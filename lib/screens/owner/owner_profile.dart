import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';

class OwnerProfileScreen extends ConsumerStatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  ConsumerState<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends ConsumerState<OwnerProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _receiveNotifications = true;
  bool _acceptOnlineBookings = true;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  
  // Opening hours state - individual days for better control
  Map<String, Map<String, dynamic>> _openingHours = {
    'Monday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
    'Tuesday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
    'Wednesday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
    'Thursday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
    'Friday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
    'Saturday': {'open': '11:00 AM', 'close': '6:00 PM', 'isOpen': true},
    'Sunday': {'open': '', 'close': '', 'isOpen': false},
  };

  final List<String> _serviceCategories = ['Haircut', 'Beard', 'Coloring', 'Facial', 'Hair Treatment'];
  final List<String> _selectedCategories = ['Haircut', 'Beard', 'Coloring'];
  
  List<String> _shopImages = [
    'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
    'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400',
    'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeOpeningHours(); // Initialize opening hours first
    _loadProfileData();
  }


  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.user != null) {
        final user = authState.user!;
        
        // Load profile data from user and database
        await _loadProfileFromDatabase(user);
        // Only set profile image from user if not loaded from database
        if (_profileImageUrl == null) {
          _profileImageUrl = user.profileImageUrl;
        }
        
        // Load user preferences
        await _loadUserPreferences();
        
        // Only initialize opening hours if not loaded from database
        if (_openingHours.isEmpty) {
          _initializeOpeningHours();
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshProfileData() async {
    // Clear current data to force reload from database
    _openingHours.clear();
    _profileImageUrl = null;
    await _loadProfileData();
  }

  void _initializeOpeningHours() {
    // Always initialize opening hours with default values
    setState(() {
      _openingHours = {
        'Monday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
        'Tuesday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
        'Wednesday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
        'Thursday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
        'Friday': {'open': '11:00 AM', 'close': '8:00 PM', 'isOpen': true},
        'Saturday': {'open': '11:00 AM', 'close': '6:00 PM', 'isOpen': true},
        'Sunday': {'open': '', 'close': '', 'isOpen': false},
      };
    });
    print('Opening hours initialized: $_openingHours');
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

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
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
                  _buildProfileHeader(),
                  _buildProfileForm(),
                  _buildSettingsSection(),
                  _buildLogoutSection(),
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
        'Profile',
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
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
              // Refresh profile data when entering edit mode
              if (_isEditing) {
                _refreshProfileData();
              }
            },
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: AppTheme.primaryMauve,
            ),
              ),
            ),
          ],
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryMauve, AppTheme.primaryMauve.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryMauve.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
        children: [
          GestureDetector(
            onTap: _changeProfilePicture,
            child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    ),
                      child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty && !_profileImageUrl!.contains('placeholder')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                _profileImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading profile image: $error');
                                  return const Icon(
                      Icons.business,
                    color: AppTheme.primaryMauve,
                    size: 50,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.business,
                              color: AppTheme.primaryMauve,
                              size: 50,
                            ),
                    ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
                  child: GestureDetector(
                    onTap: _changeProfilePicture,
              child: Container(
                width: 32,
                height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                  shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                        color: AppTheme.primaryMauve,
                  size: 16,
                      ),
                ),
              ),
            ),
        ],
                ),
                const SizedBox(height: 16),
            Text(
              _shopNameController.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Premium Hair Salon',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '4.8 (156 reviews)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileForm() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
            child: Column(
              children: [
              _buildFormSection('Basic Information', [
                _buildTextField('Shop Name', _shopNameController, Icons.business, enabled: _isEditing),
                _buildTextField('Owner Name', _ownerNameController, Icons.person, enabled: _isEditing),
                _buildTextField('Phone Number', _phoneController, Icons.phone, enabled: _isEditing),
                _buildTextField('Email', _emailController, Icons.email, enabled: _isEditing),
                _buildTextField('Address', _addressController, Icons.location_on, enabled: _isEditing, maxLines: 2),
              ]),
              const SizedBox(height: 20),
              _buildFormSection('Business Details', [
                _buildTextField('Description', _descriptionController, Icons.description, enabled: _isEditing, maxLines: 3),
                _buildOpeningHours(),
                _buildServiceCategories(),
              ]),
              const SizedBox(height: 20),
              _buildShopImagesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool enabled = true, int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryMauve),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryMauve, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildOpeningHours() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
            'Opening Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: _editOpeningHours,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMauve,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _openingHours.isEmpty 
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No opening hours set',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Column(
                    children: _openingHours.entries.map((entry) {
                      final isLast = entry == _openingHours.entries.last;
                      final day = entry.key;
                      final hours = entry.value;
                      final isOpen = hours['isOpen'] ?? false;
                      final displayText = isOpen 
                          ? '${hours['open']} - ${hours['close']}'
                          : 'Closed';
                      return Column(
              children: [
                          _buildTimeRow(day, displayText),
                          if (!isLast) const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildTimeRow(String day, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCategories() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
            'Service Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _serviceCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return GestureDetector(
                onTap: _isEditing ? () => _toggleCategory(category) : null,
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryMauve : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryMauve : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShopImagesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                'Shop Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: _addShopImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                            color: AppTheme.primaryMauve,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Add Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _shopImages.length + (_isEditing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _shopImages.length && _isEditing) {
                  return _buildAddImageButton();
                }
                return _buildImagePreview(_shopImages[index], index);
              },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildImagePreview(String imageUrl, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
          child: Stack(
            children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
                imageUrl,
              width: 100,
              height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                      color: AppTheme.primaryMauve,
                  child: const Icon(Icons.image, color: Colors.white, size: 30),
                  );
                },
            ),
              ),
              if (_isEditing)
                Positioned(
              top: 4,
              right: 4,
                  child: GestureDetector(
                onTap: () => _removeImage(index),
                    child: Container(
                  width: 20,
                  height: 20,
                      decoration: const BoxDecoration(
                    color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                    size: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: const Icon(
        Icons.add_photo_alternate,
        color: Colors.grey,
        size: 30,
      ),
    );
  }

  Widget _buildSettingsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Receive Notifications',
              'Get notified about new appointments and messages',
              _receiveNotifications,
              (value) => _toggleNotifications(value),
            ),
            const Divider(),
            _buildSwitchTile(
              'Accept Online Bookings',
              'Allow customers to book appointments online',
              _acceptOnlineBookings,
              (value) => _toggleOnlineBookings(value),
            ),
          ],
                          ),
                        ),
                      );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primaryMauve,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLogoutSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
              children: [
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMauve,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
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

  Future<void> _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        
        // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Text('Uploading profile picture...'),
              ],
            ),
        backgroundColor: AppTheme.primaryMauve,
            duration: Duration(seconds: 3),
          ),
        );

        // Upload to Supabase
        final authState = ref.read(authProvider);
        if (authState.user != null) {
          final imageUrl = await _uploadProfileImageToSupabaseWeb(
            image,
            authState.user!.id,
          );

          if (imageUrl != null) {
            // Update profile in Supabase
            final updatedUser = authState.user!.copyWith(
              profileImageUrl: imageUrl,
              updatedAt: DateTime.now(),
            );

            print('Calling _updateProfileInSupabase with user: ${updatedUser.profileImageUrl}');
            final success = await _updateProfileInSupabase(updatedUser);
            print('_updateProfileInSupabase result: $success');
            if (success) {
              await ref.read(authProvider.notifier).updateProfile(updatedUser);
              
              setState(() {
                _profileImageUrl = imageUrl;
                _isLoading = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              print('Failed to update profile in Supabase');
              _showErrorSnackBar('Failed to update profile with new image');
            }
          } else {
            _showErrorSnackBar('Failed to upload profile picture');
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _addShopImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickShopImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickShopImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickShopImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        
        // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Text('Uploading shop image...'),
              ],
            ),
        backgroundColor: AppTheme.primaryMauve,
            duration: Duration(seconds: 3),
          ),
        );

        // Upload to Supabase storage
        final authState = ref.read(authProvider);
        if (authState.user != null) {
          final imageUrl = await _uploadShopImageToSupabase(image, authState.user!.id);

          if (imageUrl != null) {
            setState(() {
              _shopImages.add(imageUrl);
              _isLoading = false;
            });
            
            // Save shop images to database
            await _saveShopImagesToDatabase();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shop image added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            _showErrorSnackBar('Failed to upload shop image');
          }
        }
      }
    } catch (e) {
      print('Error picking shop image: $e');
      _showErrorSnackBar('Error selecting image: $e');
      setState(() => _isLoading = false);
    }
  }

  void _removeImage(int index) async {
    setState(() {
      _shopImages.removeAt(index);
    });
    
    // Save updated shop images to database
    await _saveShopImagesToDatabase();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop image removed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<String?> _uploadShopImageToSupabase(XFile imageFile, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'shop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/shop/$fileName'; // Upload to user's shop folder
      final bytes = await imageFile.readAsBytes();
      
      print('Starting shop image upload for file: $filePath');
      print('File size: ${bytes.length} bytes');
      
      // Try uploadBinary method
      try {
        print('Trying uploadBinary method for shop image...');
        await supabase.storage
            .from('profile-pics') // Using same bucket for now
            .uploadBinary(filePath, bytes);
        
        print('Shop image upload successful');
        final imageUrl = supabase.storage
            .from('profile-pics')
            .getPublicUrl(filePath);
        
        print('Generated shop image URL: $imageUrl');
        return imageUrl;
      } catch (uploadError) {
        print('Shop image upload failed: $uploadError');
        rethrow;
      }
    } catch (e) {
      print('Shop image upload error: $e');
      return null;
    }
  }

  Future<void> _saveShopImagesToDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      
      if (authState.user != null) {
        await supabase.from('profiles').update({
          'shop_images': _shopImages,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', authState.user!.id);
        
        print('Shop images saved to database: ${_shopImages.length} images');
      }
    } catch (e) {
      print('Error saving shop images to database: $e');
    }
  }

  Future<void> _saveOpeningHoursToDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      
      if (authState.user != null) {
        await supabase.from('profiles').update({
          'opening_hours': _openingHours,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', authState.user!.id);
        
        print('Opening hours saved to database');
      }
    } catch (e) {
      print('Error saving opening hours to database: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Get current user from auth provider
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated && authState.user != null) {
          // Create updated user model
          final updatedUser = authState.user!.copyWith(
            fullName: _ownerNameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
            updatedAt: DateTime.now(),
          );
          
          // Update profile in Supabase database
          final success = await _updateProfileInSupabase(updatedUser);
          if (success) {
            // Update auth provider state
          await ref.read(authProvider.notifier).updateProfile(updatedUser);
          
          setState(() => _isEditing = false);
            _showSuccessSnackBar('Profile updated successfully!');
          } else {
            _showErrorSnackBar('Failed to update profile in database');
          }
        }
      } catch (e) {
        print('Error saving profile changes: $e');
        _showErrorSnackBar('Failed to update profile: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _updateProfileInSupabase(UserModel user) async {
    try {
      final supabase = Supabase.instance.client;
      print('Updating profile in Supabase with avatar_url: ${user.profileImageUrl}');
      await supabase.from('profiles').update({
        'full_name': user.fullName,
        'phone': user.phone,
        'avatar_url': user.profileImageUrl,
        'shop_name': _shopNameController.text,
        'shop_description': _descriptionController.text,
        'shop_address': _addressController.text,
        'opening_hours': _openingHours,
        'shop_images': _shopImages,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      print('Profile updated successfully in Supabase');

      // Update auth user data separately
      try {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': user.fullName,
              'phone': user.phone,
              'avatar_url': user.profileImageUrl,
              'shop_name': _shopNameController.text,
              'shop_description': _descriptionController.text,
              'shop_address': _addressController.text,
            },
          ),
        );
        print('Auth user updated successfully');
      } catch (authError) {
        print('Auth user update failed (non-critical): $authError');
        // Don't fail the entire operation if auth update fails
      }
      return true;
    } catch (e) {
      print('Supabase profile update error: $e');
      return false;
    }
  }

  Future<String?> _uploadProfileImageToSupabaseWeb(XFile imageFile, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName'; // Upload to user's folder
      final bytes = await imageFile.readAsBytes();
      
      print('Starting upload for file: $filePath');
      print('File size: ${bytes.length} bytes');
      
      // Try uploadBinary method first
      try {
        print('Trying uploadBinary method...');
        await supabase.storage
            .from('profile-pics')
            .uploadBinary(filePath, bytes);
        
        print('UploadBinary successful');
        final imageUrl = supabase.storage
            .from('profile-pics')
            .getPublicUrl(filePath);
        
        print('Generated URL: $imageUrl');
        return imageUrl;
      } catch (uploadError) {
        print('UploadBinary failed: $uploadError');
        rethrow;
      }
    } catch (e) {
      print('Profile image upload error: $e');
      return null;
    }
  }

  Future<void> _loadProfileFromDatabase(UserModel user) async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('profiles')
          .select('shop_name, shop_description, shop_address, opening_hours, shop_images, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (result != null) {
        _shopNameController.text = result['shop_name'] ?? 'Elite Hair Studio';
        _descriptionController.text = result['shop_description'] ?? 'Premium hair salon offering cutting-edge styles and personalized service in a luxurious atmosphere.';
        _addressController.text = result['shop_address'] ?? 'Model Town, Bahawalpur';
        _ownerNameController.text = user.fullName;
        _phoneController.text = user.phone ?? '';
        _emailController.text = user.email;
        
        // Load profile image if available
        print('Loading avatar_url from database: ${result['avatar_url']}');
        if (result['avatar_url'] != null) {
          setState(() {
            _profileImageUrl = result['avatar_url'];
          });
          print('Profile image loaded from database: $_profileImageUrl');
        } else {
          print('No avatar_url found in database');
        }
        
        // Load opening hours if available
        if (result['opening_hours'] != null) {
          setState(() {
            _openingHours = Map<String, Map<String, dynamic>>.from(
              result['opening_hours'].map((key, value) => 
                MapEntry(key, Map<String, dynamic>.from(value))
              )
            );
          });
        }
        
        // Load shop images if available
        if (result['shop_images'] != null && result['shop_images'].isNotEmpty) {
          setState(() {
            _shopImages = List<String>.from(result['shop_images']);
          });
        }
      } else {
        // Set defaults if no profile data exists
        _shopNameController.text = 'Elite Hair Studio';
        _descriptionController.text = 'Premium hair salon offering cutting-edge styles and personalized service in a luxurious atmosphere.';
        _addressController.text = 'Model Town, Bahawalpur';
        _ownerNameController.text = user.fullName;
        _phoneController.text = user.phone ?? '';
        _emailController.text = user.email;
      }
    } catch (e) {
      print('Error loading profile from database: $e');
      // Set defaults on error
      _shopNameController.text = 'Elite Hair Studio';
      _descriptionController.text = 'Premium hair salon offering cutting-edge styles and personalized service in a luxurious atmosphere.';
      _addressController.text = 'Model Town, Bahawalpur';
      _ownerNameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email;
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      
      if (authState.user != null) {
        final result = await supabase
            .from('user_preferences')
            .select('preferences')
            .eq('user_id', authState.user!.id)
            .maybeSingle();

        if (result != null && result['preferences'] != null) {
          final preferences = Map<String, dynamic>.from(result['preferences']);
          setState(() {
            _receiveNotifications = preferences['receive_notifications'] ?? true;
            _acceptOnlineBookings = preferences['accept_online_bookings'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
          ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
        }

  void _showErrorSnackBar(String message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
          ),
        );
      }

  void _editOpeningHours() {
    print('Opening hours data: $_openingHours');
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Opening Hours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryMauve,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                
                // Content
                Expanded(
                  child: ListView.builder(
                    itemCount: _openingHours.length,
                    itemBuilder: (context, index) {
                      final day = _openingHours.keys.elementAt(index);
                      final hours = _openingHours[day]!;
                      print('Building row for $day: $hours');
                      return _buildDayScheduleRow(day, hours, setDialogState);
                    },
                  ),
                ),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryMauve),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.primaryMauve),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                          _saveOpeningHoursToDatabase();
                          _showSuccessSnackBar('Opening hours updated successfully!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMauve,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayScheduleRow(String day, Map<String, dynamic> hours, StateSetter setDialogState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day name and toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: hours['isOpen'] ?? false,
                onChanged: (value) {
                  setDialogState(() {
                    _openingHours[day]!['isOpen'] = value;
                    if (!value) {
                      _openingHours[day]!['open'] = '';
                      _openingHours[day]!['close'] = '';
                    } else {
                      _openingHours[day]!['open'] = '11:00 AM';
                      _openingHours[day]!['close'] = '8:00 PM';
                    }
                  });
                },
                activeThumbColor: AppTheme.primaryMauve,
              ),
            ],
          ),
          
          // Time inputs (only show if day is open)
          if (hours['isOpen'] ?? false) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: hours['open'] ?? '',
                    decoration: InputDecoration(
                      labelText: 'Opening Time',
                      hintText: 'e.g., 11:00 AM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    onChanged: (value) {
                      _openingHours[day]!['open'] = value;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: hours['close'] ?? '',
                    decoration: InputDecoration(
                      labelText: 'Closing Time',
                      hintText: 'e.g., 8:00 PM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    onChanged: (value) {
                      _openingHours[day]!['close'] = value;
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Closed',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _receiveNotifications = value);
    try {
      await _saveUserPreference('receive_notifications', value);
    } catch (e) {
      setState(() => _receiveNotifications = !value);
      _showErrorSnackBar('Failed to update notification preference');
    }
  }

  Future<void> _toggleOnlineBookings(bool value) async {
    setState(() => _acceptOnlineBookings = value);
    try {
      await _saveUserPreference('accept_online_bookings', value);
    } catch (e) {
      setState(() => _acceptOnlineBookings = !value);
      _showErrorSnackBar('Failed to update online booking preference');
    }
  }

  Future<void> _saveUserPreference(String key, dynamic value) async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      
      if (authState.user != null) {
        print('Saving preference: $key = $value for user: ${authState.user!.id}');
        
        // Check if user preferences exist
        final existing = await supabase
            .from('user_preferences')
            .select('preferences')
            .eq('user_id', authState.user!.id)
            .maybeSingle();

        Map<String, dynamic> preferences = {};
        if (existing != null && existing['preferences'] != null) {
          preferences = Map<String, dynamic>.from(existing['preferences']);
          print('Existing preferences: $preferences');
        } else {
          print('No existing preferences found, creating new ones');
        }

        // Update the specific preference
        preferences[key] = value;
        print('Updated preferences: $preferences');

        // Insert or update user preferences
        final result = await supabase.from('user_preferences').upsert({
          'user_id': authState.user!.id,
          'preferences': preferences,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
        
        print('Preferences saved successfully: $result');
      }
    } catch (e) {
      print('Error saving user preference: $e');
      rethrow;
    }
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeProfilePhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Photo'),
        content: const Text('Choose how you want to update your salon photo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo updated successfully!'),
                  backgroundColor: AppTheme.primaryMauve,
                ),
              );
            },
            child: const Text('From Gallery'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo updated successfully!'),
                  backgroundColor: AppTheme.primaryMauve,
                ),
              );
            },
            child: const Text('Take Photo'),
          ),
        ],
      ),
    );
  }

  void _editShopInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            const Text(
              'Edit Shop Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Shop Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryMauve, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Owner Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryMauve, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryMauve, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryMauve, width: 2),
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
                      content: Text('Shop information updated successfully!'),
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
                  'Save Changes',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
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