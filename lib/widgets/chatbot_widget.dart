import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────
// Data model for a single chat message
// ─────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isBot;
  final DateTime time;

  _ChatMessage({required this.text, required this.isBot, required this.time});
}

// ─────────────────────────────────────────
// Fallback Rule-based FAQ engine
// ─────────────────────────────────────────
class _FallbackBotEngine {
  static const List<Map<String, dynamic>> _rules = [
    {
      'keywords': ['hello', 'hi', 'hey', 'start', 'help'],
      'response':
          'Hi! 👋 I\'m the SkillSwap assistant. I can help you with:\n\n• How swapping works\n• Creating posts\n• Starting a chat\n• Confirming swaps\n• Ratings & reviews\n\nJust ask me anything!',
    },
    {
      'keywords': [
        'swap',
        'how swap',
        'how does swap',
        'what is swap',
        'swap work',
      ],
      'response':
          '🔄 Here\'s how a swap works:\n\n1. Browse the Feed for skill posts\n2. Tap a post that interests you\n3. Hit "Start Chat & Swap"\n4. Chat with the person and agree on details\n5. Tap "Confirm Swap" inside the chat\n6. Complete the swap in real life\n7. Tap "Mark Done" and rate each other!',
    },
    {
      'keywords': [
        'create post',
        'post skill',
        'add post',
        'new post',
        'publish',
      ],
      'response':
          '📝 To create a post:\n\n1. Tap the + button in the bottom nav\n2. Fill in your skill title & description\n3. Add the skill you\'re offering\n4. Choose exchange type:\n   • Barter (skill for skill)\n   • Custom (money, treats, etc.)\n5. Add tags like "Urgent" or "Online"\n6. Tap "Publish Skill Post"',
    },
    {
      'keywords': ['barter', 'exchange type', 'custom offer'],
      'response':
          '⇌ Exchange types explained:\n\n🔄 Barter — You offer a skill and receive a skill in return. Great for equal value trades!\n\n🎁 Custom Offer — You or the other person offers something custom like money (₹), coffee, lunch, or any other creative compensation.',
    },
    {
      'keywords': ['chat', 'message', 'contact', 'talk'],
      'response':
          '💬 To start a chat:\n\n1. Open any post in the Feed\n2. Tap "Start Chat & Swap"\n3. A private conversation opens\n4. You can send text messages and images\n5. Once agreed, tap "Confirm Swap"',
    },
    {
      'keywords': ['rating', 'review', 'rate', 'stars', 'feedback'],
      'response':
          '⭐ Rating system:\n\nAfter a swap is marked complete, both parties can rate each other 1-5 stars and leave a review.\n\nRatings build your reputation on SkillSwap — higher ratings make others more likely to swap with you!',
    },
    {
      'keywords': ['profile', 'edit profile', 'username', 'bio', 'skills'],
      'response':
          '👤 To update your profile:\n\n1. Go to the Profile tab\n2. Tap the ✏️ edit icon\n3. Add your bio, campus, and skills\n4. Tap "Save Changes"\n\nAdding skills helps others discover you!',
    },
    {
      'keywords': ['bookmark', 'save post', 'saved'],
      'response':
          '🔖 Bookmarking:\n\nTap the bookmark icon on any post to save it. View all saved posts in your Profile tab under "Bookmarks".',
    },
    {
      'keywords': ['open request', 'request', 'help request'],
      'response':
          '🆘 Open Requests:\n\nThese are help requests posted by students who need assistance. You can find them by tapping the ❓ icon on the Feed screen.\n\nWhen creating a post, toggle "Open Request" ON to post a request instead of an offer.',
    },
    {
      'keywords': ['notification', 'alert', 'notify'],
      'response':
          '🔔 Notifications:\n\nTap the bell icon 🔔 on the Feed screen to see all your notifications including new messages, swap confirmations, and ratings.',
    },
    {
      'keywords': ['leaderboard', 'top users', 'rank', 'ranking'],
      'response':
          '🏆 Leaderboard:\n\nThe leaderboard ranks users by their completed swaps and ratings. Access it from your Profile screen.\n\nYou can also filter the leaderboard by skill category to find top experts in specific areas!',
    },
    {
      'keywords': ['explore', 'search', 'find skill', 'discover'],
      'response':
          '🔍 Explore & Search:\n\nTap the Explore tab to search for specific skills or people. You can:\n• Type in the search bar\n• Tap popular skill tags\n• Filter by Barter or Custom',
    },
    {
      'keywords': ['confirm', 'confirm swap', 'deal', 'agree'],
      'response':
          '🤝 Confirming a swap:\n\n1. Open the chat with the other person\n2. Agree on all swap details\n3. Tap "Confirm Swap" button in the chat header\n4. A system message confirms the swap is pending\n5. Complete the swap in real life\n6. Tap "Mark Done" to finish',
    },
  ];

  static String respond(String input) {
    final lower = input.toLowerCase().trim();
    for (final rule in _rules) {
      final keywords = rule['keywords'] as List<String>;
      for (final kw in keywords) {
        if (lower.contains(kw)) return rule['response'] as String;
      }
    }
    return "🤔 I'm not sure about that. Try asking:\n\n• \"How do I swap?\"\n• \"How do I create a post?\"\n• \"How do ratings work?\"\n• \"What is barter?\"\n• \"How do I start a chat?\"";
  }
}

