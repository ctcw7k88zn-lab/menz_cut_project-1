import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';
import '../models/salon_model.dart';
import '../services/supabase_service.dart';

// Date range model
class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  DateRange({
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  static DateRange today() {
    final now = DateTime.now();
    return DateRange(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      label: 'Today',
    );
  }

  static DateRange thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateRange(
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      label: 'This Week',
    );
  }

  static DateRange thisMonth() {
    final now = DateTime.now();
    return DateRange(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      label: 'This Month',
    );
  }

  static DateRange lastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    return DateRange(
      startDate: lastMonth,
      endDate: DateTime(now.year, now.month, 0, 23, 59, 59),
      label: 'Last Month',
    );
  }

  static DateRange custom(DateTime start, DateTime end) {
    return DateRange(
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day, 23, 59, 59),
      label: 'Custom Range',
    );
  }
}

// Analytics data model
class AnalyticsData {
  final double periodRevenue;
  final int totalBookings;
  final int cancellations;
  final double customerGrowth;
  final List<AppointmentModel> periodAppointments;
  final List<AppointmentModel> upcomingAppointments;
  final List<AppointmentModel> completedAppointments;
  final List<AppointmentModel> cancelledAppointments;
  final List<Map<String, dynamic>> monthlyRevenue;
  final List<Map<String, dynamic>> serviceDistribution;
  final List<Map<String, dynamic>> topServices;
  final DateRange dateRange;

  AnalyticsData({
    required this.periodRevenue,
    required this.totalBookings,
    required this.cancellations,
    required this.customerGrowth,
    required this.periodAppointments,
    required this.upcomingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.monthlyRevenue,
    required this.serviceDistribution,
    required this.topServices,
    required this.dateRange,
  });
}

// Analytics provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsData>>((ref) {
  return AnalyticsNotifier();
});

class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsData>> {
  DateRange _currentDateRange = DateRange.thisMonth();
  
  AnalyticsNotifier() : super(const AsyncValue.loading()) {
    loadAnalytics();
  }

  DateRange get currentDateRange => _currentDateRange;

