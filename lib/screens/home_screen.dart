// lib/screens/home_screen.dart
// Drop this file into lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch posts on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostService>().fetchPosts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── theme helpers ────────────────────────────────────────────────────────────
  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _dark ? const Color(0xFF0A0C1A) : const Color(0xFFF0F2FA);
  Color get _appBarBg => _dark ? const Color(0xFF12152A) : Colors.white;
  Color get _divider =>
      _dark ? const Color(0xFF1E2240) : const Color(0xFFE2E6F0);
  Color get _searchBg =>
      _dark ? const Color(0xFF1A1D2E) : const Color(0xFFEEF0F8);
  Color get _searchBdr =>
      _dark ? const Color(0xFF2E3150) : const Color(0xFFD0D4EC);
  Color get _hintCol =>
      _dark ? const Color(0xFF8A8FA8) : const Color(0xFFADB5C8);
  Color get _iconCol =>
      _dark ? const Color(0xFF8A8FA8) : const Color(0xFFADB5C8);
  Color get _titleCol => _dark ? Colors.white : const Color(0xFF0F1220);
  Color get _subCol =>
      _dark ? const Color(0xFF8A8FA8) : const Color(0xFF5A6080);
  Color get _accentA =>
      _dark ? const Color(0xFF7B6EF6) : const Color(0xFF5B52D0);
  Color get _accentB =>
      _dark ? const Color(0xFF5A4FCF) : const Color(0xFF3B48C8);
  Color get _shimBase =>
      _dark ? const Color(0xFF1A1D2E) : const Color(0xFFE8ECF4);
  Color get _shimHigh =>
      _dark ? const Color(0xFF2E3150) : const Color(0xFFF4F6FC);
  Color get _cardBg =>
      _dark ? const Color(0xFF12152A) : const Color(0xFFF8F9FA);
  Color get _cardBdr =>
      _dark ? const Color(0xFF1E2240) : const Color(0xFFE2E6F0);

  // ── search bar ───────────────────────────────────────────────────────────────
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _searchBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _searchBdr),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.poppins(color: _titleCol, fontSize: 13.5),
          onChanged: (v) {
            setState(() => _searchQuery = v.trim());
            context.read<PostService>().fetchPosts(
              searchQuery: v.trim().isEmpty ? null : v.trim(),
            );
          },
          decoration: InputDecoration(
            hintText: 'Search skills, people, tags…',
            hintStyle: GoogleFonts.poppins(color: _hintCol, fontSize: 13.5),
            prefixIcon: Icon(Icons.search_rounded, color: _iconCol, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: _iconCol, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                      context.read<PostService>().fetchPosts();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── shimmer skeleton ─────────────────────────────────────────────────────────
  Widget _shimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBdr),
      ),
      child: Shimmer.fromColors(
        baseColor: _shimBase,
        highlightColor: _shimHigh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 21, backgroundColor: Colors.white),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 110,
                      height: 13,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 6),
                    ),
                    Container(width: 160, height: 10, color: Colors.white),
                  ],
                ),
                const Spacer(),
                Container(width: 40, height: 10, color: Colors.white),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 14,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 6),
            ),
            Container(width: 200, height: 14, color: Colors.white),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 11,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 5),
            ),
            Container(width: 260, height: 11, color: Colors.white),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 65,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 65,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 75,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(width: 100, height: 12, color: Colors.white),
                const Spacer(),
                Container(
                  width: 70,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── empty state ──────────────────────────────────────────────────────────────
  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 64,
              color: _accentA.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _subCol, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── app bar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: _appBarBg,
      elevation: 0,
      centerTitle: false,
      title: ShaderMask(
        shaderCallback: (b) =>
            LinearGradient(colors: [_accentA, _accentB]).createShader(b),
        child: Text(
          'Swaply',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_none_rounded, color: _iconCol),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.person_outline_rounded, color: _iconCol),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _divider),
      ),
    );
  }

  // ── feed list ────────────────────────────────────────────────────────────────
  Widget _feedList(PostService ps) {
    if (ps.isLoading && ps.posts.isEmpty) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => _shimmerCard(),
      );
    }

    if (ps.posts.isEmpty) {
      return _emptyState(
        _searchQuery.isNotEmpty
            ? 'No posts match "$_searchQuery"'
            : 'No skill swaps yet.\nBe the first to post!',
      );
    }

    return RefreshIndicator(
      color: _accentA,
      onRefresh: () => ps.fetchPosts(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: ps.posts.length,
        itemBuilder: (context, i) {
          final post = ps.posts[i];
          return PostCard(
            key: ValueKey(post.id),
            post: post,
            onSwap: () {
              // TODO: Navigate to swap/chat screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Starting swap for "${post.title}"',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: _accentA,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            onBookmark: () => ps.toggleBookmark(post.id),
          );
        },
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────────
  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentA, _accentB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accentB.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigator.push to CreatePostScreen
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  'Post a Swap',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      floatingActionButton: _fab(),
      body: Column(
        children: [
          _searchBar(),
          Expanded(
            child: Consumer<PostService>(
              builder: (context, ps, _) => _feedList(ps),
            ),
          ),
        ],
      ),
    );
  }
}
