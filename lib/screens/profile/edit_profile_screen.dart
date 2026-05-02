import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey              = GlobalKey<FormState>();
  late TextEditingController  _nameCtrl;
  late TextEditingController  _usernameCtrl;
  late TextEditingController  _bioCtrl;
  late TextEditingController  _campusCtrl;
  late TextEditingController  _skillsOfferedCtrl;
  late TextEditingController  _skillsWantedCtrl;

  bool    _isLoading       = false;
  bool    _isUploadingPhoto = false;
  String? _newAvatarUrl;

  // ── theme shortcuts ─────────────────────────────────────────────────────
  bool  get _d  => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF111318) : Colors.white;
  Color get _sf => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color get _fv => _d ? const Color(0xFF1E222C) : const Color(0xFFF2F2F4);
  Color get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFE5E5E5);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthService>().currentProfile;
    _nameCtrl          = TextEditingController(text: p?.fullName ?? '');
    _usernameCtrl      = TextEditingController(text: p?.username ?? '');
    _bioCtrl           = TextEditingController(text: p?.bio ?? '');
    _campusCtrl        = TextEditingController(text: p?.campus ?? '');
    _skillsOfferedCtrl = TextEditingController(
        text: p?.skillsOffered.join(', ') ?? '');
    _skillsWantedCtrl  = TextEditingController(
        text: p?.skillsWanted.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _campusCtrl.dispose();
    _skillsOfferedCtrl.dispose();
    _skillsWantedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80,
        maxWidth: 512, maxHeight: 512);
    if (picked == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final fileName  = '${const Uuid().v4()}.jpg';
      final fileBytes = await picked.readAsBytes() as Uint8List;
      await supabase.storage.from('avatars').uploadBinary(
        fileName, fileBytes,
        fileOptions: FileOptions(cacheControl: '3600', upsert: true),
      );
      final url = supabase.storage.from('avatars').getPublicUrl(fileName);
      setState(() => _newAvatarUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Photo uploaded!',
              style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e',
              style: GoogleFonts.dmSans(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  List<String> _parseSkills(String text) => text
      .split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final ok = await auth.updateProfile(
      fullName:      _nameCtrl.text.trim(),
      username:      _usernameCtrl.text.trim(),
      bio:           _bioCtrl.text.trim(),
      campus:        _campusCtrl.text.trim(),
      skillsOffered: _parseSkills(_skillsOfferedCtrl.text),
      skillsWanted:  _parseSkills(_skillsWantedCtrl.text),
      avatarUrl:     _newAvatarUrl,
    );
    setState(() => _isLoading = false);
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text('Profile updated!',
              style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().currentProfile;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Neutral sticky header ──────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _sf,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: _tp, size: 19),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Edit Profile',
                style: GoogleFonts.dmSans(
                  color: _tp, fontSize: 17,
                  fontWeight: FontWeight.w700, letterSpacing: -0.3,
                )),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: _bd),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    // ── Avatar picker ──────────────────────────────────
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickAvatar,
                      child: Stack(
                        children: [
                          _isUploadingPhoto
                              ? Container(
                                  width: 96, height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _fv,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2),
                                  ),
                                )
                              : AvatarWidget(
                                  avatarUrl: _newAvatarUrl ?? profile?.avatarUrl,
                                  username: profile?.username ?? '',
                                  radius: 48,
                                  borderColor: _d
                                      ? const Color(0xFF2A2D36)
                                      : AppColors.primary.withOpacity(0.3),
                                ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _bg, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isUploadingPhoto ? 'Uploading...' : 'Tap to change photo',
                      style: GoogleFonts.dmSans(
                          color: _ts, fontSize: 12),
                    ),

                    const SizedBox(height: 28),

                    // ── Form fields ────────────────────────────────────
                    _field(_nameCtrl, 'Full Name',
                        Icons.person_outline_rounded,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Full name is required' : null),
                    const SizedBox(height: 14),
                    _field(_usernameCtrl, 'Username',
                        Icons.alternate_email_rounded,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Username is required' : null),
                    const SizedBox(height: 14),
                    _field(_bioCtrl, 'Bio',
                        Icons.info_outline_rounded, maxLines: 3),
                    const SizedBox(height: 14),
                    _field(_campusCtrl, 'Campus / University',
                        Icons.school_outlined),
                    const SizedBox(height: 14),
                    _field(_skillsOfferedCtrl,
                        'Skills I Offer (comma-separated)',
                        Icons.star_outline_rounded,
                        hint: 'e.g. Python, Guitar, UI Design'),
                    const SizedBox(height: 14),
                    _field(_skillsWantedCtrl,
                        'Skills I Want (comma-separated)',
                        Icons.search_rounded,
                        hint: 'e.g. Figma, Spanish, Video Editing'),

                    const SizedBox(height: 32),

                    // ── Save Changes button ────────────────────────────
                    _SaveButton(
                      isLoading: _isLoading,
                      dark: _d,
                      onTap: _isLoading ? null : _save,
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.dmSans(color: _ts, fontSize: 13.5),
        hintStyle: GoogleFonts.dmSans(color: _ts, fontSize: 13.5),
        filled: true,
        fillColor: _fv,
        prefixIcon: Padding(
          padding: EdgeInsets.only(
              bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0),
          child: Icon(icon, size: 20, color: _ts),
        ),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _bd, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _bd, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Save Changes button — theme-aware
//  Dark: primaryGradient  |  Light: solid AppColors.primary
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final bool isLoading, dark;
  final VoidCallback? onTap;
  const _SaveButton(
      {required this.isLoading, required this.dark, required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 200),
    lowerBound: 0.96, upperBound: 1.0, value: 1.0,
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      onTapDown: enabled ? (_) => _ctrl.reverse() : null,
      onTapUp:   enabled ? (_) { _ctrl.forward(); widget.onTap!(); } : null,
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            // Dark: gradient  |  Light: solid primary
            gradient: (enabled && widget.dark)
                ? AppColors.primaryGradient : null,
            color: (enabled && widget.dark) ? null
                : enabled
                    ? AppColors.primary
                    : (widget.dark
                        ? const Color(0xFF22252E)
                        : const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [BoxShadow(
                    color: AppColors.primary
                        .withOpacity(widget.dark ? 0.28 : 0.20),
                    blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_rounded,
                          color: enabled ? Colors.white
                              : (widget.dark
                                  ? const Color(0xFF555862)
                                  : const Color(0xFFAAAAAA)),
                          size: 17),
                      const SizedBox(width: 8),
                      Text('Save Changes',
                          style: GoogleFonts.dmSans(
                            color: enabled ? Colors.white
                                : (widget.dark
                                    ? const Color(0xFF555862)
                                    : const Color(0xFFAAAAAA)),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}