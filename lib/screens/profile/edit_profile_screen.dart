import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _campusCtrl   = TextEditingController();
  final _offerCtrl    = TextEditingController();
  final _wantCtrl     = TextEditingController();

  bool _loading = false;
  File? _pickedImage;

  // ── Exact HTML palette ──────────────────────────────────────────────────
  // Dark background layers from the HTML :root variables
  static const _bg      = Color(0xFF0C0D14); // --bg
  static const _bg2     = Color(0xFF13141E); // --bg2  (card bg)
  static const _bg3     = Color(0xFF1A1B28); // --bg3  (input bg)
  static const _bd      = Color(0xFF272838); // --bd
  static const _bd2     = Color(0xFF32334A); // --bd2
  static const _tp      = Color(0xFFF0F0FA); // --tp   (primary text)
  static const _ts      = Color(0xFF8A8CA8); // --ts   (secondary text)
  static const _tl      = Color(0xFF4A4B62); // --tl   (label / hint)
  static const _purple  = Color(0xFF7C5CFC); // --p
  static const _pink    = Color(0xFFF0527A); // --pk

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populate());
  }

  void _populate() {
    final profile = context.read<AuthService>().currentProfile;
    if (profile == null) return;
    _nameCtrl.text     = profile.fullName     ?? '';
    _usernameCtrl.text = profile.username     ?? '';
    _bioCtrl.text      = profile.bio          ?? '';
    _campusCtrl.text   = profile.campus       ?? '';
    _offerCtrl.text    = (profile.skillsOffered ?? []).join(', ');
    _wantCtrl.text     = (profile.skillsWanted  ?? []).join(', ');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _campusCtrl.dispose();
    _offerCtrl.dispose();
    _wantCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ─────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile  = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile != null && mounted) setState(() => _pickedImage = File(xFile.path));
  }

  // ── Save ───────────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final offered = _offerCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final wanted  = _wantCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      await auth.updateProfile(
        fullName:      _nameCtrl.text.trim(),
        username:      _usernameCtrl.text.trim(),
        bio:           _bioCtrl.text.trim(),
        campus:        _campusCtrl.text.trim(),
        skillsOffered: offered,
        skillsWanted:  wanted,
        avatarFile:    _pickedImage,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.dmSans(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  // ── Initials ───────────────────────────────────────────────────────────
  String _initials() {
    final profile = context.read<AuthService>().currentProfile;
    final n = profile?.fullName ?? profile?.username ?? '?';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().currentProfile;

    return Scaffold(
      backgroundColor: _bg,

      // ── App Bar ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _bg2,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bg3,
              border: Border.all(color: _bd),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left_rounded, color: _ts, size: 22),
          ),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.dmSans(
            color: _tp, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _bd),
        ),
      ),

      // ── Save button fixed at bottom ────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: GestureDetector(
            onTap: _loading ? null : _save,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_purple, _pink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _loading
                  ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Save Changes', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 28),

            // ── Avatar ────────────────────────────────────────────────
            _buildAvatar(profile),

            const SizedBox(height: 28),

            // ── Fields ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _field(
                    ctrl: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  _field(
                    ctrl: _usernameCtrl,
                    label: 'Username',
                    icon: Icons.alternate_email_rounded,
                  ),
                  _field(
                    ctrl: _bioCtrl,
                    label: 'Bio',
                    icon: Icons.info_outline_rounded,
                    maxLines: 3,
                  ),
                  _field(
                    ctrl: _campusCtrl,
                    label: 'Campus / University',
                    icon: Icons.school_outlined,
                  ),
                  _field(
                    ctrl: _offerCtrl,
                    label: 'Skills I Offer (comma-separated)',
                    icon: Icons.star_outline_rounded,
                  ),
                  _field(
                    ctrl: _wantCtrl,
                    label: 'Skills I Want (comma-separated)',
                    icon: Icons.search_rounded,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  AVATAR WIDGET
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildAvatar(dynamic profile) {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar circle
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bg3,
                  border: Border.all(color: _bd2, width: 2),
                ),
                child: ClipOval(
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                      : (profile?.avatarUrl != null
                          ? Image.network(
                              profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _initialsCircle(),
                            )
                          : _initialsCircle()),
                ),
              ),

              // Camera badge
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_purple, _pink]),
                    border: Border.all(color: _bg, width: 2),
                    boxShadow: [BoxShadow(color: _purple.withOpacity(0.4), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tap to change photo',
            style: GoogleFonts.dmSans(color: _tl, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _initialsCircle() => Center(
    child: Text(
      _initials(),
      style: GoogleFonts.dmSans(color: _purple, fontSize: 28, fontWeight: FontWeight.w800),
    ),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  FIELD WIDGET — floating label style matching screenshot
  // ════════════════════════════════════════════════════════════════════════
  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _bg3,          // --bg3 = #1A1B28
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bd, width: 1), // --bd = #272838
        ),
        child: Stack(
          children: [
            // Floating label
            Positioned(
              top: 8, left: 48,
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  color: _purple,    // label in purple like screenshot
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Row with icon + field
            Row(
              crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: 14,
                    top: maxLines > 1 ? 30 : 0,
                  ),
                  child: Icon(icon, color: _tl, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 22, bottom: 2, right: 14),
                    child: TextField(
                      controller: ctrl,
                      maxLines: maxLines,
                      style: GoogleFonts.dmSans(color: _tp, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.only(
                          bottom: maxLines > 1 ? 14 : 12,
                        ),
                        hintStyle: GoogleFonts.dmSans(color: _tl, fontSize: 15),
                      ),
                      cursorColor: _purple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}