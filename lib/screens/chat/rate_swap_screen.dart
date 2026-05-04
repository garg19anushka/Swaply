import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart'; // FIX: import SwapModel from here
import '../../models/profile_model.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/gradient_button.dart';

class RateSwapScreen extends StatefulWidget {
  final String chatId;
  final ProfileModel? otherUser;

  const RateSwapScreen({super.key, required this.chatId, this.otherUser});

  @override
  State<RateSwapScreen> createState() => _RateSwapScreenState();
}

class _RateSwapScreenState extends State<RateSwapScreen> {
  double _rating = 4;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final chatService = context.read<ChatService>();
    final swaps = await chatService.fetchUserSwaps();

    // FIX: SwapModel is now imported from chat_model.dart — no longer called as a method
    final swap = swaps.firstWhere(
      (s) => s.chatId == widget.chatId,
      orElse: () => SwapModel(
        id: '',
        chatId: '',
        initiatorId: '',
        receiverId: '',
        status: '',
        createdAt: DateTime.now(),
      ),
    );

    if (swap.id.isEmpty) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No completed swap found to rate.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final success = await chatService.submitRating(
      swapId: swap.id,
      rateeId: widget.otherUser?.id ?? '',
      rating: _rating.toInt(),
      review: _reviewController.text.trim().isEmpty
          ? null
          : _reviewController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rating submitted! Thanks for your feedback.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 90,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
              title: const Text(
                'Rate Your Swap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 0, 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  AvatarWidget(
                    avatarUrl: widget.otherUser?.avatarUrl,
                    username: widget.otherUser?.username ?? '',
                    radius: 40,
                  ).animate().scale(delay: 100.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  Text(
                    widget.otherUser?.fullName ??
                        widget.otherUser?.username ??
                        'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${widget.otherUser?.username ?? ''}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'How was your experience?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (_, __) => const Icon(
                      Icons.star_rounded,
                      color: AppColors.warning,
                    ),
                    onRatingUpdate: (r) => setState(() => _rating = r),
                    itemSize: 44,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  Text(
                    _ratingLabel(_rating.toInt()),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Leave a review (optional)...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 28),
                  GradientButton(
                    onPressed: _isSubmitting ? null : _submit,
                    isLoading: _isSubmitting,
                    label: 'Submit Rating',
                    icon: Icons.star_rounded,
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
