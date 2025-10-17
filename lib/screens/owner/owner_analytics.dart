import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../providers/appointments_provider.dart';
import '../../models/appointment_model.dart';

class OwnerAnalyticsScreen extends ConsumerStatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  ConsumerState<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends ConsumerState<OwnerAnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedFilter = 'This Month';
  int _selectedTabIndex = 0;

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

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentsProvider.notifier).loadAppointments();
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
                  _buildFilterSection(),
                  _buildStatsCards(),
                  _buildTabSection(),
                  _buildTabContent(appointments),
                  _buildBestSellingServices(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                        ],
                      ),
                    ),
                  ),
                ),
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
            context.go('/owner-home');
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMauve),
        ),
      ),
      title: const Text(
        'Analytics',
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
            onPressed: _downloadReport,
            icon: const Icon(Icons.download, color: AppTheme.primaryMauve),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
                child: Row(
                  children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryMauve),
                    items: ['This Week', 'This Month', 'Last 3 Months', 'Custom Range'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(color: AppTheme.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFilter = newValue!;
                      });
                    },
                    ),
                  ),
                ),
              ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const Text(
              'Today\'s Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
                children: [
                Expanded(child: _buildStatCard('Today\'s Revenue', '\$245', Icons.attach_money, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Total Bookings', '47', Icons.calendar_today, Colors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Cancellations', '3', Icons.cancel, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Customer Growth', '+12%', Icons.trending_up, Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        child: TabBar(
          controller: TabController(length: 3, vsync: this, initialIndex: _selectedTabIndex),
          onTap: (index) => setState(() => _selectedTabIndex = index),
          indicator: BoxDecoration(
            color: AppTheme.primaryMauve,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<AppointmentModel> appointments) {
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

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
            if (_selectedTabIndex == 0) _buildRevenueChart(),
            if (_selectedTabIndex == 1) _buildServicePieChart(),
            if (_selectedTabIndex == 2) _buildCancellationChart(),
            const SizedBox(height: 20),
            ...filteredAppointments.map((appointment) => _buildAppointmentCard(appointment)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
              ),
            ],
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
            'Monthly Revenue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                              return Text(
                          months[value.toInt() % 6],
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                          '\$${value.toInt()}00',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: AppTheme.primaryMauve)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: AppTheme.primaryMauve)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 15, color: AppTheme.primaryMauve)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 18, color: AppTheme.primaryMauve)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 16, color: AppTheme.primaryMauve)]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 20, color: AppTheme.primaryMauve)]),
                ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildServicePieChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
            'Service Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                pieTouchData: PieTouchData(enabled: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: AppTheme.primaryMauve,
                    value: 40,
                    title: '40%',
                          radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.blue,
                    value: 30,
                    title: '30%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.green,
                    value: 20,
                    title: '20%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: 10,
                    title: '10%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              _buildLegendItem('Haircut', AppTheme.primaryMauve),
              _buildLegendItem('Beard', Colors.blue),
              _buildLegendItem('Facial', Colors.green),
              _buildLegendItem('Other', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
        children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCancellationChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
            'Cancellation Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Text(
                          days[value.toInt() % 7],
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                    spots: [
                      const FlSpot(0, 1),
                      const FlSpot(1, 2),
                      const FlSpot(2, 1),
                      const FlSpot(3, 3),
                      const FlSpot(4, 2),
                      const FlSpot(5, 1),
                      const FlSpot(6, 0),
                    ],
                          isCurved: true,
                    color: Colors.red,
                          barWidth: 3,
                    dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                      color: Colors.red.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
            children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryMauve.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: AppTheme.primaryMauve,
              size: 24,
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
                      '${appointment.startAt.day}/${appointment.startAt.month} at ${appointment.startAt.hour}:${appointment.startAt.minute.toString().padLeft(2, '0')}',
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
              Row(
                children: [
                  if (_selectedTabIndex == 0) ...[
                    _buildActionButton(Icons.check, Colors.green, () => _approveAppointment(appointment)),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.close, Colors.red, () => _rejectAppointment(appointment)),
                  ] else if (_selectedTabIndex == 1) ...[
                    _buildActionButton(Icons.refresh, Colors.blue, () => _rescheduleAppointment(appointment)),
                  ] else ...[
                    _buildActionButton(Icons.delete, Colors.red, () => _deleteAppointment(appointment)),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
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

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report download feature coming soon!'),
        backgroundColor: AppTheme.primaryMauve,
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

  void _rescheduleAppointment(AppointmentModel appointment) {
    // Navigate to booking screen for rescheduling
    context.go('/booking', extra: {
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

  Widget _buildBestSellingServices() {
    final bestSellingServices = [
      {
        'name': 'Classic Haircut',
        'earnings': 1250.0,
        'bookings': 50,
        'image': 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
      },
      {
        'name': 'Beard Trim',
        'earnings': 750.0,
        'bookings': 30,
        'image': 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400',
      },
      {
        'name': 'Hair Wash & Style',
        'earnings': 1050.0,
        'bookings': 30,
        'image': 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400',
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 3 Best-Selling Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...bestSellingServices.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(service['image'] as String),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
          Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMauve,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
            child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                service['name'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
                          const SizedBox(height: 8),
                          Row(
        children: [
                              Icon(Icons.attach_money, size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 4),
          Text(
                                '\$${(service['earnings'] as double).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade600),
                              const SizedBox(width: 4),
          Text(
                                '${service['bookings']} bookings',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
            ),
          ),
        ],
                ),
              );
            }),
          ],
        ),
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