// ─────────────────────────────────────────
// Floating chatbot FAB
// ─────────────────────────────────────────
class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Chatbot',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const _ChatbotDialog(),
        transitionBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: Builder(
        builder: (context) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: dark ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: dark
                  ? null
                  : Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                      width: 1.5,
                    ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(dark ? 0.35 : 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: dark ? Colors.white : AppColors.primary,
              size: 26,
            ),
          );
        },
      ),
    ).animate().scale(delay: 800.ms, curve: Curves.elasticOut);
  }
}

// ─────────────────────────────────────────
// The actual chat dialog UI
// ─────────────────────────────────────────
class _ChatbotDialog extends StatefulWidget {
  const _ChatbotDialog();

  @override
  State<_ChatbotDialog> createState() => _ChatbotDialogState();
}

class _ChatbotDialogState extends State<_ChatbotDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _quickReplies = [
    'How do I swap?',
    'Create a post',
    'How do ratings work?',
    'What is barter?',
    'Open requests',
  ];

  static const _apiKey = 'YOUR_GEMINI_API_KEY';
  ChatSession? _chatSession;

  // ── Theme tokens (read fresh in build) ─────────────────────────────────
  bool _dark = false;
  Color get _bg => _dark ? const Color(0xFF111318) : Colors.white;
  Color get _sf => _dark ? const Color(0xFF1A1D24) : Colors.white;
  Color get _fv => _dark ? const Color(0xFF1E222C) : const Color(0xFFF2F2F4);
  Color get _bd => _dark ? const Color(0xFF2A2D36) : const Color(0xFFE5E5E5);
  Color get _tp => _dark ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _dark ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color get _tl => _dark ? const Color(0xFF555862) : const Color(0xFFAAAAAA);
  Color get _bubble =>
      _dark ? const Color(0xFF22252E) : const Color(0xFFF2F2F4);

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            'Hi! 👋 I\'m your AI SkillSwap assistant.\n\nHow can I help you today?',
        isBot: true,
        time: DateTime.now(),
      ),
    );

    if (_apiKey != 'YOUR_GEMINI_API_KEY') {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(
          'You are the SkillSwap Assistant, a helpful AI. '
          'SkillSwap is a platform where university students can barter skills. '
          'Answer questions about the app features. Be friendly, concise, and use emojis.',
        ),
      );
      _chatSession = model.startChat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(
        _ChatMessage(text: text.trim(), isBot: false, time: DateTime.now()),
      );
      _isTyping = true;
    });
    _scrollToBottom();
    _getAIResponse(text.trim());
  }

  Future<void> _getAIResponse(String text) async {
    if (_chatSession == null) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(
            _ChatMessage(
              text: _FallbackBotEngine.respond(text),
              isBot: true,
              time: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      });
      return;
    }
    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: response.text ?? 'Sorry, I could not generate a response.',
            isBot: true,
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text:
                'Oops, something went wrong. Check your connection or API key.',
            isBot: true,
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Refresh theme tokens on every build
    _dark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: _dark ? Border.all(color: _bd, width: 1) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_dark ? 0.45 : 0.13),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: BoxDecoration(
                  // Dark: solid deep surface with primary accent left-border feel
                  // Light: keep the original warm gradient
                  gradient: _dark ? null : AppColors.accentGradient,
                  color: _dark ? const Color(0xFF1A1D24) : null,
                  border: _dark
                      ? Border(bottom: BorderSide(color: _bd, width: 1))
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xxl),
                    topRight: Radius.circular(AppRadius.xxl),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _dark
                            ? AppColors.primary.withOpacity(0.18)
                            : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: _dark ? AppColors.primary : Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SkillSwap Assistant',
                            style: GoogleFonts.dmSans(
                              color: _dark ? _tp : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Ask me anything about the app',
                            style: GoogleFonts.dmSans(
                              color: _dark
                                  ? _ts
                                  : Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: _dark ? _ts : Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Messages ──────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_isTyping && i == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessage(_messages[i]);
                  },
                ),
              ),

              // ── Quick reply chips ─────────────────────────────────────
              if (_messages.length <= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickReplies.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _sendMessage(_quickReplies[i]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _fv,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                              border: Border.all(color: _bd),
                            ),
                            child: Text(
                              _quickReplies[i],
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Input bar ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: _sf,
                  border: Border(top: BorderSide(color: _bd, width: 1)),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.xxl),
                    bottomRight: Radius.circular(AppRadius.xxl),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _fv,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: _bd, width: 1),
                        ),
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.sentences,
                          style: GoogleFonts.dmSans(color: _tp, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Ask something...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            hintStyle: GoogleFonts.dmSans(
                              color: _tl,
                              fontSize: 13,
                            ),
                          ),
                          onSubmitted: _sendMessage,
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(_controller.text),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: _dark
                              ? AppColors.primaryGradient
                              : AppColors.accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_dark ? AppColors.primary : AppColors.accent)
                                      .withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.only(
        left: msg.isBot ? 0 : 40,
        right: msg.isBot ? 40 : 0,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (msg.isBot) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: msg.isBot ? null : AppColors.primaryGradient,
                color: msg.isBot ? _bubble : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isBot ? 4 : 16),
                  bottomRight: Radius.circular(msg.isBot ? 16 : 4),
                ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.5,
                  color: msg.isBot ? _tp : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _bubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  child: _TypingDot(color: _tl),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _TypingDot extends StatefulWidget {
  final Color color;
  const _TypingDot({required this.color});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
