import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/appointments_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/appointment_model.dart';
import '../../widgets/lottie_loader.dart';
import '../../widgets/review_input_widget.dart';

class CustomerAppointmentsScreen extends ConsumerStatefulWidget {
  const CustomerAppointmentsScreen({super.key});

  @override
  ConsumerState<CustomerAppointmentsScreen> createState() => _CustomerAppointmentsScreenState();
}

class _CustomerAppointmentsScreenState extends ConsumerState<CustomerAppointmentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _expandAnimationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _expandAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandAnimationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(appointmentsProvider.notifier).loadAppointmentsForCustomer(authState.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expandAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsState = ref.watch(appointmentsProvider);
    final appointments = appointmentsState.when(
      data: (data) => data,
      loading: () => <AppointmentModel>[],
      error: (_, __) => <AppointmentModel>[],
    );

    // Filter appointments by status
    final upcomingAppointments = appointments.where((apt) => 
        apt.status == AppointmentStatus.confirmed && 
        apt.startAt.isAfter(DateTime.now())).toList();
    
    final pastAppointments = appointments.where((apt) => 
        apt.status == AppointmentStatus.completed || 
        (apt.status == AppointmentStatus.confirmed && apt.startAt.isBefore(DateTime.now()))).toList();
    
    final cancelledAppointments = appointments.where((apt) => 
        apt.status == AppointmentStatus.cancelled).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundWhite, Color(0xFFF1F5F9)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'My Appointments',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Refresh appointments
                                  final authState = ref.read(authProvider);
                                  if (authState.user != null) {
                                    ref.read(appointmentsProvider.notifier).loadAppointmentsForCustomer(authState.user!.id);
                                  }
                                },
                                icon: const Icon(Icons.refresh, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Upcoming (${upcomingAppointments.length})'),
                  Tab(text: 'Past (${pastAppointments.length})'),
                  Tab(text: 'Cancelled (${cancelledAppointments.length})'),
                ],
              ),
            ),

            // Content
            SliverFillRemaining(
              child: appointmentsState.isLoading
                  ? const LottieLoader(
                      assetPath: 'assets/lottie/loading.json',
                      message: 'Loading your appointments...',
                    )
                  : appointmentsState.error != null
                      ? _buildErrorState(appointmentsState.error.toString())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAppointmentsList(upcomingAppointments, 'upcoming'),
                            _buildAppointmentsList(pastAppointments, 'past'),
                            _buildAppointmentsList(cancelledAppointments, 'cancelled'),
                          ],
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryMauve.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: 2,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.push('/customer-home');
                  break;
                case 1:
                  context.push('/customer-map');
                  break;
                case 2:
                  // Already on appointments
                  break;
                case 3:
                  context.push('/ai-hair-suggestions');
                  break;
                case 4:
                  context.push('/customer-profile');
                  break;
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome),
                label: 'AI Style',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading appointments',
            style: AppTheme.heading2.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final authState = ref.read(authProvider);
              if (authState.user != null) {
                ref.read(appointmentsProvider.notifier).loadAppointmentsForCustomer(authState.user!.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMauve,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments, String type) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment, type);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    String lottieAsset;
    
    switch (type) {
      case 'upcoming':
        message = 'No upcoming appointments';
        lottieAsset = 'assets/lottie/empty_calendar.json';
        break;
      case 'past':
        message = 'No past appointments';
        lottieAsset = 'assets/lottie/empty_history.json';
        break;
      case 'cancelled':
        message = 'No cancelled appointments';
        lottieAsset = 'assets/lottie/empty_cancelled.json';
        break;
      default:
        message = 'No appointments found';
        lottieAsset = 'assets/lottie/empty_calendar.json';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LottieLoader(
            assetPath: 'assets/lottie/empty_calendar.json',
            message: message,
          ),
          const SizedBox(height: 24),
          if (type == 'upcoming')
            ElevatedButton(
              onPressed: () => context.push('/customer-home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMauve,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Book an Appointment'),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    appointment.salonDetails?['imageUrl'] ?? 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=100',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMauve.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: AppTheme.primaryMauve,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.salonDetails?['name'] ?? 'Salon Name',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.serviceDetails?['name'] ?? 'Service Name',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${appointment.startAt.day}/${appointment.startAt.month}/${appointment.startAt.year} at ${appointment.startAt.hour.toString().padLeft(2, '0')}:${appointment.startAt.minute.toString().padLeft(2, '0')}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(appointment.status),
              ],
            ),

            const SizedBox(height: 16),

            // Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryMauve.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stylist: ${appointment.serviceDetails?['stylist'] ?? 'Not assigned'}',
                        style: AppTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        '\$${(appointment.price ?? 0).toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryMauve,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Duration: ${appointment.duration} minutes',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (type == 'upcoming') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rescheduleAppointment(appointment),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('Reschedule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryMauve,
                        side: const BorderSide(color: AppTheme.primaryMauve),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelAppointment(appointment),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (type == 'past') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rateAppointment(appointment),
                      icon: const Icon(Icons.star, size: 16),
                      label: const Text('Rate & Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentGold,
                        side: const BorderSide(color: AppTheme.accentGold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _bookAgain(appointment),
                      icon: const Icon(Icons.repeat, size: 16),
                      label: const Text('Book Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMauve,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _messageSalon(appointment),
                  icon: const Icon(Icons.message),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.infoColor.withOpacity(0.1),
                    foregroundColor: AppTheme.infoColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case AppointmentStatus.confirmed:
        color = AppTheme.successColor;
        text = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case AppointmentStatus.completed:
        color = AppTheme.infoColor;
        text = 'Completed';
        icon = Icons.done_all;
        break;
      case AppointmentStatus.cancelled:
        color = AppTheme.errorColor;
        text = 'Cancelled';
        icon = Icons.cancel;
        break;
      case AppointmentStatus.pending:
        color = AppTheme.warningColor;
        text = 'Pending';
        icon = Icons.schedule;
        break;
      case AppointmentStatus.inProgress:
        color = AppTheme.warningColor;
        text = 'In Progress';
        icon = Icons.hourglass_empty;
        break;
      default:
        color = AppTheme.textSecondary;
        text = 'Unknown';
        icon = Icons.help;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(AppointmentModel appointment) {
    // Navigate to booking screen with pre-filled data
    context.push('/booking', extra: {
      'salon': appointment.salonDetails,
      'service': appointment.serviceDetails,
      'isReschedule': true,
      'appointmentId': appointment.id,
    });
  }

  void _cancelAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(appointmentsProvider.notifier).cancelAppointment(
                appointment.id,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment cancelled successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _rateAppointment(AppointmentModel appointment) {
    // Navigate to rating screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Experience'),
        content: SizedBox(
          width: double.maxFinite,
          child: ReviewInputWidget(
            salonId: appointment.salonId,
            appointmentId: appointment.id,
            onReviewSubmitted: () {
              Navigator.of(context).pop();
              // Refresh the appointments to show updated review status
              ref.read(appointmentsProvider.notifier).loadAppointments();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your review!'),
                  backgroundColor: AppTheme.primaryMauve,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _bookAgain(AppointmentModel appointment) {
    // Navigate to booking screen with pre-filled data
    context.push('/booking', extra: {
      'salon': appointment.salonDetails,
      'service': appointment.serviceDetails,
    });
  }

  void _messageSalon(AppointmentModel appointment) {
    // Navigate to chat screen
    context.push('/customer-chat', extra: {
      'salonId': appointment.salonId,
      'salonName': appointment.salonDetails?['name'] ?? 'Salon',
    });
  }
}