import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';

// Home dashboard data model
class HomeDashboardData {
  final String salonName;
  final int todayAppointments;
  final double todayEarnings;
  final int customersServed;
  final int totalServices;
  final double averageRating;
  final int unreadNotifications;
  final List<AppointmentModel> recentAppointments;
  final List<ServiceModel> services;
  final List<ReviewModel> recentReviews;
  final List<NotificationModel> notifications;
  final Map<String, int> weeklyStats;

  HomeDashboardData({
    required this.salonName,
    required this.todayAppointments,
    required this.todayEarnings,
    required this.customersServed,
    required this.totalServices,
    required this.averageRating,
    required this.unreadNotifications,
    required this.recentAppointments,
    required this.services,
    required this.recentReviews,
    required this.notifications,
    required this.weeklyStats,
  });
}

// Home dashboard provider
final homeDashboardProvider = StateNotifierProvider<HomeDashboardNotifier, AsyncValue<HomeDashboardData>>((ref) {
  return HomeDashboardNotifier();
});

class HomeDashboardNotifier extends StateNotifier<AsyncValue<HomeDashboardData>> {
  HomeDashboardNotifier() : super(const AsyncValue.loading()) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      state = const AsyncValue.loading();
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get salon for current user
      final salon = await SupabaseService.getSalonByOwnerId(user.id);
      if (salon == null) {
        throw Exception('No salon found for user');
      }

      print('🏠 Home Dashboard: Loading data for salon ${salon.name}');

      // Load all data in parallel
      final results = await Future.wait([
        SupabaseService.getAppointmentsBySalon(salon.id),
        SupabaseService.getServicesBySalon(salon.id),
        SupabaseService.getReviewsForSalon(salon.id),
        SupabaseService.getNotificationsByUser(user.id),
      ]);

      final appointments = results[0] as List<AppointmentModel>;
      final services = results[1] as List<ServiceModel>;
      final reviews = results[2] as List<ReviewModel>;
      final notifications = results[3] as List<NotificationModel>;

      print('🏠 Home Dashboard: Loaded ${appointments.length} appointments, ${services.length} services, ${reviews.length} reviews, ${notifications.length} notifications');

      // Calculate all-time data instead of just today's
      final allTimeAppointments = appointments.length;
      final allTimeEarnings = appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .fold<double>(0.0, (sum, apt) => sum + apt.totalAmount);
      final allTimeCustomersServed = appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .length;

      // Calculate average rating
      final averageRating = reviews.isNotEmpty 
          ? reviews.fold<double>(0.0, (sum, review) => sum + review.rating) / reviews.length
          : 0.0;

      // Get unread notifications
      final unreadNotifications = notifications.where((n) => !n.isRead).length;

      // Get recent appointments (last 5)
      final recentAppointments = appointments
          .where((apt) => apt.startAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
          .toList()
        ..sort((a, b) => b.startAt.compareTo(a.startAt));

      // Get recent reviews (last 3)
      final recentReviews = reviews
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Calculate weekly stats for chart
      final weeklyStats = _calculateWeeklyStats(appointments);

      final dashboardData = HomeDashboardData(
        salonName: salon.name,
        todayAppointments: allTimeAppointments,
        todayEarnings: allTimeEarnings,
        customersServed: allTimeCustomersServed,
        totalServices: services.length,
        averageRating: averageRating,
        unreadNotifications: unreadNotifications,
        recentAppointments: recentAppointments.take(5).toList(),
        services: services,
        recentReviews: recentReviews.take(3).toList(),
        notifications: notifications,
        weeklyStats: weeklyStats,
      );

      print('🏠 Home Dashboard: All-Time - $allTimeAppointments appointments, \$${allTimeEarnings.toStringAsFixed(0)} earnings, $allTimeCustomersServed customers served');
      
      state = AsyncValue.data(dashboardData);
    } catch (e) {
      print('🏠 Home Dashboard Error: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Map<String, int> _calculateWeeklyStats(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final weeklyStats = <String, int>{};
    
    // Get last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final dayAppointments = appointments.where((apt) {
        return apt.startAt.isAfter(dayStart) && apt.startAt.isBefore(dayEnd);
      }).length;
      
      weeklyStats[dayName] = dayAppointments;
    }
    
    return weeklyStats;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await SupabaseService.markNotificationAsRead(notificationId);
      await loadDashboardData(); // Refresh to update unread count
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
