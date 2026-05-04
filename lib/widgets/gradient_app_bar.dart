import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

/// Gradient app bar — used in detail/secondary screens.
/// Primary screens use plain white SliverAppBars.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: AppBar(
        title: Text(
          title,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: centerTitle,
        leading: leading,
        actions: actions,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
