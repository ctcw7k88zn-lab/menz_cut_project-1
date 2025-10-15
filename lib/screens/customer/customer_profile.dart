import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _editAnimationController;
  late Animation<double> _editFadeAnimation;
  late Animation<Offset> _editSlideAnimation;
  
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedGender = 'Male';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  // Mock payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'type': 'Visa',
      'number': '**** 1234',
      'expiry': '12/25',
      'logo': 'assets/images/visa_logo.png',
    },
    {
      'type': 'PayPal',
      'email': 'user@example.com',
      'logo': 'assets/images/paypal_logo.png',
    },
  ];

  // Mock reviews
  final List<Map<String, dynamic>> _reviews = [
    {
      'salonName': 'Style Studio',
      'rating': 5.0,
      'comment': 'Amazing haircut! The stylist was very professional.',
      'date': '2024-01-15',
      'service': 'Haircut & Styling',
    },
    {
      'salonName': 'Luxury Spa',
      'rating': 4.5,
      'comment': 'Great spa experience, very relaxing.',
      'date': '2024-01-10',
      'service': 'Facial Treatment',
    },
  ];

  @override
  void initState() {
    super.initState();
    _editAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _editFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _editAnimationController, curve: Curves.easeInOut),
    );
    _editSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _editAnimationController, curve: Curves.easeInOut));

    _loadUserData();
  }

  @override
  void dispose() {
    _editAnimationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.user != null) {
      final user = authState.user!;
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
              expandedHeight: 200,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/customer-home');
                                  }
                                },
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                              ),
                              const Expanded(
                                child: Text(
                                  'My Profile',
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
                                onPressed: _toggleEditMode,
                                icon: Icon(
                                  _isEditing ? Icons.check : Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: _buildProfileAvatar(user),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Personal Info Section
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    
                    // Payment Methods Section
                    _buildPaymentMethodsSection(),
                    const SizedBox(height: 24),
                    
                    // Preferences Section
                    _buildPreferencesSection(),
                    const SizedBox(height: 24),
                    
                    // My Reviews Section
                    _buildReviewsSection(),
                    const SizedBox(height: 24),
                    
                    // Logout Button
                    _buildLogoutButton(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
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
            currentIndex: 4,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/customer-home');
                  break;
                case 1:
                  context.go('/customer-map');
                  break;
                case 2:
                  context.go('/customer-appointments');
                  break;
                case 3:
                  context.go('/ai-hair-suggestions');
                  break;
                case 4:
                  // Already on profile
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

  Widget _buildProfileAvatar(UserModel? user) {
    return GestureDetector(
      onTap: _isEditing ? _changeProfilePicture : null,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: user?.profileImageUrl != null
                  ? Image.network(
                      user!.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(user.fullName ?? 'User');
                      },
                    )
                  : _buildDefaultAvatar(user?.fullName ?? 'User'),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return AppTheme.glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 16),
          
          _buildEditableField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.person,
            enabled: _isEditing,
          ),
          const SizedBox(height: 16),
          
          _buildEditableField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          
          _buildEditableField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email,
            enabled: false, // Email is not editable
          ),
          const SizedBox(height: 16),
          
          _buildGenderSelector(),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? AppTheme.primaryMauve.withOpacity(0.3) : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryMauve),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_isEditing)
          Row(
            children: [
              Expanded(
                child: _buildGenderOption('Male', Icons.male),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption('Female', Icons.female),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedGender == 'Male' ? Icons.male : Icons.female,
                  color: AppTheme.primaryMauve,
                ),
                const SizedBox(width: 12),
                Text(_selectedGender, style: AppTheme.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryMauve.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryMauve : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryMauve : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              gender,
              style: AppTheme.bodyMedium.copyWith(
                color: isSelected ? AppTheme.primaryMauve : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return AppTheme.glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Payment Methods',
                style: AppTheme.heading2,
              ),
              const Spacer(),
              if (_isEditing)
                GestureDetector(
                  onTap: _addPaymentMethod,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMauve.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppTheme.primaryMauve,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryMauve.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.credit_card,
              color: AppTheme.primaryMauve,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method['type'],
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  method['number'] ?? method['email'],
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (_isEditing)
            GestureDetector(
              onTap: () => _removePaymentMethod(method),
              child: const Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return AppTheme.glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 16),
          
          _buildPreferenceSwitch(
            title: 'Push Notifications',
            subtitle: 'Receive appointment reminders and updates',
            value: _notificationsEnabled,
            onChanged: _isEditing ? (value) => setState(() => _notificationsEnabled = value) : null,
            icon: Icons.notifications,
          ),
          const SizedBox(height: 16),
          
          _buildPreferenceSwitch(
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            value: _darkModeEnabled,
            onChanged: _isEditing ? (value) => setState(() => _darkModeEnabled = value) : null,
            icon: Icons.dark_mode,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryMauve.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryMauve),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryMauve,
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return AppTheme.glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Reviews',
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 16),
          
          if (_reviews.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No reviews yet',
                  style: AppTheme.bodyMedium,
                ),
              ),
            )
          else
            ..._reviews.map((review) => _buildReviewCard(review)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review['salonName'],
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review['rating'] ? Icons.star : Icons.star_border,
                    color: AppTheme.accentGold,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['service'],
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'],
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            review['date'],
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
    
    if (_isEditing) {
      _editAnimationController.forward();
    } else {
      _editAnimationController.reverse();
      _saveChanges();
    }
  }

  void _saveChanges() async {
    try {
      // Get current user from auth provider
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.user != null) {
        // Create updated user model
        final updatedUser = authState.user!.copyWith(
          fullName: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
        );
        
        // Update profile via AppApi
        await ref.read(authProvider.notifier).updateProfile(updatedUser);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _changeProfilePicture() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: const Text('Choose an option to update your profile picture'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement camera functionality with image_picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Camera functionality coming soon'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement gallery functionality with image_picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gallery functionality coming soon'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  void _addPaymentMethod() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: const Text('Payment method functionality would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _removePaymentMethod(Map<String, dynamic> method) {
    setState(() {
      _paymentMethods.remove(method);
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}