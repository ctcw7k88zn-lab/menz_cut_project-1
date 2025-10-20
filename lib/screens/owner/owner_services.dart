import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/appointments_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/appointment_model.dart';
import '../../services/app_api.dart';

class OwnerServicesScreen extends ConsumerStatefulWidget {
  const OwnerServicesScreen({super.key});

  @override
  ConsumerState<OwnerServicesScreen> createState() => _OwnerServicesScreenState();
}

class _OwnerServicesScreenState extends ConsumerState<OwnerServicesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Upcoming', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  void _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get the authenticated salon owner
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        // Get the salon ID for this owner
        final salon = await AppApi.getSalonByOwnerId(authState.user!.id);
        if (salon != null) {
          ref.read(appointmentsProvider.notifier).loadAppointmentsForSalon(salon.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundWhite, Color(0xFFF8F4FF)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
                  _buildAppBar(),
                  _buildTabSection(),
                  _buildAppointmentsList(appointments),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createManualAppointment,
        backgroundColor: AppTheme.primaryMauve,
                                icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Manual Entry', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
                          ),
                        ],
                      ),
        child: IconButton(
          onPressed: () {
            print('Back button pressed - navigating to home tab');
            // Navigate to owner-home which will show the dashboard with Home tab (index 0)
            context.push('/owner-home');
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMauve),
        ),
      ),
      title: const Text(
        'Appointments',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.filter_list, color: AppTheme.primaryMauve),
              ),
            ),
          ],
    );
  }

  Widget _buildTabSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: _tabs.asMap().entries.map((entry) {
            int index = entry.key;
            String tab = entry.value;
            bool isSelected = _selectedTabIndex == index;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryMauve : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tab,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
    List<AppointmentModel> filteredAppointments = [];
    
    switch (_selectedTabIndex) {
      case 0:
        filteredAppointments = appointments.where((apt) => 
          apt.status == AppointmentStatus.pending || apt.status == AppointmentStatus.confirmed).toList();
        break;
      case 1:
        filteredAppointments = appointments.where((apt) => 
          apt.status == AppointmentStatus.completed).toList();
        break;
      case 2:
        filteredAppointments = appointments.where((apt) => 
          apt.status == AppointmentStatus.cancelled).toList();
        break;
    }

    if (filteredAppointments.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
              Icon(
                Icons.calendar_today_outlined,
            size: 64,
                color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
                'No ${_tabs[_selectedTabIndex].toLowerCase()} appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
                'Your ${_tabs[_selectedTabIndex].toLowerCase()} appointments will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ),
            ],
          ),
      ),
    );
  }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final appointment = filteredAppointments[index];
          return _buildAppointmentCard(appointment, index);
        },
        childCount: filteredAppointments.length,
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Dismissible(
        key: Key(appointment.id),
        direction: _selectedTabIndex == 0 ? DismissDirection.horizontal : DismissDirection.endToStart,
        background: _selectedTabIndex == 0 ? _buildSwipeBackground(true) : _buildSwipeBackground(false),
        secondaryBackground: _buildSwipeBackground(false),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd && _selectedTabIndex == 0) {
            _approveAppointment(appointment);
            return false;
          } else if (direction == DismissDirection.endToStart) {
            if (_selectedTabIndex == 0) {
              _rejectAppointment(appointment);
            } else {
              _deleteAppointment(appointment);
            }
            return false;
          }
          return false;
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        child: Column(
          children: [
            Row(
              children: [
                  Container(
                    width: 50,
                    height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMauve.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: appointment.customerDetails?['imageUrl'] != null
                          ? Image.network(
                              appointment.customerDetails!['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                          color: AppTheme.primaryMauve,
                                  size: 24,
                      );
                    },
                            )
                          : const Icon(
                              Icons.person,
                              color: AppTheme.primaryMauve,
                              size: 24,
                  ),
                ),
                  ),
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          appointment.customerDetails?['name'] ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          appointment.serviceDetails?['name'] ?? 'Service',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                      Row(
                        children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${appointment.startAt.day}/${appointment.startAt.month}/${appointment.startAt.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 8),
                            Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                              '${appointment.startAt.hour}:${appointment.startAt.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(appointment.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appointment.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(appointment.status),
                          ),
                      ),
                    ),
                    const SizedBox(height: 8),
                      Text(
                        '\$${appointment.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: _buildActionButtons(appointment),
              ),
            ],
                            ),
                          ),
                        ),
    );
  }

  Widget _buildSwipeBackground(bool isApprove) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
        color: isApprove ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: isApprove ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            isApprove ? Icons.check : Icons.close,
            color: Colors.white,
            size: 24,
                            ),
                          ),
                        ),
    );
  }

  List<Widget> _buildActionButtons(AppointmentModel appointment) {
    List<Widget> buttons = [];

    // Show different buttons based on appointment status, not just tab index
    switch (appointment.status) {
      case AppointmentStatus.pending:
        buttons = [
          Expanded(
            child: _buildActionButton(
              'Chat',
              Icons.chat_bubble_outline,
              AppTheme.primaryMauve,
              () => _chatWithCustomer(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Approve',
              Icons.check,
              Colors.green,
              () => _approveAppointment(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Reject',
              Icons.close,
              Colors.red,
              () => _rejectAppointment(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Reschedule',
              Icons.schedule,
              Colors.blue,
              () => _rescheduleAppointment(appointment),
            ),
          ),
        ];
        break;
      case AppointmentStatus.confirmed:
        buttons = [
          Expanded(
            child: _buildActionButton(
              'Chat',
              Icons.chat_bubble_outline,
              AppTheme.primaryMauve,
              () => _chatWithCustomer(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Complete',
              Icons.check_circle,
              Colors.green,
              () => _completeAppointment(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Cancel',
              Icons.cancel,
              Colors.red,
              () => _cancelAppointment(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Reschedule',
              Icons.schedule,
              Colors.blue,
              () => _rescheduleAppointment(appointment),
            ),
          ),
        ];
        break;
      case AppointmentStatus.completed:
        buttons = [
          Expanded(
            child: _buildActionButton(
              'Chat',
              Icons.chat_bubble_outline,
              AppTheme.primaryMauve,
              () => _chatWithCustomer(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'View Details',
              Icons.visibility,
              Colors.blue,
              () => _viewAppointmentDetails(appointment),
            ),
          ),
        ];
        break;
      case AppointmentStatus.cancelled:
        buttons = [
          Expanded(
            child: _buildActionButton(
              'Chat',
              Icons.chat_bubble_outline,
              AppTheme.primaryMauve,
              () => _chatWithCustomer(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'View Details',
              Icons.visibility,
              Colors.blue,
              () => _viewAppointmentDetails(appointment),
            ),
          ),
        ];
        break;
      default:
        buttons = [
          Expanded(
            child: _buildActionButton(
              'Chat',
              Icons.chat_bubble_outline,
              AppTheme.primaryMauve,
              () => _chatWithCustomer(appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'View Details',
              Icons.visibility,
              Colors.blue,
              () => _viewAppointmentDetails(appointment),
            ),
          ),
        ];
    }

    return buttons;
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // If width is very tight, show icon only to prevent overflow
            if (constraints.maxWidth < 72) {
              return Center(child: Icon(icon, color: color, size: 16));
            }
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.purple;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  void _createManualAppointment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateAppointmentSheet(),
    );
  }

  Widget _buildCreateAppointmentSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create New Appointment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Customer Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
                    ),
                    const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Service',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Date & Time',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment created successfully!'),
                    backgroundColor: AppTheme.primaryMauve,
                  ),
                );
              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMauve,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                        ),
                          ),
              child: const Text(
                'Create Appointment',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filter Appointments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // Add filter options here
            const Text('Filter options coming soon!'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _approveAppointment(AppointmentModel appointment) async {
    try {
      await ref.read(appointmentsProvider.notifier).updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.confirmed,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved appointment for ${appointment.customerDetails?['name'] ?? 'Customer'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectAppointment(AppointmentModel appointment) async {
    try {
      await ref.read(appointmentsProvider.notifier).updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.cancelled,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejected appointment for ${appointment.customerDetails?['name'] ?? 'Customer'}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeAppointment(AppointmentModel appointment) async {
    try {
      await ref.read(appointmentsProvider.notifier).updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.completed,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completed appointment for ${appointment.customerDetails?['name'] ?? 'Customer'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelAppointment(AppointmentModel appointment) async {
    try {
      await ref.read(appointmentsProvider.notifier).updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.cancelled,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cancelled appointment for ${appointment.customerDetails?['name'] ?? 'Customer'}'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rescheduleAppointment(AppointmentModel appointment) {
    // Navigate to booking screen for rescheduling
    context.push('/booking', extra: {
      'salon': appointment.salonDetails,
      'service': appointment.serviceDetails,
      'isReschedule': true,
      'appointmentId': appointment.id,
    });
  }

  void _deleteAppointment(AppointmentModel appointment) async {
    try {
      await ref.read(appointmentsProvider.notifier).deleteAppointment(appointment.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted appointment for ${appointment.customerDetails?['name'] ?? 'Customer'}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _chatWithCustomer(AppointmentModel appointment) async {
    try {
      print('🔍 Starting chat with customer for appointment: ${appointment.id}');
      
      final authState = ref.read(authProvider);
      final ownerId = authState.user?.id;
      if (ownerId == null) {
        print('❌ Owner not logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ensure we have a valid customer id
      final customerId = appointment.customerId;
      if (customerId.isEmpty) {
        print('❌ Customer ID is empty for appointment: ${appointment.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer not found for this appointment'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('🔍 Creating/getting thread between owner: $ownerId and customer: $customerId');
      await AppApi.getOrCreateThread(ownerId, customerId);

      print('🔍 Navigating to owner-chat with customer info');
      // Navigate to owner chat screen with customer information
      if (mounted) {
        context.push('/owner-chat', extra: {
          'customerId': customerId,
          'customerName': appointment.customerDetails?['name'] ?? 'Customer',
          'customerImage': appointment.customerDetails?['imageUrl'],
        });
      }
    } catch (e) {
      print('❌ Error in _chatWithCustomer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewAppointmentDetails(AppointmentModel appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View details for ${appointment.customerDetails?['name'] ?? 'Customer'}'),
        backgroundColor: Colors.blue,
      ),
    );
  }


  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppTheme.primaryMauve,
      ),
    );
  }
}