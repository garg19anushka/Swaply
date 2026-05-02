import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  CreatePostScreen  –  Dual-themed (Light/Dark)
//  Light : pure #FFFFFF bg, #F2F2F4 field fills, 1px #E5E5E5 borders
//  Dark  : #111318 bg,  #1E222C field fills, 1px #2A2D36 borders
//  ✦ Neutral header — no gradient, simple back arrow + title
//  ✦ Clean rounded input fields
//  ✦ Open Request toggle card
//  ✦ Exchange Type: Barter / Custom selector
//  ✦ Tags wrap
//  ✦ Neutral "Publish" button at bottom
// ═══════════════════════════════════════════════════════════════════════════
class CreatePostScreen extends StatefulWidget {
  /// Pass an existing post to prefill fields for editing (optional).
  final PostModel? post;
  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey               = GlobalKey<FormState>();
  final _titleCtrl             = TextEditingController();
  final _descCtrl              = TextEditingController();
  final _skillOfferedCtrl      = TextEditingController();
  final _skillWantedCtrl       = TextEditingController();
  final _customOfferCtrl       = TextEditingController();

  String _exchangeType  = 'barter';
  bool   _isOpenRequest = false;
  bool   _isLoading     = false;
  final List<String> _tags = [];

  static const _availableTags = [
    'Urgent', 'Quick Help', 'Long-term', 'Online',
    'In-person', 'Flexible', 'Beginner-friendly',
  ];

