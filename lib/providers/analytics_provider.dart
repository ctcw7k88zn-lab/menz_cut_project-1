import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';
import '../services/supabase_service.dart';

// Analytics data model
class AnalyticsData {
  final double todayRevenue;
  final int totalBookings;
  final int cancellations;
  final double customerGrowth;
  final List<AppointmentModel> todayAppointments;
  final List<AppointmentModel> upcomingAppointments;
  final List<AppointmentModel> completedAppointments;
  final List<AppointmentModel> cancelledAppointments;
  final List<Map<String, dynamic>> monthlyRevenue;
  final List<Map<String, dynamic>> serviceDistribution;
  final List<Map<String, dynamic>> topServices;

  AnalyticsData({
    required this.todayRevenue,
    required this.totalBookings,
    required this.cancellations,
    required this.customerGrowth,
    required this.todayAppointments,
    required this.upcomingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.monthlyRevenue,
    required this.serviceDistribution,
    required this.topServices,
  });
}

// Analytics provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsData>>((ref) {
  return AnalyticsNotifier();
});

class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsData>> {
  AnalyticsNotifier() : super(const AsyncValue.loading()) {
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
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

      // Get all appointments for this salon
      final allAppointments = await SupabaseService.getAppointmentsBySalon(salon.id);
      
      // Get services for this salon
      final services = await SupabaseService.getServicesBySalon(salon.id);

      // Calculate analytics data
      final analyticsData = await _calculateAnalyticsData(allAppointments, services);
      
      state = AsyncValue.data(analyticsData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<AnalyticsData> _calculateAnalyticsData(
    List<AppointmentModel> appointments,
    List<ServiceModel> services,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    // Today's appointments
    final todayAppointments = appointments.where((apt) {
      final aptDate = DateTime(apt.startAt.year, apt.startAt.month, apt.startAt.day);
      return aptDate.isAtSameMomentAs(today);
    }).toList();

    // Calculate today's revenue
    final todayRevenue = todayAppointments
        .where((apt) => apt.status == AppointmentStatus.completed)
        .fold<double>(0.0, (sum, apt) => sum + apt.totalAmount);

    // Total bookings today
    final totalBookings = todayAppointments.length;

    // Cancellations today
    final cancellations = todayAppointments
        .where((apt) => apt.status == AppointmentStatus.cancelled)
        .length;

    // Customer growth (compare this month vs last month)
    final thisMonthAppointments = appointments.where((apt) {
      return apt.startAt.isAfter(thisMonth) && apt.startAt.isBefore(DateTime(now.year, now.month + 1, 1));
    }).length;

    final lastMonthAppointments = appointments.where((apt) {
      return apt.startAt.isAfter(lastMonth) && apt.startAt.isBefore(thisMonth);
    }).length;

    final customerGrowth = lastMonthAppointments > 0 
        ? ((thisMonthAppointments - lastMonthAppointments) / lastMonthAppointments) * 100
        : 0.0;

    // Filter appointments by status
    final upcomingAppointments = appointments.where((apt) => 
        apt.status == AppointmentStatus.pending || apt.status == AppointmentStatus.confirmed
    ).toList();

    final completedAppointments = appointments.where((apt) => 
        apt.status == AppointmentStatus.completed
    ).toList();

    final cancelledAppointments = appointments.where((apt) => 
        apt.status == AppointmentStatus.cancelled
    ).toList();

    // Monthly revenue data (last 6 months)
    final monthlyRevenue = _calculateMonthlyRevenue(appointments);

    // Service distribution
    final serviceDistribution = _calculateServiceDistribution(appointments, services);

    // Top services
    final topServices = _calculateTopServices(appointments, services);

    return AnalyticsData(
      todayRevenue: todayRevenue,
      totalBookings: totalBookings,
      cancellations: cancellations,
      customerGrowth: customerGrowth,
      todayAppointments: todayAppointments,
      upcomingAppointments: upcomingAppointments,
      completedAppointments: completedAppointments,
      cancelledAppointments: cancelledAppointments,
      monthlyRevenue: monthlyRevenue,
      serviceDistribution: serviceDistribution,
      topServices: topServices,
    );
  }

  List<Map<String, dynamic>> _calculateMonthlyRevenue(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final monthlyData = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      
      final monthAppointments = appointments.where((apt) {
        return apt.startAt.isAfter(month) && 
               apt.startAt.isBefore(nextMonth) &&
               apt.status == AppointmentStatus.completed;
      }).toList();

      final revenue = monthAppointments.fold<double>(0.0, (sum, apt) => sum + apt.totalAmount);
      
      monthlyData.add({
        'month': _getMonthName(month.month),
        'revenue': revenue,
        'appointments': monthAppointments.length,
      });
    }

    return monthlyData;
  }

  List<Map<String, dynamic>> _calculateServiceDistribution(
    List<AppointmentModel> appointments,
    List<ServiceModel> services,
  ) {
    final serviceCounts = <String, int>{};
    final serviceRevenue = <String, double>{};

    for (final appointment in appointments.where((apt) => 
        apt.status == AppointmentStatus.completed)) {
      final serviceName = appointment.serviceDetails?['name'] ?? 'Unknown Service';
      serviceCounts[serviceName] = (serviceCounts[serviceName] ?? 0) + 1;
      serviceRevenue[serviceName] = (serviceRevenue[serviceName] ?? 0.0) + appointment.totalAmount;
    }

    final totalAppointments = appointments.where((apt) => 
        apt.status == AppointmentStatus.completed).length;

    return serviceCounts.entries.map((entry) {
      final percentage = totalAppointments > 0 ? (entry.value / totalAppointments) * 100 : 0.0;
      return {
        'name': entry.key,
        'count': entry.value,
        'percentage': percentage,
        'revenue': serviceRevenue[entry.key] ?? 0.0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _calculateTopServices(
    List<AppointmentModel> appointments,
    List<ServiceModel> services,
  ) {
    final serviceStats = <String, Map<String, dynamic>>{};

    for (final appointment in appointments.where((apt) => 
        apt.status == AppointmentStatus.completed)) {
      final serviceName = appointment.serviceDetails?['name'] ?? 'Unknown Service';
      
      if (!serviceStats.containsKey(serviceName)) {
        serviceStats[serviceName] = {
          'name': serviceName,
          'bookings': 0,
          'revenue': 0.0,
        };
      }
      
      serviceStats[serviceName]!['bookings'] = 
          (serviceStats[serviceName]!['bookings'] as int) + 1;
      serviceStats[serviceName]!['revenue'] = 
          (serviceStats[serviceName]!['revenue'] as double) + appointment.totalAmount;
    }

    return serviceStats.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Refresh analytics data
  Future<void> refresh() async {
    await loadAnalytics();
  }
}
