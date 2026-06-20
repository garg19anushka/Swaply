import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'edit_profile_screen.dart';
import '../../widgets/swaply_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification toggles — persisted via SharedPreferences
  bool _pushNotif = true;
  bool _msgAlerts = true;
  bool _swapAlerts = false;

  static const _kPush = 'notif_push';
  static const _kMsg = 'notif_msg';
  static const _kSwap = 'notif_swap';

  @override
  void initState() {
    super.initState();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotif = p.getBool(_kPush) ?? true;
      _msgAlerts = p.getBool(_kMsg) ?? true;
      _swapAlerts = p.getBool(_kSwap) ?? false;
    });
  }

  Future<void> _saveNotifPref(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  // ── theme colours ──────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF0C0D14) : const Color(0xFFF0EFFF);
  Color get _bg2 => _d ? const Color(0xFF13141E) : Colors.white;
  Color get _bg3 => _d ? const Color(0xFF1A1B28) : const Color(0xFFF5F4FF);
  Color get _bd => _d ? const Color(0xFF272838) : const Color(0xFFE2E0F5);
  Color get _bd2 => _d ? const Color(0xFF32334A) : const Color(0xFFCCCAE8);
  Color get _tp => _d ? const Color(0xFFF0F0FA) : const Color(0xFF0D0C1E);
  Color get _ts => _d ? const Color(0xFF8A8CA8) : const Color(0xFF6B6988);
  Color get _tl => _d ? const Color(0xFF4A4B62) : const Color(0xFFB0AECB);

  static const _purple = Color(0xFF7C5CFC);
  static const _purple2 = Color(0xFF9B7BFF);
  static const _pink = Color(0xFFF0527A);
  static const _teal = Color(0xFF2EC4B6);
  static const _amber = Color(0xFFF4B942);
  static const _orange = Color(0xFFF97316);
  static const _red = Color(0xFFEF4444);
  static const _green = Color(0xFF22C55E);

  // ── helpers ────────────────────────────────────────────────────────────
  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF4B4ACF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _initials(String? fullName, String? username) {
    final n = fullName ?? username ?? '?';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.currentProfile;
    final tp2 = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ─────────────────────────────────────────────────
            _buildHeader(),

            // ── Profile strip ───────────────────────────────────────────
            _buildProfileStrip(profile),

            // ── Scrollable body ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppearance(tp2),
                    _buildSection('Account', _buildAccount(auth)),
                    _buildSection('Notifications', _buildNotifications()),
                    _buildSection('App Data', _buildAppData()),
                    _buildSection('Support', _buildSupport()),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  HEADER
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 10),
      decoration: BoxDecoration(
        color: _bg2,
        border: Border(bottom: BorderSide(color: _bd, width: 1)),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _bg3,
                border: Border.all(color: _bd),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_left_rounded, color: _ts, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Settings',
            style: GoogleFonts.dmSans(
              color: _tp,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  PROFILE STRIP
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildProfileStrip(dynamic profile) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bg2,
        border: Border.all(color: _bd),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // ── Avatar — exact same as profile screen ──────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _bg3,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: profile?.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      profile!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _initialsBox(profile.username, profile.fullName),
                    ),
                  )
                : _initialsBox(profile?.username, profile?.fullName),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? profile?.username ?? 'User',
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${profile?.username ?? ''}${profile?.campus != null ? ' · ${profile!.campus}' : ''}',
                  style: GoogleFonts.dmSans(color: _ts, fontSize: 12),
                ),
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ).then((_) => context.read<AuthService>().fetchProfile()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.10),
                border: Border.all(color: _purple.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Edit',
                style: GoogleFonts.dmSans(
                  color: _purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsBox(String? username, String? fullName) => Center(
    child: Text(
      _initials(fullName, username),
      style: GoogleFonts.dmSans(
        color: AppColors.primary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  SECTION WRAPPER
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildSection(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.dmSans(
                color: _tl,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _bg2,
              border: Border.all(color: _bd),
              borderRadius: BorderRadius.circular(20),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  APPEARANCE — 3 tile grid
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildAppearance(ThemeProvider tp2) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'APPEARANCE',
              style: GoogleFonts.dmSans(
                color: _tl,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Row(
            children: [
              _appearTile(
                label: 'Light',
                sub: 'Always light',
                isActive: tp2.isLight,
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFF4B942),
                iconBg: const Color(0xFFF4B942).withOpacity(0.12),
                onTap: () => tp2.setTheme(ThemeMode.light),
              ),
              const SizedBox(width: 8),
              _appearTile(
                label: 'System',
                sub: 'Auto',
                isActive: tp2.isSystem,
                icon: Icons.computer_outlined,
                iconColor: _purple,
                iconBg: _purple.withOpacity(0.12),
                onTap: () => tp2.setTheme(ThemeMode.system),
              ),
              const SizedBox(width: 8),
              _appearTile(
                label: 'Dark',
                sub: 'Always dark',
                isActive: tp2.isDark,
                icon: Icons.nightlight_round,
                iconColor: _purple2,
                iconBg: _purple.withOpacity(0.12),
                onTap: () => tp2.setTheme(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appearTile({
    required String label,
    required String sub,
    required bool isActive,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? _purple.withOpacity(0.08) : _bg2,
            border: Border.all(
              color: isActive ? _purple : _bd,
              width: isActive ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: GoogleFonts.dmSans(color: _ts, fontSize: 10)),
              const SizedBox(height: 8),
              // indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? _purple : _bd,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  ACCOUNT
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildAccount(AuthService auth) {
    return Column(
      children: [
        _row(
          icon: Icons.person_outline_rounded,
          iconBg: _purple.withOpacity(0.12),
          iconColor: _purple,
          title: 'Edit Profile',
          sub: 'Name, photo, campus, bio',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ).then((_) => auth.fetchProfile()),
        ),
        _divider(),
        _row(
          icon: Icons.lock_outline_rounded,
          iconBg: _teal.withOpacity(0.12),
          iconColor: _teal,
          title: 'Change Password / Email',
          onTap: () => _showChangePasswordDialog(auth),
        ),
        _divider(),
        _row(
          icon: Icons.logout_rounded,
          iconBg: _orange.withOpacity(0.12),
          iconColor: _orange,
          title: 'Logout',
          titleColor: _orange,
          onTap: () => _showLogoutDialog(auth),
        ),
        _divider(),
        _row(
          icon: Icons.delete_outline_rounded,
          iconBg: _red.withOpacity(0.12),
          iconColor: _red,
          title: 'Delete Account',
          titleColor: _red,
          onTap: () => _showDeleteDialog(auth),
          isLast: true,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildNotifications() {
    return Column(
      children: [
        _toggleRow(
          icon: Icons.notifications_outlined,
          iconBg: _purple.withOpacity(0.12),
          iconColor: _purple,
          title: 'Push Notifications',
          sub: 'All app alerts',
          value: _pushNotif,
          onChanged: (v) {
            setState(() => _pushNotif = v);
            _saveNotifPref(_kPush, v);
          },
        ),
        _divider(),
        _toggleRow(
          icon: Icons.chat_bubble_outline_rounded,
          iconBg: _pink.withOpacity(0.12),
          iconColor: _pink,
          title: 'Message Alerts',
          sub: 'Chat notifications',
          value: _msgAlerts,
          onChanged: (v) {
            setState(() => _msgAlerts = v);
            _saveNotifPref(_kMsg, v);
          },
        ),
        _divider(),
        _toggleRow(
          icon: Icons.swap_horiz_rounded,
          iconBg: _teal.withOpacity(0.12),
          iconColor: _teal,
          title: 'Swap Requests',
          sub: 'New swap alerts',
          value: _swapAlerts,
          onChanged: (v) {
            setState(() => _swapAlerts = v);
            _saveNotifPref(_kSwap, v);
          },
          isLast: true,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  APP DATA
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildAppData() {
    return Column(
      children: [
        _row(
          icon: Icons.refresh_rounded,
          iconBg: _amber.withOpacity(0.12),
          iconColor: _amber,
          title: 'Clear Cache',
          sub: 'Free up local storage',
          onTap: () {
            Navigator.pop(context);
            _snack('Cache cleared successfully!', color: AppColors.success);
          },
        ),
        _divider(),
        _row(
          icon: Icons.download_outlined,
          iconBg: _purple.withOpacity(0.12),
          iconColor: _purple,
          title: 'Download My Data',
          sub: 'Export your profile & history',
          onTap: () => _showDownloadDialog(),
        ),
        _divider(),
        _row(
          icon: Icons.info_outline_rounded,
          iconBg: _ts.withOpacity(0.12),
          iconColor: _ts,
          title: 'About App',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.10),
              border: Border.all(color: _purple.withOpacity(0.25)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'v1.0.0',
              style: GoogleFonts.dmSans(
                color: _purple,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          onTap: () => _showAboutDialog(),
          isLast: true,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  SUPPORT
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildSupport() {
    return Column(
      children: [
        _row(
          icon: Icons.help_outline_rounded,
          iconBg: _amber.withOpacity(0.12),
          iconColor: _amber,
          title: 'FAQs',
          sub: 'Common questions answered',
          onTap: () => _showFAQsDialog(),
        ),
        _divider(),
        _row(
          icon: Icons.mail_outline_rounded,
          iconBg: _pink.withOpacity(0.12),
          iconColor: _pink,
          title: 'Contact Developer',
          sub: 'Report bugs, send feedback',
          onTap: () => _showContactDialog(),
        ),
        _divider(),
        _row(
          icon: Icons.description_outlined,
          iconBg: _ts.withOpacity(0.10),
          iconColor: _ts,
          title: 'Terms & Privacy Policy',
          onTap: () => _showTermsDialog(),
        ),
        _divider(),
        _row(
          icon: Icons.star_outline_rounded,
          iconBg: _amber.withOpacity(0.12),
          iconColor: _amber,
          title: 'Rate Swaply',
          sub: 'Love the app? Let us know!',
          onTap: () => _showRateDialog(),
          isLast: true,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  FOOTER
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Swaply',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Campus Skill Barter · v1.0.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: _tl, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              'Made with ♥ by Anushka Garg',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: _tl, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  ROW WIDGETS
  // ════════════════════════════════════════════════════════════════════════
  Widget _row({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? sub,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isLast ? 20 : 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: titleColor ?? _tp,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      sub,
                      style: GoogleFonts.dmSans(color: _ts, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: _tl, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? sub,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: GoogleFonts.dmSans(color: _ts, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _purple,
            activeTrackColor: _purple.withOpacity(0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _tl.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: _bd, indent: 16, endIndent: 16);

  // ════════════════════════════════════════════════════════════════════════
  //  DIALOGS
  // ════════════════════════════════════════════════════════════════════════

  // ── Bottom sheet helper ────────────────────────────────────────────────
  void _sheet(Widget content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => content,
    );
  }

  // ── Confirm sheet (logout / delete) ───────────────────────────────────
  void _confirmSheet({
    required Widget icon,
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    _sheet(
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _bd2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            icon,
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: _ts, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _bg3,
                        border: Border.all(color: _bd),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmSans(
                          color: _ts,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [confirmColor, confirmColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: confirmColor.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  // Logout
  void _showLogoutDialog(AuthService auth) {
    _confirmSheet(
      icon: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.logout_rounded, color: _orange, size: 26),
      ),
      title: 'Logout?',
      body: 'Are you sure you want to log out of your Swaply account?',
      confirmLabel: 'Logout',
      confirmColor: _orange,
      onConfirm: () async {
        await auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false,
          );
        }
      },
    );
  }

  // Delete account
  void _showDeleteDialog(AuthService auth) {
    _confirmSheet(
      icon: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: _red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_forever_rounded, color: _red, size: 26),
      ),
      title: 'Delete Account?',
      body:
          'This will permanently delete your account and all data. This action cannot be undone.',
      confirmLabel: 'Delete Forever',
      confirmColor: _red,
      onConfirm: () async {
        await auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false,
          );
        }
      },
    );
  }

  // Change password
  void _showChangePasswordDialog(AuthService auth) {
    final emailCtrl = TextEditingController(text: '');
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscurePass = true;
    bool obscureConfirm = true;

    _sheet(
      StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _bd2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Change Password / Email',
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                _dialogField(
                  emailCtrl,
                  'New Email',
                  Icons.mail_outline_rounded,
                ),
                const SizedBox(height: 10),
                _dialogFieldObscure(
                  passCtrl,
                  'New Password',
                  obscurePass,
                  () => setS(() => obscurePass = !obscurePass),
                ),
                const SizedBox(height: 10),
                _dialogFieldObscure(
                  confirmCtrl,
                  'Confirm Password',
                  obscureConfirm,
                  () => setS(() => obscureConfirm = !obscureConfirm),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: _outlineBtn('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (passCtrl.text.isNotEmpty &&
                              passCtrl.text != confirmCtrl.text) {
                            _snack(
                              'Passwords do not match',
                              color: AppColors.error,
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          _snack('Changes saved!', color: AppColors.success);
                        },
                        child: _gradientBtn('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Download data
  void _showDownloadDialog() {
    _sheet(
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _bd2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.download_outlined,
                color: _purple,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Download My Data',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'We will prepare a copy of your profile, posts, and swap history. You will be notified when it\'s ready.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: _ts, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _outlineBtn('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _snack('Export requested!', color: AppColors.success);
                    },
                    child: _gradientBtn('Request Export'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // About
  void _showAboutDialog() {
    _sheet(
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _bd2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const SwaplyLogoWidget(size: 44),
                const SizedBox(width: 12),
                Text(
                  'About Swaply',
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0 (Build 1)',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Swaply is a campus-only skill-swap platform where students exchange their talents with each other.',
              style: GoogleFonts.dmSans(color: _ts, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Developed by',
              style: GoogleFonts.dmSans(color: _tl, fontSize: 11),
            ),
            Text(
              'Anushka Garg',
              style: GoogleFonts.dmSans(
                color: _purple,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: _gradientBtn('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // FAQs
  void _showFAQsDialog() {
    final faqs = [
      (
        'How do I create a swap post?',
        'Tap the + Post button in the bottom nav, fill in what skill you offer and what you want in return.',
      ),
      (
        'How does the rating system work?',
        'After completing a swap, both parties can rate each other from 1–5 stars.',
      ),
      (
        'Can I cancel a swap request?',
        'Yes! Go to the swap in your Chats tab and tap "Cancel Request" before the other party accepts.',
      ),
      (
        'Is Swaply free?',
        'Yes, completely free. All skill swaps are peer-to-peer with no monetary transactions.',
      ),
      (
        'How do I report a user?',
        'Open the user\'s profile, tap the three-dot menu and select "Report User".',
      ),
    ];
    _sheet(
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _bd2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'FAQs',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...faqs.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.$1,
                      style: GoogleFonts.dmSans(
                        color: _tp,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      f.$2,
                      style: GoogleFonts.dmSans(
                        color: _ts,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    Divider(color: _bd, height: 16),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: _gradientBtn('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // Contact
  void _showContactDialog() {
    final msgCtrl = TextEditingController();
    _sheet(
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _bd2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact Developer',
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Have a bug or suggestion? We\'d love to hear from you!',
                style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _bg3,
                  border: Border.all(color: _bd),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write your message here...',
                    hintStyle: GoogleFonts.dmSans(color: _tl, fontSize: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: _outlineBtn('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (msgCtrl.text.trim().isEmpty) {
                          _snack(
                            'Please write a message first',
                            color: AppColors.error,
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _snack(
                          'Message sent! We\'ll get back to you soon.',
                          color: AppColors.success,
                        );
                      },
                      child: _gradientBtn('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Terms
  void _showTermsDialog() {
    _sheet(
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _bd2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Terms & Privacy Policy',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Terms of Service',
              style: GoogleFonts.dmSans(
                color: _purple,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'By using Swaply, you agree to exchange skills fairly and honestly. You must not use the platform for illegal activity, harassment, or misrepresentation of your skills.',
              style: GoogleFonts.dmSans(color: _ts, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 14),
            Text(
              'Privacy Policy',
              style: GoogleFonts.dmSans(
                color: _purple,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'We collect only data necessary to operate the platform. We never sell your data to third parties. You may request deletion of your account at any time.',
              style: GoogleFonts.dmSans(color: _ts, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Last updated: January 2025',
              style: GoogleFonts.dmSans(color: _tl, fontSize: 11),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: _gradientBtn('I Understand'),
            ),
          ],
        ),
      ),
    );
  }

  // Rate app
  void _showRateDialog() {
    int stars = 5;
    _sheet(
      StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _bd2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rate Swaply',
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enjoying Swaply? Give us a rating!',
                style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setS(() => stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.warning,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent!'][stars],
                style: GoogleFonts.dmSans(
                  color: AppColors.warning,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: _outlineBtn('Later'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _snack(
                          stars >= 4
                              ? 'Thank you for the $stars-star review! ⭐'
                              : 'Thanks for your feedback!',
                          color: AppColors.success,
                        );
                      },
                      child: _gradientBtn('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reusable button widgets ────────────────────────────────────────────
  Widget _gradientBtn(String label) => Container(
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF4B4ACF),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4B4ACF).withOpacity(0.45),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      label,
      style: GoogleFonts.dmSans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _outlineBtn(String label) => Container(
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _bg3,
      border: Border.all(color: _bd),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: GoogleFonts.dmSans(
        color: _ts,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon) =>
      Container(
        decoration: BoxDecoration(
          color: _bg3,
          border: Border.all(color: _bd),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(icon, color: _tl, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: ctrl,
                style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.dmSans(color: _tl, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _dialogFieldObscure(
    TextEditingController ctrl,
    String hint,
    bool obscure,
    VoidCallback toggle,
  ) => Container(
    decoration: BoxDecoration(
      color: _bg3,
      border: Border.all(color: _bd),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const SizedBox(width: 14),
        Icon(Icons.lock_outline_rounded, color: _tl, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(color: _tl, fontSize: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _tl,
            size: 17,
          ),
          onPressed: toggle,
        ),
      ],
    ),
  );
}
