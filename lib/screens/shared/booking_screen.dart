import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/salon_model.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointments_provider.dart';
import '../../providers/auth_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final SalonModel salon;
  final ServiceModel? service;

  const BookingScreen({
    super.key,
    required this.salon,
    this.service,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  
  int _currentStep = 0;
  ServiceModel? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedStaff;
  String? _promoCode;
  String _notes = '';

  // Mock available times
  final List<TimeOfDay> _availableTimes = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
  ];

  // Mock staff members
  final List<String> _staffMembers = [
    'Sarah Johnson',
    'Michael Chen',
    'Emma Davis',
    'David Kim',
  ];

  // Mock services
  final List<ServiceModel> _services = [
    ServiceModel(
      id: 'service_1',
      salonId: 'salon_1',
      name: 'Premium Haircut & Styling',
      description: 'Professional haircut with personalized styling consultation and blow-dry finish.',
      category: 'Haircut',
      price: 85.00,
      durationMinutes: 60,
      imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ServiceModel(
      id: 'service_2',
      salonId: 'salon_1',
      name: 'Full Color Treatment',
      description: 'Complete hair coloring service with premium products and color consultation.',
      category: 'Coloring',
      price: 150.00,
      durationMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Set initial service if provided
    if (widget.service != null) {
      _selectedService = widget.service;
      _currentStep = 1; // Skip service selection
      // Navigate to the date/time selection page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
    
    // Load appointments to check availability
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentsProvider.notifier).loadAppointments();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              expandedHeight: AppTheme.isMobile(context) ? 140 : 180, // Adequate height to prevent overlap
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryMauve,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0), // Adequate padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16), // Adequate spacing
                          Center(
                            child: Text(
                              'Book Appointment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16), // Adequate spacing
                          Center(
                            child: _buildProgressIndicator(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverFillRemaining(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildServiceSelectionStep(),
                  _buildDateTimeSelectionStep(),
                  _buildConfirmationStep(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressDot(0, 'Service'),
        _buildProgressLine(),
        _buildProgressDot(1, 'Date & Time'),
        _buildProgressLine(),
        _buildProgressDot(2, 'Confirm'),
      ],
    );
  }

  Widget _buildProgressDot(int step, String label) {
    final isActive = step <= _currentStep;
    final isCompleted = step < _currentStep;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: AppTheme.primaryMauve, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryMauve : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildServiceSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Service',
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the service you\'d like to book',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.builder(
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                final isSelected = _selectedService?.id == service.id;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedService = service;
                        // Refresh availability when service changes
                        ref.read(appointmentsProvider.notifier).loadAppointments();
                      });
                    },
                    child: AppTheme.glassCard(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryMauve.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryMauve : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                service.imageUrl ?? '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryMauve.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.business_center,
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
                                    service.name,
                                    style: AppTheme.heading3.copyWith(
                                      color: isSelected ? AppTheme.primaryMauve : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service.description,
                                    style: AppTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryMauve.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          service.category,
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.primaryMauve,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${service.durationMinutes} min',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '\$${service.price.toStringAsFixed(0)}',
                                  style: AppTheme.heading3.copyWith(
                                    color: AppTheme.primaryMauve,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppTheme.accentGold,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.5',
                                      style: AppTheme.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0), // Maximum bottom padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date & Time',
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred date and time slot',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Date Selection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMauve.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppTheme.primaryMauve,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14, // Show 2 weeks
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = _selectedDate?.day == date.day && _selectedDate?.month == date.month;
                      final isToday = index == 0;
                      final isUnavailable = _isDateUnavailable(date);
                      
                      return GestureDetector(
                        onTap: isUnavailable ? null : () {
                          setState(() {
                            _selectedDate = date;
                            _selectedTime = null; // Reset time when date changes
                          });
                        },
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Text(
                                _getDayName(date.weekday),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnavailable ? Colors.grey[400] : AppTheme.textSecondary,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isUnavailable 
                                      ? Colors.grey[200]
                                      : isSelected 
                                          ? AppTheme.primaryMauve 
                                          : isToday 
                                              ? AppTheme.primaryMauve.withOpacity(0.1)
                                              : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected 
                                      ? Border.all(color: AppTheme.primaryMauve, width: 2)
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        date.day.toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isUnavailable 
                                              ? Colors.grey[400]
                                              : isSelected 
                                                  ? Colors.white 
                                                  : isToday 
                                                      ? AppTheme.primaryMauve
                                                      : AppTheme.textSecondary,
                                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isUnavailable)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: Colors.red.withOpacity(0.1),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.month}/${date.day}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUnavailable ? Colors.grey[400] : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Time Selection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMauve.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: AppTheme.primaryMauve,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_selectedDate == null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const Center(
                      child: Text(
                        'Please select a date first',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _availableTimes.length,
                    itemBuilder: (context, index) {
                      final time = _availableTimes[index];
                      final isSelected = _selectedTime?.hour == time.hour && _selectedTime?.minute == time.minute;
                      final isUnavailable = _isTimeSlotUnavailable(_selectedDate!, time);
                      
                      return GestureDetector(
                        onTap: isUnavailable ? null : () {
                          setState(() {
                            _selectedTime = time;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isUnavailable 
                                ? Colors.grey[200]
                                : isSelected 
                                    ? AppTheme.primaryMauve 
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUnavailable 
                                  ? Colors.grey[300]!
                                  : isSelected 
                                      ? AppTheme.primaryMauve 
                                      : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  time.format(context),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isUnavailable 
                                        ? Colors.grey[400]
                                        : isSelected 
                                            ? Colors.white 
                                            : AppTheme.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isUnavailable)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.red.withOpacity(0.1),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Reduced spacing

          // Staff Selection
          AppTheme.glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Stylist',
                  style: AppTheme.heading3,
                ),
                const SizedBox(height: 16),
                ..._staffMembers.map((staff) {
                  final isSelected = _selectedStaff == staff;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStaff = staff;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryMauve.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryMauve : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryMauve.withOpacity(0.1),
                            child: Text(
                              staff[0],
                              style: const TextStyle(
                                color: AppTheme.primaryMauve,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              staff,
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppTheme.primaryMauve : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryMauve,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    if (_selectedService == null || _selectedDate == null || _selectedTime == null) {
      return const Center(
        child: Text('Please complete all previous steps'),
      );
    }

    final totalPrice = _selectedService!.price;
    final discount = _promoCode == 'SAVE10' ? totalPrice * 0.1 : 0.0;
    final finalPrice = totalPrice - discount;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Booking',
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Review your appointment details',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Appointment Summary
          AppTheme.glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment Summary',
                  style: AppTheme.heading3,
                ),
                const SizedBox(height: 16),
                
                _buildSummaryRow('Service', _selectedService!.name),
                _buildSummaryRow('Date', _formatDate(_selectedDate!)),
                _buildSummaryRow('Time', _selectedTime!.format(context)),
                _buildSummaryRow('Stylist', _selectedStaff ?? 'Any available'),
                _buildSummaryRow('Duration', '${_selectedService!.durationMinutes} minutes'),
                const Divider(),
                _buildSummaryRow('Price', '\$${_selectedService!.price.toStringAsFixed(2)}'),
                if (discount > 0) ...[
                  _buildSummaryRow('Discount', '-\$${discount.toStringAsFixed(2)}'),
                  const Divider(),
                ],
                _buildSummaryRow('Total', '\$${finalPrice.toStringAsFixed(2)}', isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Promo Code
          AppTheme.glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Promo Code',
                  style: AppTheme.heading3,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _promoCode = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: ElevatedButton(
                      onPressed: _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMauve,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notes
          AppTheme.glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Special Requests',
                  style: AppTheme.heading3,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _notes = value;
                    });
                  },
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any special requests or notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryMauve : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryMauve,
                    side: const BorderSide(color: AppTheme.primaryMauve),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Previous'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _canProceed() ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMauve,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(_currentStep == 2 ? 'Confirm Booking' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedService != null;
      case 1:
        return _selectedDate != null && _selectedTime != null;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmBooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _applyPromoCode() {
    if (_promoCode == 'SAVE10') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied! 10% discount added.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _confirmBooking() async {
    try {
      // Get the authenticated user
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to book an appointment'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      
      print('🎯 Starting appointment booking process...');
      print('📅 Selected date: $_selectedDate');
      print('⏰ Selected time: $_selectedTime');
      print('🏢 Salon ID: ${widget.salon.id}');
      print('🔧 Service ID: ${_selectedService!.id}');
      print('👤 Customer ID: ${authState.user!.id}');
      
      // Create appointment using the proper provider
      final appointment = await ref.read(appointmentsProvider.notifier).bookAppointment(
        customerId: authState.user!.id, // Use actual authenticated user ID
        salonId: widget.salon.id,
        serviceId: _selectedService!.id,
        startAt: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        ),
        notes: _notes.isNotEmpty ? _notes : null,
        staffId: _selectedStaff,
      );

      if (appointment != null) {
        print('✅ Appointment created successfully: ${appointment.id}');
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate to appointments
        await Future.delayed(const Duration(seconds: 1));
        context.push('/customer-appointments');
      } else {
        print('❌ Appointment creation returned null');
        throw Exception('Failed to create appointment');
      }
    } catch (e) {
      print('❌ Booking failed with error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // Check if date is unavailable based on existing bookings and business rules
  bool _isDateUnavailable(DateTime date) {
    // Make weekends unavailable (business rule)
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return true;
    }
    
    // Make past dates unavailable
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (date.isBefore(todayDate)) {
      return true;
    }
    
    // Make certain dates unavailable (e.g., holidays)
    final unavailableDates = [
      DateTime(2024, 12, 25), // Christmas
      DateTime(2024, 1, 1),   // New Year
      DateTime(2024, 7, 4),   // Independence Day
    ];
    
    final isHoliday = unavailableDates.any((unavailableDate) => 
      date.year == unavailableDate.year &&
      date.month == unavailableDate.month &&
      date.day == unavailableDate.day
    );
    
    if (isHoliday) return true;
    
    // Get appointments for this salon and date
    final appointments = ref.read(appointmentsProvider).value ?? [];
    final salonAppointments = appointments.where((appointment) {
      return appointment.salonId == widget.salon.id &&
             appointment.startAt.year == date.year &&
             appointment.startAt.month == date.month &&
             appointment.startAt.day == date.day;
    }).toList();
    
    // Date is fully booked if all available time slots are taken
    // This is a simplified check - in reality, you'd check against available time slots
    final activeAppointments = salonAppointments.where((appointment) {
      return appointment.status != AppointmentStatus.cancelled &&
             appointment.status != AppointmentStatus.completed &&
             appointment.status != AppointmentStatus.noShow;
    }).length;
    
    // If there are more than 8 active appointments on this date, consider it fully booked
    // (assuming 8 time slots per day)
    return activeAppointments >= 8;
  }

  // Check if time slot is unavailable based on existing bookings
  bool _isTimeSlotUnavailable(DateTime date, TimeOfDay time) {
    // Get appointments for this salon
    final appointments = ref.read(appointmentsProvider).value ?? [];
    
    // Filter appointments for this salon and date
    final salonAppointments = appointments.where((appointment) {
      return appointment.salonId == widget.salon.id &&
             appointment.startAt.year == date.year &&
             appointment.startAt.month == date.month &&
             appointment.startAt.day == date.day;
    }).toList();
    
    // Check if any appointment conflicts with this time slot
    return salonAppointments.any((appointment) {
      // Create DateTime objects for comparison
      final appointmentStart = appointment.startAt;
      final appointmentEnd = appointment.endAt;
      final requestedStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      
      // Calculate end time for the requested slot based on service duration
      final serviceDuration = _selectedService?.durationMinutes ?? 60; // Default to 60 minutes
      final requestedEnd = requestedStart.add(Duration(minutes: serviceDuration));
      
      // Check for time overlap
      final hasOverlap = (requestedStart.isBefore(appointmentEnd) && requestedEnd.isAfter(appointmentStart));
      
      // Time slot is unavailable if:
      // 1. There's a time overlap, AND
      // 2. The appointment is not cancelled or completed
      return hasOverlap && 
             appointment.status != AppointmentStatus.cancelled &&
             appointment.status != AppointmentStatus.completed &&
             appointment.status != AppointmentStatus.noShow;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}