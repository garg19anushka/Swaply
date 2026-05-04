import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  CreatePostScreen  —  Matches the dark design exactly.
//  Field order (per spec):
//    1. Open Request toggle
//    2. POST DETAILS: Title, Description
//    3. Skills I Offer
//    4. Exchange Type (Barter | Custom)
//    5. Skill You Want in Return  ← swapped to ABOVE "skill offered in return"
//    6. AVAILABILITY chips
//    7. SESSION FORMAT (Online | In-Person | Hybrid)
//    8. Publish Skill Post button
// ═══════════════════════════════════════════════════════════════════════════

class CreatePostScreen extends StatefulWidget {
  final PostModel? post;
  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _titleCtrl        = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _skillOfferedCtrl = TextEditingController();
  final _skillWantedCtrl  = TextEditingController();
  final _customOfferCtrl  = TextEditingController();

  final _titleFocus        = FocusNode();
  final _descFocus         = FocusNode();
  final _skillOfferedFocus = FocusNode();
  final _skillWantedFocus  = FocusNode();
  final _customOfferFocus  = FocusNode();

  String _exchangeType  = 'barter';
  bool   _isOpenRequest = false;
  bool   _isLoading     = false;

  // Availability chips
  final _availabilityOptions = ['Weekends', 'Evenings', 'Flexible', 'Online Only'];
  final Set<String> _selectedAvailability = {};

  // Session format
  String _sessionFormat = 'online'; // 'online' | 'inperson' | 'hybrid'

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _bg        = Color(0xFF0D0E17);
  static const _surface   = Color(0xFF161824);
  static const _inputBg   = Color(0xFF1C1D2A);
  static const _border    = Color(0xFF2E3048);
  static const _purple    = Color(0xFF6C63FF);
  static const _textMain  = Color(0xFFFFFFFF);
  static const _textSub   = Color(0xFF8E90A8);
  static const _textHint  = Color(0xFF545670);
  static const _errorRed  = Color(0xFFFF5C6A);

  @override
  void initState() {
    super.initState();
    for (final fn in [_titleFocus, _descFocus, _skillOfferedFocus,
                      _skillWantedFocus, _customOfferFocus]) {
      fn.addListener(() => setState(() {}));
    }
    if (widget.post != null) {
      final p = widget.post!;
      _titleCtrl.text        = p.title;
      _descCtrl.text         = p.description;
      _skillOfferedCtrl.text = p.skillOffered;
      _skillWantedCtrl.text  = p.skillWanted ?? '';
      _customOfferCtrl.text  = p.customOffer ?? '';
      _exchangeType          = p.exchangeType;
      _isOpenRequest         = p.isOpenRequest;
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _skillOfferedCtrl,
                     _skillWantedCtrl, _customOfferCtrl]) { c.dispose(); }
    for (final f in [_titleFocus, _descFocus, _skillOfferedFocus,
                     _skillWantedFocus, _customOfferFocus]) { f.dispose(); }
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final isEdit = widget.post != null;