  Future<void> loadAnalytics([DateRange? dateRange]) async {
    try {
      state = const AsyncValue.loading();
      
      // Update current date range if provided
      if (dateRange != null) {
        _currentDateRange = dateRange;
      }
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get or create salon for current user
      SalonModel? salon = await SupabaseService.getSalonByOwnerId(user.id);
      if (salon == null) {
        print('📊 Analytics: No salon found for user, creating one...');
        // Create a salon for the owner if it doesn't exist
        final userName = user.userMetadata?['full_name'] ?? 
                        user.email?.split('@')[0] ?? 
                        'User';
        salon = await SupabaseService.createSalonForOwner(
          user.id,
          name: "$userName's Salon",
          description: 'Professional salon services',
          address: '123 Main St', // Default address
          phone: user.userMetadata?['phone'] ?? '',
          email: user.email ?? '',
        );
        print('📊 Analytics: Created new salon: ${salon.id}');
      }

      // Get all appointments for this salon
      final allAppointments = await SupabaseService.getAppointmentsBySalon(salon.id);
      
      // Get services for this salon
      final services = await SupabaseService.getServicesBySalon(salon.id);

      // Calculate analytics data for the selected date range
      final analyticsData = await _calculateAnalyticsData(allAppointments, services, _currentDateRange);
      
      state = AsyncValue.data(analyticsData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<AnalyticsData> _calculateAnalyticsData(
    List<AppointmentModel> appointments,
    List<ServiceModel> services,
    DateRange dateRange,
  ) async {
    // Filter appointments for the selected date range
    final periodAppointments = appointments.where((apt) {
      final aptDate = DateTime(apt.startAt.year, apt.startAt.month, apt.startAt.day);
      final startDate = DateTime(dateRange.startDate.year, dateRange.startDate.month, dateRange.startDate.day);
      final endDate = DateTime(dateRange.endDate.year, dateRange.endDate.month, dateRange.endDate.day);
      
      return (aptDate.isAtSameMomentAs(startDate) || aptDate.isAfter(startDate)) &&
             (aptDate.isAtSameMomentAs(endDate) || aptDate.isBefore(endDate));
    }).toList();

    print('📊 Analytics Debug:');
    print('   Date Range: ${dateRange.startDate} to ${dateRange.endDate}');
    print('   Total appointments: ${appointments.length}');
    print('   Period appointments: ${periodAppointments.length}');
    print('   Period appointments details:');
    for (final apt in periodAppointments) {
      print('     - ${apt.startAt}: ${apt.status} - \$${apt.totalAmount}');
    }
    
    if (periodAppointments.isEmpty) {
      print('⚠️  No appointments found in selected date range!');
      print('   Available appointment dates:');
      for (final apt in appointments) {
        print('     - ${apt.startAt}');
      }
    }

    // Calculate period revenue
    final periodRevenue = periodAppointments
        .where((apt) => apt.status == AppointmentStatus.completed)
        .fold<double>(0.0, (sum, apt) => sum + apt.totalAmount);

    // Total bookings in period
    final totalBookings = periodAppointments.length;

    // Cancellations in period
    final cancellations = periodAppointments
        .where((apt) => apt.status == AppointmentStatus.cancelled)
        .length;

    // Customer growth (compare with previous period of same length)
    final periodLength = dateRange.endDate.difference(dateRange.startDate).inDays + 1;
    final previousPeriodStart = dateRange.startDate.subtract(Duration(days: periodLength));
    final previousPeriodEnd = dateRange.startDate.subtract(const Duration(days: 1));
    
    final previousPeriodAppointments = appointments.where((apt) {
      final aptDate = DateTime(apt.startAt.year, apt.startAt.month, apt.startAt.day);
      final startDate = DateTime(previousPeriodStart.year, previousPeriodStart.month, previousPeriodStart.day);
      final endDate = DateTime(previousPeriodEnd.year, previousPeriodEnd.month, previousPeriodEnd.day);
      
      return (aptDate.isAtSameMomentAs(startDate) || aptDate.isAfter(startDate)) &&
             (aptDate.isAtSameMomentAs(endDate) || aptDate.isBefore(endDate));
    }).length;

    final customerGrowth = previousPeriodAppointments > 0 
        ? ((totalBookings - previousPeriodAppointments) / previousPeriodAppointments) * 100
        : 0.0;

    // Filter appointments by status (from period appointments)
    final upcomingAppointments = periodAppointments.where((apt) => 
        apt.status == AppointmentStatus.pending || apt.status == AppointmentStatus.confirmed
    ).toList();

    final completedAppointments = periodAppointments.where((apt) => 
        apt.status == AppointmentStatus.completed
    ).toList();

    final cancelledAppointments = periodAppointments.where((apt) => 
        apt.status == AppointmentStatus.cancelled
    ).toList();

    // Monthly revenue data (last 6 months)
    final monthlyRevenue = _calculateMonthlyRevenue(appointments);

    // Service distribution (based on period appointments)
    final serviceDistribution = _calculateServiceDistribution(periodAppointments, services);

    // Top services (based on period appointments)
    final topServices = _calculateTopServices(periodAppointments, services);

    return AnalyticsData(
      periodRevenue: periodRevenue,
      totalBookings: totalBookings,
      cancellations: cancellations,
      customerGrowth: customerGrowth,
      periodAppointments: periodAppointments,
      upcomingAppointments: upcomingAppointments,
      completedAppointments: completedAppointments,
      cancelledAppointments: cancelledAppointments,
      monthlyRevenue: monthlyRevenue,
      serviceDistribution: serviceDistribution,
      topServices: topServices,
      dateRange: dateRange,
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

  // Change date range methods
  Future<void> setDateRange(DateRange dateRange) async {
    await loadAnalytics(dateRange);
  }

  Future<void> setToday() async {
    await setDateRange(DateRange.today());
  }

  Future<void> setThisWeek() async {
    await setDateRange(DateRange.thisWeek());
  }

  Future<void> setThisMonth() async {
    await setDateRange(DateRange.thisMonth());
  }

  Future<void> setLastMonth() async {
    await setDateRange(DateRange.lastMonth());
  }

  Future<void> setCustomRange(DateTime startDate, DateTime endDate) async {
    await setDateRange(DateRange.custom(startDate, endDate));
  }

  // Refresh analytics data
  Future<void> refresh() async {
    await loadAnalytics();
  }
}
