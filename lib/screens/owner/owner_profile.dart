import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

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
  final _shopNameController = TextEditingController(text: 'Elite Hair Studio');
  final _ownerNameController = TextEditingController(text: 'Ahmed Khan');
  final _phoneController = TextEditingController(text: '+92 300 1234567');
  final _emailController = TextEditingController(text: 'owner@elitehair.com');
  final _addressController = TextEditingController(text: 'Model Town, Bahawalpur');
  final _descriptionController = TextEditingController(text: 'Premium hair salon offering cutting-edge styles and personalized service in a luxurious atmosphere.');
  
  bool _receiveNotifications = true;
  bool _acceptOnlineBookings = true;
  bool _isEditing = false;

  final List<String> _serviceCategories = ['Haircut', 'Beard', 'Coloring', 'Facial', 'Hair Treatment'];
  final List<String> _selectedCategories = ['Haircut', 'Beard', 'Coloring'];
  
  final List<String> _shopImages = [
    'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
    'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400',
    'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
          onPressed: () => _showComingSoon('Back'),
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
            onPressed: () => setState(() => _isEditing = !_isEditing),
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
          Container(
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
                    child: const Icon(
                      Icons.business,
                    color: AppTheme.primaryMauve,
                    size: 50,
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
              const Text(
            'Opening Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildTimeRow('Monday - Friday', '9:00 AM - 7:00 PM'),
                const Divider(),
                _buildTimeRow('Saturday', '9:00 AM - 6:00 PM'),
                const Divider(),
                _buildTimeRow('Sunday', '10:00 AM - 5:00 PM'),
              ],
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
              (value) => setState(() => _receiveNotifications = value),
            ),
            const Divider(),
            _buildSwitchTile(
              'Accept Online Bookings',
              'Allow customers to book appointments online',
              _acceptOnlineBookings,
              (value) => setState(() => _acceptOnlineBookings = value),
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

  void _changeProfilePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change profile picture feature coming soon!'),
        backgroundColor: AppTheme.primaryMauve,
      ),
    );
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

  void _addShopImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add shop image feature coming soon!'),
        backgroundColor: AppTheme.primaryMauve,
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _shopImages.removeAt(index);
    });
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user from auth provider
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated && authState.user != null) {
          // Create updated user model
          final updatedUser = authState.user!.copyWith(
            fullName: _ownerNameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
          );
          
          // Update profile via AppApi
          await ref.read(authProvider.notifier).updateProfile(updatedUser);
          
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
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