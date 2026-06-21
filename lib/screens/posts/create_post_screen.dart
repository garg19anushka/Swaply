import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? post;
  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skillOfferedCtrl = TextEditingController();
  final _skillWantedCtrl = TextEditingController();
  final _customOfferCtrl = TextEditingController();
  final _customTagCtrl = TextEditingController();

  final _titleFocus = FocusNode();
  final _descFocus = FocusNode();
  final _skillOfferedFocus = FocusNode();
  final _skillWantedFocus = FocusNode();
  final _customOfferFocus = FocusNode();

  // ── Post mode: offer vs need ──────────────────────────────────────────────
  bool _isOfferMode = true; // true = "I want to OFFER", false = "I need"

  String _exchangeType = 'barter';
  bool _isOpenRequest = false;
  bool _isLoading = false;

  // ── Tag system ────────────────────────────────────────────────────────────
  int _tagTabIdx = 0;
  final List<String> _tagTabs = [
    'Urgency',
    'Format',
    'Level',
    'Skill',
    'Extras',
  ];
  final Map<String, List<String>> _tagOptions = {
    'Urgency': ['Urgent', 'Quick Help', 'Flexible Timeline', 'Long-term'],
    'Format': ['Online', 'In-Person', 'Hybrid', 'Async'],
    'Level': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    'Skill': [
      'Coding',
      'Design',
      'Music',
      'Writing',
      'Language',
      'Fitness',
      'Finance',
    ],
    'Extras': [
      'Portfolio Project',
      'Certificate',
      'Mentorship',
      'Fun & Casual',
    ],
  };
  final Set<String> _selectedTags = {};
  final List<String> _customTags = [];

  // ── Availability ──────────────────────────────────────────────────────────
  DateTime? _fromDate;
  DateTime? _toDate;
  final Set<String> _selectedDays = {};
  String? _selectedTime; // null = none selected
  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final List<Map<String, String>> _timeSlots = [
    {'label': 'Morning (6–12)', 'icon': '🌅'},
    {'label': 'Afternoon (12–17)', 'icon': '☀️'},
    {'label': 'Evening (17–21)', 'icon': '🌆'},
    {'label': 'Night (21–24)', 'icon': '🌙'},
    {'label': 'Flexible', 'icon': '🕐'},
  ];

  String _sessionFormat = 'online';

  // ── Palette ────────────────────────────────────────────────────────────────
  static const _purple = Color(0xFF6C63FF);
  static const _purpleStart = Color(0xFF5B4FE8);
  static const _purpleEnd = Color(0xFF7B6FF0);
  static const _errorRed = Color(0xFFFF5C6A);

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _dark ? const Color(0xFF0D0E17) : const Color(0xFFF4F4FB);
  Color get _surface => _dark ? const Color(0xFF161824) : Colors.white;
  Color get _inputBg =>
      _dark ? const Color(0xFF1C1D2A) : const Color(0xFFEFEEF9);
  Color get _border =>
      _dark ? const Color(0xFF2E3048) : const Color(0xFFDDDCF0);
  Color get _textMain => _dark ? Colors.white : const Color(0xFF0D0C1E);
  Color get _textSub =>
      _dark ? const Color(0xFF8E90A8) : const Color(0xFF6B698A);
  Color get _textHint =>
      _dark ? const Color(0xFF545670) : const Color(0xFFAAAAAC);

  @override
  void initState() {
    super.initState();
    for (final fn in [
      _titleFocus,
      _descFocus,
      _skillOfferedFocus,
      _skillWantedFocus,
      _customOfferFocus,
    ]) {
      fn.addListener(() => setState(() {}));
    }
    if (widget.post != null) {
      final p = widget.post!;
      _titleCtrl.text = p.title;
      _descCtrl.text = p.description;
      _skillOfferedCtrl.text = p.skillOffered;
      _skillWantedCtrl.text = p.skillWanted ?? '';
      _customOfferCtrl.text = p.customOffer ?? '';
      _exchangeType = p.exchangeType;
      _isOpenRequest = p.isOpenRequest;
      _selectedTags.addAll(p.tags);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _skillOfferedCtrl,
      _skillWantedCtrl,
      _customOfferCtrl,
      _customTagCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _titleFocus,
      _descFocus,
      _skillOfferedFocus,
      _skillWantedFocus,
      _customOfferFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  List<String> get _allTags => [
    ..._selectedTags,
    ..._customTags,
    if (_selectedDays.isNotEmpty) ..._selectedDays,
    if (_selectedTime != null) _selectedTime!,
    if (_fromDate != null)
      'From: ${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}',
    if (_toDate != null)
      'To: ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
  ];

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final isEdit = widget.post != null;
    try {
      PostModel? result;
      if (isEdit) {
        result = await context.read<PostService>().updatePost(
          postId: widget.post!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          skillOffered: _skillOfferedCtrl.text.trim(),
          skillWanted: _exchangeType == 'barter'
              ? _skillWantedCtrl.text.trim()
              : null,
          exchangeType: _exchangeType,
          customOffer: _exchangeType == 'custom'
              ? _customOfferCtrl.text.trim()
              : null,
          tags: _allTags,
          isOpenRequest: _isOpenRequest,
        );
      } else {
        result = await context.read<PostService>().createPost(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          skillOffered: _skillOfferedCtrl.text.trim(),
          skillWanted: _exchangeType == 'barter'
              ? _skillWantedCtrl.text.trim()
              : null,
          exchangeType: _exchangeType,
          customOffer: _exchangeType == 'custom'
              ? _customOfferCtrl.text.trim()
              : null,
          tags: _allTags,
          isOpenRequest: _isOpenRequest,
        );
      }
      setState(() => _isLoading = false);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Post updated!' : 'Skill post published!',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4B4ACF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to publish. Please try again.',
                    style: GoogleFonts.dmSans(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.post != null;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildAppBar(isEdit),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── OFFER / NEED mode toggle ─────────────────────────
                    const SizedBox(height: 20),
                    _modeToggle().animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 24),

                    // ── POST DETAILS ─────────────────────────────────────
                    _sectionHeader(Icons.description_outlined, 'Post Details'),
                    const SizedBox(height: 12),
                    _inputField(
                      ctrl: _titleCtrl,
                      focus: _titleFocus,
                      hint: _isOfferMode
                          ? 'What skill are you offering?'
                          : 'What skill do you need?',
                      icon: Icons.title_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a title'
                          : null,
                    ).animate().fadeIn(delay: 60.ms),
                    const SizedBox(height: 10),
                    _inputField(
                      ctrl: _descCtrl,
                      focus: _descFocus,
                      hint: 'Describe in detail…',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please add a description'
                          : null,
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 24),

                    // ── SKILLS ───────────────────────────────────────────
                    _sectionHeader(Icons.swap_horiz_rounded, 'Skill Exchange'),
                    const SizedBox(height: 12),
                    _inputField(
                      ctrl: _skillOfferedCtrl,
                      focus: _skillOfferedFocus,
                      hint: _isOfferMode
                          ? 'Skill I\'m offering'
                          : 'Skill I\'m looking for',
                      icon: Icons.star_border_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter the skill'
                          : null,
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 10),
                    _exchangeSelector().animate().fadeIn(delay: 110.ms),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SizeTransition(sizeFactor: anim, child: child),
                      ),
                      child: _exchangeType == 'barter'
                          ? _inputField(
                              key: const ValueKey('barter'),
                              ctrl: _skillWantedCtrl,
                              focus: _skillWantedFocus,
                              hint: _isOpenRequest
                                  ? 'Skill I want in return (optional)'
                                  : 'Skill I want in return',
                              icon: Icons.swap_horiz_rounded,
                              validator: (v) =>
                                  !_isOpenRequest &&
                                      _exchangeType == 'barter' &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Please enter the skill you want'
                                  : null,
                            )
                          : _inputField(
                              key: const ValueKey('custom'),
                              ctrl: _customOfferCtrl,
                              focus: _customOfferFocus,
                              hint: _isOpenRequest
                                  ? 'Your custom offer (optional)'
                                  : 'Your custom offer (e.g. ₹200, Coffee)',
                              icon: Icons.card_giftcard_rounded,
                              validator: (v) =>
                                  !_isOpenRequest &&
                                      _exchangeType == 'custom' &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Please describe your custom offer'
                                  : null,
                            ),
                    ).animate().fadeIn(delay: 120.ms),
                    const SizedBox(height: 10),

                    // Open request toggle (compact)
                    _openRequestTile().animate().fadeIn(delay: 130.ms),
                    const SizedBox(height: 24),

                    // ── ADD TAGS ─────────────────────────────────────────
                    _sectionHeader(Icons.label_outline_rounded, 'Add Tags'),
                    const SizedBox(height: 12),
                    _tagsSection().animate().fadeIn(delay: 140.ms),
                    const SizedBox(height: 24),

                    // ── AVAILABILITY ─────────────────────────────────────
                    _sectionHeader(
                      Icons.calendar_today_outlined,
                      'Availability',
                    ),
                    const SizedBox(height: 12),
                    _availabilitySection().animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 24),

                    // ── SESSION FORMAT ───────────────────────────────────
                    _sectionHeader(Icons.devices_rounded, 'Session Format'),
                    const SizedBox(height: 12),
                    _sessionFormatRow().animate().fadeIn(delay: 160.ms),
                    const SizedBox(height: 32),

                    _publishButton(isEdit).animate().fadeIn(delay: 180.ms),
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
  Widget _buildAppBar(bool isEdit) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_purpleStart, _purpleEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: topPad + 24,
        left: 20,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isEdit ? 'Edit Post' : 'Create Swap Post',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── OFFER / NEED toggle ───────────────────────────────────────────────────
  Widget _modeToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(child: _modeTile(true, 'I want to OFFER')),
          Expanded(child: _modeTile(false, 'I need')),
        ],
      ),
    );
  }

  Widget _modeTile(bool isOffer, String label) {
    final active = _isOfferMode == isOffer;
    return GestureDetector(
      onTap: () => setState(() => _isOfferMode = isOffer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [_purpleStart, _purpleEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _purple.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: active ? Colors.white : _textSub,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: _purple),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: _textMain,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── Open Request compact tile ─────────────────────────────────────────────
  Widget _openRequestTile() {
    return GestureDetector(
      onTap: () => setState(() => _isOpenRequest = !_isOpenRequest),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isOpenRequest ? _purple.withOpacity(0.09) : _inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isOpenRequest ? _purple.withOpacity(0.5) : _border,
            width: _isOpenRequest ? 1.5 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.public_rounded,
              color: _isOpenRequest ? _purple : _textHint,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Open Request – anyone can respond',
                style: GoogleFonts.dmSans(
                  color: _isOpenRequest ? _purple : _textSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(
              value: _isOpenRequest,
              onChanged: (v) => setState(() => _isOpenRequest = v),
              activeColor: _purple,
              activeTrackColor: _purple.withOpacity(0.3),
              inactiveThumbColor: _textHint,
              inactiveTrackColor: _border,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tags section ──────────────────────────────────────────────────────────
  Widget _tagsSection() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tagTabs.length, (i) {
                final active = _tagTabIdx == i;
                return GestureDetector(
                  onTap: () => setState(() => _tagTabIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active ? _purple : _inputBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? _purple : _border,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      _tagTabs[i],
                      style: GoogleFonts.dmSans(
                        color: active ? Colors.white : _textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Tag chips for current tab
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_tagOptions[_tagTabs[_tagTabIdx]] ?? []).map((tag) {
              final selected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected)
                    _selectedTags.remove(tag);
                  else
                    _selectedTags.add(tag);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _purple.withOpacity(0.12) : _inputBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _purple : _border,
                      width: selected ? 1.5 : 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: GoogleFonts.dmSans(
                          color: selected ? _purple : _textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_rounded, color: _purple, size: 12),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Custom tag input
          Container(
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border, width: 1.2),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.add_rounded, color: _textHint, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _customTagCtrl,
                    style: GoogleFonts.dmSans(color: _textMain, fontSize: 13),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      hintText: 'Add custom tag…',
                      hintStyle: GoogleFonts.dmSans(
                        color: _textHint,
                        fontSize: 13,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onSubmitted: (v) {
                      final tag = v.trim();
                      if (tag.isNotEmpty && !_customTags.contains(tag)) {
                        setState(() {
                          _customTags.add(tag);
                          _customTagCtrl.clear();
                        });
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final tag = _customTagCtrl.text.trim();
                    if (tag.isNotEmpty && !_customTags.contains(tag)) {
                      setState(() {
                        _customTags.add(tag);
                        _customTagCtrl.clear();
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_purpleStart, _purpleEnd],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom tags preview
          if (_customTags.isNotEmpty || _selectedTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._selectedTags.map(
                  (t) => _tagPill(
                    t,
                    () => setState(() => _selectedTags.remove(t)),
                  ),
                ),
                ..._customTags.map(
                  (t) =>
                      _tagPill(t, () => setState(() => _customTags.remove(t))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tagPill(String tag, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: GoogleFonts.dmSans(
              color: _purple,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 10, color: _purple),
            ),
          ),
        ],
      ),
    );
  }

  // ── Availability section ──────────────────────────────────────────────────
  Widget _availabilitySection() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          Text(
            'Date Range',
            style: GoogleFonts.dmSans(
              color: _textSub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _datePicker(
                  label: 'From',
                  date: _fromDate,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: _purple,
                            brightness: _dark
                                ? Brightness.dark
                                : Brightness.light,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setState(() => _fromDate = d);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: _textHint,
                ),
              ),
              Expanded(
                child: _datePicker(
                  label: 'To',
                  date: _toDate,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? (_fromDate ?? DateTime.now()),
                      firstDate: _fromDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: _purple,
                            brightness: _dark
                                ? Brightness.dark
                                : Brightness.light,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setState(() => _toDate = d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Days available
          Text(
            'Days Available',
            style: GoogleFonts.dmSans(
              color: _textSub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekDays.map((day) {
              final sel = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel)
                    _selectedDays.remove(day);
                  else
                    _selectedDays.add(day);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: sel ? _purple : _inputBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? _purple : _border,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      day,
                      style: GoogleFonts.dmSans(
                        color: sel ? Colors.white : _textSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Preferred time
          Text(
            'Preferred Time',
            style: GoogleFonts.dmSans(
              color: _textSub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((slot) {
              final sel = _selectedTime == slot['label'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedTime = sel ? null : slot['label']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? _purple.withOpacity(0.12) : _inputBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? _purple : _border,
                      width: sel ? 1.5 : 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(slot['icon']!, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        slot['label']!,
                        style: GoogleFonts.dmSans(
                          color: sel ? _purple : _textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate ? _purple.withOpacity(0.5) : _border,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 15,
              color: hasDate ? _purple : _textHint,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: _textHint,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  hasDate
                      ? '${date!.day}/${date.month}/${date.year}'
                      : 'Select',
                  style: GoogleFonts.dmSans(
                    color: hasDate ? _textMain : _textHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
    // Fill colour: stay the same on focus — no grey wash, no yellow line
    final fill = _inputBg;
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
        fillColor: fill,
        // Remove the default focus overlay / splash tint
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        prefixIcon: Padding(
          padding: maxLines > 1
              ? const EdgeInsets.only(bottom: 40, left: 2)
              : EdgeInsets.zero,
          child: Icon(icon, size: 19, color: focused ? _purple : _textHint),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        // All border states use OutlineInputBorder so no underline ever shows
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _border, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _purple, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _errorRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _errorRed, width: 1.6),
        ),
        errorStyle: GoogleFonts.dmSans(color: _errorRed, fontSize: 11.5),
      ),
    );
  }

  // ── Exchange type selector ────────────────────────────────────────────────
  Widget _exchangeSelector() {
    return Row(
      children: [
        Expanded(
          child: _exchangeTile(
            value: 'barter',
            emoji: '⇌',
            title: 'Barter',
            subtitle: 'Skill for skill',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _exchangeTile(
            value: 'custom',
            emoji: '🎁',
            title: 'Custom',
            subtitle: 'Money, treats…',
          ),
        ),
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
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: active ? _purple : _textMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(color: _textSub, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: _purple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Session format ────────────────────────────────────────────────────────
  Widget _sessionFormatRow() {
    return Row(
      children: [
        Expanded(child: _sessionTile('online', '💻', 'Online')),
        const SizedBox(width: 10),
        Expanded(child: _sessionTile('inperson', '🤝', 'In-Person')),
        const SizedBox(width: 10),
        Expanded(child: _sessionTile('hybrid', '🔀', 'Hybrid')),
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
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 9,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: active ? _purple : _textSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            colors: [_purpleStart, _purpleEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _purpleStart.withOpacity(0.40),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Save Changes' : 'Publish Skill Post',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
