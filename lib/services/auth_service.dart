import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      await fetchProfile();
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

      // Auto-patch empty fields from auth metadata
      final meta = user.userMetadata;
      if (meta != null) {
        bool needsUpdate = false;
        final updates = <String, dynamic>{};
        final currentUsername = _currentProfile!.username;
        final currentFullName = _currentProfile!.fullName ?? '';

        if ((currentUsername.isEmpty ||
                currentUsername == user.id.substring(0, 8)) &&
            meta['username'] != null) {
          updates['username'] = meta['username'];
          needsUpdate = true;
        }
        if (currentFullName.isEmpty && meta['full_name'] != null) {
          updates['full_name'] = meta['full_name'];
          needsUpdate = true;
        }
        if (needsUpdate) {
          updates['updated_at'] = DateTime.now().toIso8601String();
          await supabase.from('profiles').update(updates).eq('id', user.id);
          final updated = await supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();
          _currentProfile = ProfileModel.fromJson(updated);
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
  }) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null && fullName.isNotEmpty)
        updates['full_name'] = fullName;
      if (username != null && username.isNotEmpty)
        updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (campus != null) updates['campus'] = campus;
      if (skillsOffered != null) updates['skills_offered'] = skillsOffered;
      if (skillsWanted != null) updates['skills_wanted'] = skillsWanted;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

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
