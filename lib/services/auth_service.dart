import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/profile_model.dart';

class AuthService extends ChangeNotifier {
  ProfileModel? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'username': username.trim(), 'full_name': fullName.trim()},
      );
      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _upsertProfile(
          userId: response.user!.id,
          username: username.trim(),
          fullName: fullName.trim(),
        );
        await fetchProfile();
        _setLoading(false);
        return true;
      }
      _setError('Sign up failed. Please try again.');
      _setLoading(false);
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _upsertProfile({
    required String userId,
    required String username,
    required String fullName,
  }) async {
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'username': username,
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('Profile upsert error: $e');
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);
    try {
      await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _setLoading(false);
      // Navigate immediately — fetch profile in the background so the
      // user lands on the home screen without waiting for a DB round trip.
      fetchProfile();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await supabase.auth.resetPasswordForEmail(email.trim());
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    _currentProfile = null;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      _currentProfile = ProfileModel.fromJson(data);

      // Auto-patch stale fields from auth metadata — fire-and-forget so we
      // never block navigation on a second round trip.
      final meta = user.userMetadata;
      if (meta != null) {
        final updates = <String, dynamic>{};
        final currentUsername = _currentProfile!.username;
        final currentFullName = _currentProfile!.fullName ?? '';

        if ((currentUsername.isEmpty ||
                currentUsername == user.id.substring(0, 8)) &&
            meta['username'] != null) {
          updates['username'] = meta['username'];
        }
        if (currentFullName.isEmpty && meta['full_name'] != null) {
          updates['full_name'] = meta['full_name'];
        }
        if (updates.isNotEmpty) {
          updates['updated_at'] = DateTime.now().toIso8601String();
          // Apply locally right away so the UI is correct immediately.
          _currentProfile = _currentProfile!.copyWith(
            fullName: updates['full_name'] ?? _currentProfile!.fullName,
          );
          if (updates.containsKey('username')) {
            // username is not in copyWith, rebuild manually
            _currentProfile = ProfileModel(
              id: _currentProfile!.id,
              username: updates['username'],
              fullName: _currentProfile!.fullName,
              bio: _currentProfile!.bio,
              campus: _currentProfile!.campus,
              skillsOffered: _currentProfile!.skillsOffered,
              skillsWanted: _currentProfile!.skillsWanted,
              avatarUrl: _currentProfile!.avatarUrl,
              totalSwaps: _currentProfile!.totalSwaps,
              averageRating: _currentProfile!.averageRating,
              ratingCount: _currentProfile!.ratingCount,
              createdAt: _currentProfile!.createdAt,
            );
          }
          // Persist in background — no await, no extra round trip.
          supabase.from('profiles').update(updates).eq('id', user.id)
              .then((_) => debugPrint('Profile patched'))
              .catchError((e) => debugPrint('Profile patch error: $e'));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      final meta = user.userMetadata;
      if (meta != null) {
        _currentProfile = ProfileModel(
          id: user.id,
          username: meta['username'] ?? user.id.substring(0, 8),
          fullName: meta['full_name'],
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? campus,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
    String? avatarUrl,
    File? avatarFile,
  }) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      String? finalAvatarUrl = avatarUrl;
      if (avatarFile != null) {
        try {
          final fileName = '${const Uuid().v4()}.jpg';
          await supabase.storage.from('avatars').upload(fileName, avatarFile);
          finalAvatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
        } catch (e) {
          debugPrint('Error uploading avatar: $e');
        }
      }

      if (fullName != null && fullName.isNotEmpty)
        updates['full_name'] = fullName;
      if (username != null && username.isNotEmpty)
        updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (campus != null) updates['campus'] = campus;
      if (skillsOffered != null) updates['skills_offered'] = skillsOffered;
      if (skillsWanted != null) updates['skills_wanted'] = skillsWanted;
      if (finalAvatarUrl != null) updates['avatar_url'] = finalAvatarUrl;

      final existing = await supabase.from('profiles').select('id').eq('id', currentUser!.id);
      if (existing.isEmpty) {
        updates['id'] = currentUser!.id;
        updates['username'] = currentUser!.userMetadata?['username'] ?? currentUser!.id.substring(0, 8);
        await supabase.from('profiles').insert(updates);
      } else {
        await supabase.from('profiles').update(updates).eq('id', currentUser!.id);
      }

      await fetchProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Profile update error: $e');
      _setError('Failed to update profile.');
      _setLoading(false);
      return false;
    }
  }

  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}