    try {
      PostModel? result;
      if (isEdit) {
        result = await context.read<PostService>().updatePost(
          postId:       widget.post!.id,
          title:        _titleCtrl.text.trim(),
          description:  _descCtrl.text.trim(),
          skillOffered: _skillOfferedCtrl.text.trim(),
          skillWanted:  _exchangeType == 'barter' ? _skillWantedCtrl.text.trim() : null,
          exchangeType: _exchangeType,
          customOffer:  _exchangeType == 'custom'  ? _customOfferCtrl.text.trim() : null,
          tags:         _selectedAvailability.toList(),
          isOpenRequest: _isOpenRequest,
        );
      } else {
        result = await context.read<PostService>().createPost(
          title:        _titleCtrl.text.trim(),
          description:  _descCtrl.text.trim(),
          skillOffered: _skillOfferedCtrl.text.trim(),
          skillWanted:  _exchangeType == 'barter' ? _skillWantedCtrl.text.trim() : null,
          exchangeType: _exchangeType,
          customOffer:  _exchangeType == 'custom'  ? _customOfferCtrl.text.trim() : null,
          tags:         _selectedAvailability.toList(),
          isOpenRequest: _isOpenRequest,
        );
      }

      setState(() => _isLoading = false);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 17),
            const SizedBox(width: 10),
            Text(isEdit ? 'Post updated!' : 'Skill post published!',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 17),
            const SizedBox(width: 10),
            Expanded(child: Text('Failed to publish. Please try again.',
              style: GoogleFonts.dmSans(color: Colors.white))),
          ]),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.post != null;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildAppBar(isEdit, context),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Open Request toggle ──────────────────────────────
                    _openRequestCard().animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 20),

                    // ── POST DETAILS label ───────────────────────────────
                    _sectionLabel('POST DETAILS'),
                    const SizedBox(height: 10),

                    // ── Title ────────────────────────────────────────────
                    _inputField(
                      ctrl: _titleCtrl, focus: _titleFocus,
                      hint: 'Post Title',
                      icon: Icons.title_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a post title' : null,
                    ).animate().fadeIn(delay: 60.ms),
                    const SizedBox(height: 10),

                    // ── Description ──────────────────────────────────────
                    _inputField(
                      ctrl: _descCtrl, focus: _descFocus,
                      hint: 'Description',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please add a description' : null,
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 20),

                    // ── Skills I Offer label ─────────────────────────────
                    _sectionLabel('Skills I Offer'),
                    const SizedBox(height: 10),

                    _inputField(
                      ctrl: _skillOfferedCtrl, focus: _skillOfferedFocus,
                      hint: "Skill You're Offering",
                      icon: Icons.star_border_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter the skill you\'re offering' : null,
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 20),

                    // ── Exchange Type label ──────────────────────────────
                    _sectionLabel('Exchange Type'),
                    const SizedBox(height: 10),

                    // ── Barter / Custom selector ─────────────────────────
                    _exchangeSelector().animate().fadeIn(delay: 110.ms),
                    const SizedBox(height: 16),

                    // ── Skill You Want in Return (ABOVE skill offered) ───
                    _sectionLabel('Skill You Want in Return'),
                    const SizedBox(height: 10),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim,
                            child: SizeTransition(sizeFactor: anim, child: child)),
                      child: _exchangeType == 'barter'
                          ? _inputField(
                              key: const ValueKey('barter'),
                              ctrl: _skillWantedCtrl, focus: _skillWantedFocus,
                              hint: 'Skill You Want in Return',
                              icon: Icons.swap_horiz_rounded,
                              validator: (v) =>
                                  _exchangeType == 'barter' && (v == null || v.trim().isEmpty)
                                  ? 'Please enter the skill you want in return' : null,
                            )
                          : _inputField(
                              key: const ValueKey('custom'),
                              ctrl: _customOfferCtrl, focus: _customOfferFocus,
                              hint: 'Your Custom Offer (e.g. ₹200, Coffee)',
                              icon: Icons.card_giftcard_rounded,
                              validator: (v) =>
                                  _exchangeType == 'custom' && (v == null || v.trim().isEmpty)
                                  ? 'Please describe your custom offer' : null,
                            ),
                    ).animate().fadeIn(delay: 120.ms),
                    const SizedBox(height: 20),

                    // ── AVAILABILITY label ───────────────────────────────
                    _sectionLabel('AVAILABILITY'),
                    const SizedBox(height: 10),

                    _availabilityChips().animate().fadeIn(delay: 130.ms),
                    const SizedBox(height: 20),

                    // ── SESSION FORMAT label ─────────────────────────────
                    _sectionLabel('SESSION FORMAT'),
                    const SizedBox(height: 10),

                    _sessionFormatRow().animate().fadeIn(delay: 140.ms),
                    const SizedBox(height: 28),

                    // ── Publish button ────────────────────────────────────
                    _publishButton(isEdit).animate().fadeIn(delay: 160.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(bool isEdit, BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: _surface,
      padding: EdgeInsets.only(top: topPad, left: 4, right: 16, bottom: 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: _textMain, size: 28),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              isEdit ? 'Edit Post' : 'Create Swap Post',
              style: GoogleFonts.dmSans(
                color: _textMain, fontSize: 17,
                fontWeight: FontWeight.w700, letterSpacing: -0.3,
              ),
            ),
          ),
          // Publish button in header (top-right)
          GestureDetector(
            onTap: _isLoading ? null : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B6CF6), Color(0xFFE96DD8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isLoading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Publish',
                      style: GoogleFonts.dmSans(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(text,
      style: GoogleFonts.dmSans(
        color: _textMain, fontSize: 13,
        fontWeight: FontWeight.w700, letterSpacing: 0.3,
      ));
  }

  // ── Open Request toggle card ──────────────────────────────────────────────
  Widget _openRequestCard() {
    return GestureDetector(
      onTap: () => setState(() => _isOpenRequest = !_isOpenRequest),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isOpenRequest ? _purple.withOpacity(0.6) : _border,
            width: _isOpenRequest ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.help_outline_rounded,
                color: _textSub, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Open Request',
                    style: GoogleFonts.dmSans(
                      color: _textMain, fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                  Text('Let others respond to your request',
                    style: GoogleFonts.dmSans(color: _textSub, fontSize: 12)),
                ],
              ),
            ),
            Switch.adaptive(
              value: _isOpenRequest,
              onChanged: (v) => setState(() => _isOpenRequest = v),
              activeColor: _purple,
              activeTrackColor: _purple.withOpacity(0.35),
              inactiveThumbColor: _textHint,
              inactiveTrackColor: _border,
            ),
          ],
        ),
      ),
    );
  }

  // ── Input field ───────────────────────────────────────────────────────────
  Widget _inputField({
    Key? key,
    required TextEditingController ctrl,
    required FocusNode focus,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final focused = focus.hasFocus;
    return TextFormField(
      key: key,
      controller: ctrl,
      focusNode: focus,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.dmSans(color: _textMain, fontSize: 14.5),
      cursorColor: _purple,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: _textHint, fontSize: 14.5),
        filled: true,
        fillColor: _inputBg,
        prefixIcon: Padding(
          padding: maxLines > 1
              ? const EdgeInsets.only(bottom: 40, left: 2) : EdgeInsets.zero,
          child: Icon(icon, size: 19,
            color: focused ? _purple : _textHint),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _purple, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _errorRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _errorRed, width: 1.6),
        ),
        errorStyle: GoogleFonts.dmSans(color: _errorRed, fontSize: 11.5),
      ),
    );
  }

  // ── Exchange type selector ────────────────────────────────────────────────
  Widget _exchangeSelector() {
    return Row(
      children: [
        Expanded(child: _exchangeTile(
          value: 'barter',
          emoji: '⇌',
          title: 'Barter',
          subtitle: 'Skill for skill',
        )),
        const SizedBox(width: 10),
        Expanded(child: _exchangeTile(
          value: 'custom',
          emoji: '🎁',
          title: 'Custom',
          subtitle: 'Money, treats...',
        )),
      ],
    );
  }

  Widget _exchangeTile({
    required String value,
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    final active = _exchangeType == value;
    return GestureDetector(
      onTap: () => setState(() => _exchangeType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: active ? _purple.withOpacity(0.12) : _inputBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? _purple : _border,
            width: active ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.dmSans(
                      color: active ? _purple : _textMain,
                      fontSize: 13, fontWeight: FontWeight.w700,
                    )),
                  Text(subtitle,
                    style: GoogleFonts.dmSans(color: _textSub, fontSize: 11)),
                ],
              ),
            ),
            if (active)
              Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(
                  color: _purple, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
              ),
          ],
        ),
      ),
    );
  }

  // ── Availability chips ────────────────────────────────────────────────────
  Widget _availabilityChips() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _availabilityOptions.map((option) {
        final selected = _selectedAvailability.contains(option);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedAvailability.remove(option);
            } else {
              _selectedAvailability.add(option);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _purple.withOpacity(0.15) : _inputBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _purple : _border,
                width: selected ? 1.5 : 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option,
                  style: GoogleFonts.dmSans(
                    color: selected ? _purple : _textSub,
                    fontSize: 13, fontWeight: FontWeight.w600,
                  )),
                if (selected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_rounded, color: _purple, size: 13),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Session format row ────────────────────────────────────────────────────
  Widget _sessionFormatRow() {
    return Row(
      children: [
        Expanded(child: _sessionTile('online',   '💻', 'Online')),
        const SizedBox(width: 10),
        Expanded(child: _sessionTile('inperson', '🤝', 'In-Person')),
        const SizedBox(width: 10),
        Expanded(child: _sessionTile('hybrid',   '🔀', 'Hybrid')),
      ],
    );
  }

  Widget _sessionTile(String value, String emoji, String label) {
    final active = _sessionFormat == value;
    return GestureDetector(
      onTap: () => setState(() => _sessionFormat = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? _purple.withOpacity(0.12) : _inputBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? _purple : _border,
            width: active ? 1.6 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                if (active)
                  Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(
                      color: _purple, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 9),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label,
              style: GoogleFonts.dmSans(
                color: active ? _purple : _textSub,
                fontSize: 12, fontWeight: FontWeight.w600,
              )),
          ],
        ),
      ),
    );
  }

  // ── Publish button ────────────────────────────────────────────────────────
  Widget _publishButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9B6CF6), Color(0xFFE96DD8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.40),
              blurRadius: 20, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Save Changes' : 'Publish Skill Post',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}