  // ── theme shortcuts ─────────────────────────────────────────────────────
  bool   get _d  => Theme.of(context).brightness == Brightness.dark;
  Color  get _bg => _d ? const Color(0xFF111318) : Colors.white;
  Color  get _sf => _d ? const Color(0xFF161A22) : Colors.white;
  Color  get _fv => _d ? const Color(0xFF1E222C) : const Color(0xFFF2F2F4);
  Color  get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFE5E5E5);
  Color  get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color  get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color  get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    // Prefill if editing
    if (widget.post != null) {
      final p = widget.post!;
      _titleCtrl.text          = p.title;
      _descCtrl.text           = p.description;
      _skillOfferedCtrl.text   = p.skillOffered;
      _skillWantedCtrl.text    = p.skillWanted ?? '';
      _customOfferCtrl.text    = p.customOffer ?? '';
      _exchangeType            = p.exchangeType;
      _isOpenRequest           = p.isOpenRequest;
      _tags.addAll(p.tags);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _skillOfferedCtrl.dispose();
    _skillWantedCtrl.dispose();
    _customOfferCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final isEdit = widget.post != null;
    PostModel? result;

    if (isEdit) {
      // ── Update existing post ──────────────────────────────────────────────
      result = await context.read<PostService>().updatePost(
        postId:       widget.post!.id,
        title:        _titleCtrl.text.trim(),
        description:  _descCtrl.text.trim(),
        skillOffered: _skillOfferedCtrl.text.trim(),
        skillWanted:  _exchangeType == 'barter'
            ? _skillWantedCtrl.text.trim() : null,
        exchangeType: _exchangeType,
        customOffer:  _exchangeType == 'custom'
            ? _customOfferCtrl.text.trim() : null,
        tags:         _tags,
        isOpenRequest: _isOpenRequest,
      );
    } else {
      // ── Create new post ───────────────────────────────────────────────────
      result = await context.read<PostService>().createPost(
        title:        _titleCtrl.text.trim(),
        description:  _descCtrl.text.trim(),
        skillOffered: _skillOfferedCtrl.text.trim(),
        skillWanted:  _exchangeType == 'barter'
            ? _skillWantedCtrl.text.trim() : null,
        exchangeType: _exchangeType,
        customOffer:  _exchangeType == 'custom'
            ? _customOfferCtrl.text.trim() : null,
        tags:         _tags,
        isOpenRequest: _isOpenRequest,
      );
    }

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 17),
          const SizedBox(width: 10),
          Text(isEdit ? 'Post updated!' : 'Post published!',
              style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.post != null;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Neutral sticky header ────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _sf,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: _tp, size: 19),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              isEdit ? 'Edit Post' : 'Create Post',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: _bd),
            ),
          ),

          // ── Form ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 20),

                    // ── Open Request toggle ──────────────────────────────
                    _ToggleCard(
                      value: _isOpenRequest,
                      onChanged: (v) => setState(() => _isOpenRequest = v),
                      d: _d, sf: _sf, bd: _bd, tp: _tp, ts: _ts,
                    ).animate().fadeIn(duration: 320.ms),

                    const SizedBox(height: 22),
                    _label('Post Details', _tp),
                    const SizedBox(height: 10),

                    // ── Post title ───────────────────────────────────────
                    _Field(
                      controller: _titleCtrl,
                      label: 'Post Title',
                      hint: 'e.g. Teaching Python basics',
                      icon: Icons.title_rounded,
                      fv: _fv, bd: _bd, tp: _tp, ts: _ts, d: _d,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ).animate().fadeIn(delay: 60.ms),

                    const SizedBox(height: 12),

                    // ── Description ──────────────────────────────────────
                    _Field(
                      controller: _descCtrl,
                      label: 'Description',
                      hint: 'Describe what you offer and what you need...',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      fv: _fv, bd: _bd, tp: _tp, ts: _ts, d: _d,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Description is required' : null,
                    ).animate().fadeIn(delay: 80.ms),

                    const SizedBox(height: 12),

                    // ── Skill offered ────────────────────────────────────
                    _Field(
                      controller: _skillOfferedCtrl,
                      label: 'Skill You\'re Offering',
                      hint: 'e.g. Python, Guitar, UI Design',
                      icon: Icons.star_outline_rounded,
                      fv: _fv, bd: _bd, tp: _tp, ts: _ts, d: _d,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 22),
                    _label('Exchange Type', _tp),
                    const SizedBox(height: 10),

                    // ── Exchange type selector ───────────────────────────
                    _ExchangeSelector(
                      value: _exchangeType,
                      onChanged: (v) => setState(() => _exchangeType = v),
                      d: _d, sf: _sf, fv: _fv, bd: _bd,
                      tp: _tp, ts: _ts, tl: _tl,
                    ).animate().fadeIn(delay: 110.ms),

                    const SizedBox(height: 12),

                    // ── Skill wanted / custom offer ──────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, anim) =>
                          SizeTransition(sizeFactor: anim, child: child),
                      child: _exchangeType == 'barter'
                          ? _Field(
                              key: const ValueKey('barter'),
                              controller: _skillWantedCtrl,
                              label: 'Skill You Want in Return',
                              hint: 'e.g. Graphic Design, Spanish',
                              icon: Icons.swap_horiz_rounded,
                              fv: _fv, bd: _bd, tp: _tp, ts: _ts, d: _d,
                              validator: (v) =>
                                  _exchangeType == 'barter' &&
                                      (v == null || v.isEmpty)
                                  ? 'Required for barter' : null,
                            )
                          : _Field(
                              key: const ValueKey('custom'),
                              controller: _customOfferCtrl,
                              label: 'Your Custom Offer',
                              hint: 'e.g. ₹200, Coffee, Lunch',
                              icon: Icons.card_giftcard_rounded,
                              fv: _fv, bd: _bd, tp: _tp, ts: _ts, d: _d,
                              validator: (v) =>
                                  _exchangeType == 'custom' &&
                                      (v == null || v.isEmpty)
                                  ? 'Required for custom offer' : null,
                            ),
                    ).animate().fadeIn(delay: 120.ms),

                    const SizedBox(height: 22),
                    _label('Tags', _tp),
                    const SizedBox(height: 10),

                    // ── Tags ─────────────────────────────────────────────
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final on = _tags.contains(tag);
                        return GestureDetector(
                          onTap: () => setState(() =>
                              on ? _tags.remove(tag) : _tags.add(tag)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 170),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: on
                                  ? AppColors.primary.withOpacity(0.1)
                                  : _fv,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: on ? AppColors.primary : _bd,
                                width: on ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (on) ...[
                                  const Icon(Icons.check_rounded,
                                      size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                ],
                                Text(tag,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12.5,
                                      fontWeight: on
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: on ? AppColors.primary : _ts,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 140.ms),

                    const SizedBox(height: 32),

                    // ── Publish / Save button ─────────────────────────────
                    _PublishButton(
                      label: isEdit ? 'Save Changes' : 'Publish Skill Post',
                      icon: isEdit
                          ? Icons.save_rounded
                          : Icons.rocket_launch_rounded,
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _submit,
                      d: _d,
                    ).animate().fadeIn(delay: 160.ms),

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

  Widget _label(String text, Color color) => Text(text,
      style: GoogleFonts.dmSans(
          color: color, fontSize: 13.5,
          fontWeight: FontWeight.w700, letterSpacing: -0.1));
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable input field
// ─────────────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final int maxLines;
  final Color fv, bd, tp, ts;
  final bool d;
  final String? Function(String?)? validator;

  const _Field({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.fv,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.d,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.dmSans(color: tp, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.dmSans(color: ts, fontSize: 13.5),
        hintStyle: GoogleFonts.dmSans(color: ts, fontSize: 13.5),
        filled: true,
        fillColor: fv,
        prefixIcon: Padding(
          padding: maxLines > 1
              ? const EdgeInsets.only(bottom: 36, left: 2)
              : EdgeInsets.zero,
          child: Icon(icon, size: 19, color: ts),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 46),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: bd, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: bd, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Open Request toggle card
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleCard extends StatelessWidget {
  final bool value, d;
  final ValueChanged<bool> onChanged;
  final Color sf, bd, tp, ts;

  const _ToggleCard({
    required this.value,
    required this.onChanged,
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: sf,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: value
              ? AppColors.warning.withOpacity(0.5)
              : bd,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.warning.withOpacity(0.12)
                  : (d ? const Color(0xFF22252E) : const Color(0xFFF4F4F6)),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.help_outline_rounded,
                color: value ? AppColors.warning : ts, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Open Request',
                    style: GoogleFonts.dmSans(
                        color: tp, fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text('Let others respond to your request',
                    style: GoogleFonts.dmSans(color: ts, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Exchange type selector: Barter | Custom
// ─────────────────────────────────────────────────────────────────────────────
class _ExchangeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool d;
  final Color sf, fv, bd, tp, ts, tl;

  const _ExchangeSelector({
    required this.value,
    required this.onChanged,
    required this.d,
    required this.sf,
    required this.fv,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tile('barter', '⇌', 'Barter', 'Skill for skill')),
        const SizedBox(width: 10),
        Expanded(child: _tile('custom', '🎁', 'Custom', 'Money, treats...')),
      ],
    );
  }

  Widget _tile(String v, String emoji, String title, String subtitle) {
    final active = value == v;
    return GestureDetector(
      onTap: () => onChanged(v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.08)
              : fv,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? AppColors.primary : bd,
            width: active ? 1.5 : 1,
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
                          color: active ? AppColors.primary : tp,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          color: ts, fontSize: 11)),
                ],
              ),
            ),
            if (active)
              Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 11),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Neutral publish button
// ─────────────────────────────────────────────────────────────────────────────
class _PublishButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool d;

  const _PublishButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
    required this.d,
  });

  @override
  State<_PublishButton> createState() => _PublishButtonState();
}

class _PublishButtonState extends State<_PublishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 200),
    lowerBound: 0.96,
    upperBound: 1.0,
    value: 1.0,
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
            gradient: (enabled && widget.d) ? AppColors.primaryGradient : null,
            color: (enabled && widget.d) ? null
                : enabled
                    ? AppColors.primary
                    : (widget.d
                        ? const Color(0xFF22252E)
                        : const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [BoxShadow(
                    color: AppColors.primary.withOpacity(widget.d ? 0.28 : 0.20),
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
                      Icon(widget.icon,
                          color: enabled ? Colors.white
                              : (widget.d
                                  ? const Color(0xFF555862)
                                  : const Color(0xFFAAAAAA)),
                          size: 17),
                      const SizedBox(width: 8),
                      Text(widget.label,
                          style: GoogleFonts.dmSans(
                            color: enabled ? Colors.white
                                : (widget.d
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