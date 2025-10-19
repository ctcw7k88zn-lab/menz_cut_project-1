import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/reviews_provider.dart';
import '../providers/auth_provider.dart';

class ReviewInputWidget extends ConsumerStatefulWidget {
  final String salonId;
  final String? appointmentId;
  final VoidCallback? onReviewSubmitted;

  const ReviewInputWidget({
    super.key,
    required this.salonId,
    this.appointmentId,
    this.onReviewSubmitted,
  });

  @override
  ConsumerState<ReviewInputWidget> createState() => _ReviewInputWidgetState();
}

class _ReviewInputWidgetState extends ConsumerState<ReviewInputWidget> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      await ref.read(reviewsProvider.notifier).createReview(
        customerId: authState.user!.id,
        salonId: widget.salonId,
        appointmentId: widget.appointmentId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        
        _commentController.clear();
        _selectedRating = 0;
        
        widget.onReviewSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Write a Review',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.primaryMauve,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Rating Selection
            Text(
              'Rating',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: AppTheme.accentGold,
                      size: 32.0,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16.0),
            
            // Comment Input
            Text(
              'Comment',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey[500],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: AppTheme.primaryMauve, width: 2.0),
                ),
                contentPadding: const EdgeInsets.all(12.0),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please write a comment';
                }
                if (value.trim().length < 10) {
                  return 'Comment must be at least 10 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMauve,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20.0,
                        width: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
