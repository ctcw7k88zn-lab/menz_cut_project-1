import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/app_api.dart';

class ReviewsNotifier extends AsyncNotifier<List<ReviewModel>> {
  @override
  Future<List<ReviewModel>> build() async {
    // Initialize with empty list
    return [];
  }

  // Load reviews for a specific salon
  Future<void> loadReviewsForSalon(String salonId) async {
    state = const AsyncValue.loading();
    try {
      print('🔍 ReviewsProvider: Loading reviews for salon: $salonId');
      final reviews = await AppApi.getReviewsForSalon(salonId);
      print('🔍 ReviewsProvider: Loaded ${reviews.length} reviews for salon');
      state = AsyncValue.data(reviews);
    } catch (error, stackTrace) {
      print('❌ ReviewsProvider: Error loading reviews for salon: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Load reviews for a specific customer
  Future<void> loadReviewsForCustomer(String customerId) async {
    state = const AsyncValue.loading();
    try {
      print('🔍 ReviewsProvider: Loading reviews for customer: $customerId');
      final reviews = await AppApi.getReviewsForCustomer(customerId);
      print('🔍 ReviewsProvider: Loaded ${reviews.length} reviews for customer');
      state = AsyncValue.data(reviews);
    } catch (error, stackTrace) {
      print('❌ ReviewsProvider: Error loading reviews for customer: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Create a new review
  Future<String?> createReview({
    required String customerId,
    required String salonId,
    String? appointmentId,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      print('📝 ReviewsProvider: Creating review for salon: $salonId');
      final reviewId = await AppApi.createReview(
        customerId: customerId,
        salonId: salonId,
        appointmentId: appointmentId,
        rating: rating,
        comment: comment,
        images: images,
      );
      
      if (reviewId != null) {
        print('✅ ReviewsProvider: Review created successfully: $reviewId');
        // Refresh the current list
        await loadReviewsForSalon(salonId);
      }
      
      return reviewId;
    } catch (error) {
      print('❌ ReviewsProvider: Error creating review: $error');
      rethrow;
    }
  }

  // Update an existing review
  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      print('✏️ ReviewsProvider: Updating review: $reviewId');
      await AppApi.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
        images: images,
      );
      
      print('✅ ReviewsProvider: Review updated successfully');
      // Refresh the current list
      final currentState = state.value;
      if (currentState != null && currentState.isNotEmpty) {
        // Refresh based on the first review's salon ID
        await loadReviewsForSalon(currentState.first.salonId);
      }
    } catch (error) {
      print('❌ ReviewsProvider: Error updating review: $error');
      rethrow;
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      print('🗑️ ReviewsProvider: Deleting review: $reviewId');
      await AppApi.deleteReview(reviewId);
      
      print('✅ ReviewsProvider: Review deleted successfully');
      // Refresh the current list
      final currentState = state.value;
      if (currentState != null && currentState.isNotEmpty) {
        // Refresh based on the first review's salon ID
        await loadReviewsForSalon(currentState.first.salonId);
      }
    } catch (error) {
      print('❌ ReviewsProvider: Error deleting review: $error');
      rethrow;
    }
  }

  // Refresh current reviews
  Future<void> refreshReviews() async {
    final currentState = state.value;
    if (currentState != null && currentState.isNotEmpty) {
      await loadReviewsForSalon(currentState.first.salonId);
    }
  }
}

// Provider for reviews
final reviewsProvider = AsyncNotifierProvider<ReviewsNotifier, List<ReviewModel>>(() {
  return ReviewsNotifier();
});

// Provider for review stats
final reviewStatsProvider = FutureProvider.family<ReviewStats, String>((ref, salonId) async {
  return await AppApi.getReviewStats(salonId);
});

// Provider for checking if customer can review salon
final canReviewProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final customerId = params['customerId']!;
  final salonId = params['salonId']!;
  return await AppApi.canCustomerReviewSalon(customerId, salonId);
});
