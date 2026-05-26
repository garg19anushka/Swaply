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
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _campusCtrl = TextEditingController();
  final _offerCtrl = TextEditingController();
  final _wantCtrl = TextEditingController();
  final List<TextEditingController> _linkCtrls = [];

  bool _loading = false;
  File? _pickedImage;

  // ── Theme-aware color getters ──────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _d ? const Color(0xFF111318) : const Color(0xFFF5F5F7);
  Color get _bg2 => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color get _bg3 => _d ? const Color(0xFF22252E) : const Color(0xFFF0F0F5);
  Color get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFE0E0E8);
  Color get _bd2 => _d ? const Color(0xFF32364A) : const Color(0xFFD0D0DC);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E7A);
  Color get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);
  static const _purple = Color(0xFF7C5CFC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populate());
  }

  void _populate() {
    final profile = context.read<AuthService>().currentProfile;
    if (profile == null) return;
    _nameCtrl.text = profile.fullName ?? '';
    _usernameCtrl.text = profile.username ?? '';
    _bioCtrl.text = profile.bio ?? '';
    _campusCtrl.text = profile.campus ?? '';
    _offerCtrl.text = (profile.skillsOffered ?? []).join(', ');
    _wantCtrl.text = (profile.skillsWanted ?? []).join(', ');
    for (final url in profile.links) {
      _linkCtrls.add(TextEditingController(text: url));
    }
    if (_linkCtrls.isEmpty) _linkCtrls.add(TextEditingController());
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _campusCtrl.dispose();
    _offerCtrl.dispose();
    _wantCtrl.dispose();
    for (final c in _linkCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xFile != null && mounted)
      setState(() => _pickedImage = File(xFile.path));
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final offered = _offerCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final wanted = _wantCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final links = _linkCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await auth.updateProfile(
        fullName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        campus: _campusCtrl.text.trim(),
        skillsOffered: offered,
        skillsWanted: wanted,
        links: links,
        avatarFile: _pickedImage,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

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
            child: Icon(Icons.chevron_left_rounded, color: _ts, size: 22),
          ),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.dmSans(
            color: _tp,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _bd),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: GestureDetector(
            onTap: _loading ? null : _save,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B52E8), Color(0xFF7C5CFC)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B52E8).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _bg3,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _purple.withOpacity(0.35),
                        width: 2,
                      ),
                    ),
                    child: _pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_pickedImage!, fit: BoxFit.cover),
                          )
                        : profile?.avatarUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  _initials(),
                                  style: GoogleFonts.dmSans(
                                    color: _purple,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _initials(),
                              style: GoogleFonts.dmSans(
                                color: _purple,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change photo',
              style: GoogleFonts.dmSans(color: _tl, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // ── Fields ──────────────────────────────────────────────────
            _field(
              ctrl: _nameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 8),
            _field(
              ctrl: _usernameCtrl,
              label: 'Username',
              icon: Icons.alternate_email_rounded,
            ),
            const SizedBox(height: 8),
            _field(
              ctrl: _bioCtrl,
              label: 'Bio',
              icon: Icons.info_outline_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            _field(
              ctrl: _campusCtrl,
              label: 'Campus / University',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 8),
            _field(
              ctrl: _offerCtrl,
              label: 'Skills I Offer (comma-separated)',
              icon: Icons.star_outline_rounded,
            ),
            const SizedBox(height: 8),
            _field(
              ctrl: _wantCtrl,
              label: 'Skills I Want (comma-separated)',
              icon: Icons.search_rounded,
            ),
            const SizedBox(height: 8),

            // ── Links ────────────────────────────────────────────────────
            _buildLinksSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Field widget ──────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bd, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14, top: maxLines > 1 ? 26 : 20),
            child: Icon(icon, color: _tl, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 2, right: 14),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: _purple.withOpacity(0.28),
                    cursorColor: _purple,
                    selectionHandleColor: _purple,
                  ),
                ),
                child: Stack(
                  children: [
                    // Floating label
                    Positioned(
                      top: -14,
                      left: 0,
                      child: Text(
                        label,
                        style: GoogleFonts.dmSans(
                          color: _purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    TextField(
                      controller: ctrl,
                      maxLines: maxLines,
                      autocorrect: false,
                      autofillHints: const [],
                      enableIMEPersonalizedLearning: false,
                      style: GoogleFonts.dmSans(
                        color: _tp,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.only(
                          bottom: maxLines > 1 ? 14 : 12,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        hintStyle: GoogleFonts.dmSans(color: _tl, fontSize: 15),
                      ),
                      cursorColor: _purple,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Links section ─────────────────────────────────────────────────────────
  Widget _buildLinksSection() {
    return Container(
      decoration: BoxDecoration(
        color: _bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bd, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: _purple, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Links',
                  style: GoogleFonts.dmSans(
                    color: _purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ..._linkCtrls.asMap().entries.map((entry) {
            final i = entry.key;
            final ctrl = entry.value;
            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _bg3,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _bd2, width: 1),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.link_rounded,
                              color: _tl,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: TextSelectionThemeData(
                                  selectionColor: _purple.withOpacity(0.28),
                                  cursorColor: _purple,
                                  selectionHandleColor: _purple,
                                ),
                              ),
                              child: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.url,
                                autocorrect: false,
                                autofillHints: const [AutofillHints.url],
                                style: GoogleFonts.dmSans(
                                  color: _tp,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  hintText: 'https://',
                                  hintStyle: GoogleFonts.dmSans(
                                    color: _tl,
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                                cursorColor: _purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeLink(i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _bg3,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _bd2, width: 1),
                      ),
                      child: Icon(Icons.close_rounded, color: _ts, size: 16),
                    ),
                  ),
                ],
              ),
            );
          }),

          GestureDetector(
            onTap: _linkCtrls.length < 5 ? _addLink : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: _linkCtrls.length < 5 ? _purple : _tl,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _linkCtrls.length < 5
                        ? '+ Add another link'
                        : 'Max 5 links reached',
                    style: GoogleFonts.dmSans(
                      color: _linkCtrls.length < 5 ? _purple : _tl,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addLink() => setState(() => _linkCtrls.add(TextEditingController()));

  void _removeLink(int index) {
    setState(() {
      _linkCtrls[index].dispose();
      _linkCtrls.removeAt(index);
      if (_linkCtrls.isEmpty) _linkCtrls.add(TextEditingController());
    });
  }
}
