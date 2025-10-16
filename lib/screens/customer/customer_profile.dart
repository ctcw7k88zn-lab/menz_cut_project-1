import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/app_api.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  late AnimationController _editAnimationController;

  @override
  void initState() {
    super.initState();
    _editAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _editAnimationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email;
      
      // Load user preferences
      _loadUserPreferences();
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
              expandedHeight: 180,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                              ),
                              const Spacer(),
                              const Text(
                                'My Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: _toggleEditMode,
                                  icon: Icon(
                                    _isEditing ? Icons.check : Icons.edit,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
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
                    
                    // Preferences Section
                    _buildPreferencesSection(),
                    const SizedBox(height: 24),
                    
                    // Logout Button
                    _buildLogoutButton(),
                    const SizedBox(height: 20),
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
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          color: AppTheme.primaryMauve,
        ),
        child: user?.profileImageUrl != null
            ? ClipOval(
                child: Image.network(
                  user!.profileImageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsAvatar(user.fullName);
                  },
                ),
              )
            : _buildInitialsAvatar(user?.fullName ?? 'U'),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return AppTheme.glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Information',
                  style: AppTheme.heading3,
                ),
                if (!_isEditing)
                  TextButton.icon(
                    onPressed: _toggleEditMode,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryMauve,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
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
            
            _buildDropdownField(
              label: 'Gender',
              icon: Icons.person_outline,
              enabled: _isEditing,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleEditMode, // This will save changes
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMauve,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                        });
                        _editAnimationController.reverse();
                        // Reset to original values
                        final user = ref.read(authProvider).user;
                        if (user != null) {
                          _nameController.text = user.fullName;
                          _phoneController.text = user.phone ?? '';
                          _emailController.text = user.email;
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
              color: enabled ? AppTheme.primaryMauve : Colors.grey[300]!,
              width: enabled ? 2 : 1,
            ),
            boxShadow: enabled ? [
              BoxShadow(
                color: AppTheme.primaryMauve.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: AppTheme.bodyMedium.copyWith(
              color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: enabled ? AppTheme.primaryMauve : Colors.grey,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required bool enabled,
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
              color: enabled ? AppTheme.primaryMauve : Colors.grey[300]!,
              width: enabled ? 2 : 1,
            ),
            boxShadow: enabled ? [
              BoxShadow(
                color: AppTheme.primaryMauve.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: 'Not Specified', // Default value
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: enabled ? AppTheme.primaryMauve : Colors.grey,
              ),
              style: AppTheme.bodyMedium.copyWith(
                color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
              items: const [
                DropdownMenuItem(value: 'Not Specified', child: Text('Not Specified')),
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: enabled ? (value) {
                // For now, just show a snackbar since we don't have gender in the database
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gender selection: $value'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return AppTheme.glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 20),
            
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications about appointments',
              icon: Icons.notifications_outlined,
              value: _notificationsEnabled,
              onChanged: (value) => _toggleNotifications(value),
            ),
            const SizedBox(height: 16),
            
            _buildSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              icon: Icons.dark_mode_outlined,
              value: _darkModeEnabled,
              onChanged: (value) => _toggleDarkMode(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryMauve.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryMauve,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
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

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
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
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
      // Show editing mode feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Editing mode enabled - tap check to save changes'),
          duration: Duration(seconds: 2),
        ),
      );
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
        // Validate input
        if (_nameController.text.trim().isEmpty) {
          _showErrorSnackBar('Please enter your full name');
          return;
        }

        if (_phoneController.text.trim().isEmpty) {
          _showErrorSnackBar('Please enter your phone number');
          return;
        }

        // Show loading indicator
        _showLoadingSnackBar('Updating profile...');
        
        // Create updated user model
        final updatedUser = authState.user!.copyWith(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          updatedAt: DateTime.now(),
        );
        
        // Update profile via Supabase directly
        final success = await _updateProfileInSupabase(updatedUser);
        
        if (success) {
          // Update the auth provider state
          await ref.read(authProvider.notifier).updateProfile(updatedUser);
          
          _showSuccessSnackBar('Profile updated successfully!');
          
          // Exit edit mode
          setState(() {
            _isEditing = false;
          });
          _editAnimationController.reverse();
        } else {
          _showErrorSnackBar('Failed to update profile. Please try again.');
        }
      } else {
        _showErrorSnackBar('Please login to update your profile');
      }
    } catch (e) {
      print('Profile update error: $e');
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    }
  }

  Future<bool> _updateProfileInSupabase(UserModel user) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('profiles').update({
        'full_name': user.fullName,
        'phone': user.phone,
        'avatar_url': user.profileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      return true;
    } catch (e) {
      print('Supabase profile update error: $e');
      return false;
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.primaryMauve,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _changeProfilePicture() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: const Text('Choose an option to update your profile picture'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Uploading profile picture...'),
              ],
            ),
          ),
        );

        // Upload image to Supabase Storage directly
        final authState = ref.read(authProvider);
        if (authState.user != null) {
          final imageUrl = await _uploadProfileImageToSupabase(
            File(image.path),
            authState.user!.id,
          );

          // Close loading dialog
          Navigator.pop(context);

          if (imageUrl != null) {
            // Update user profile with new image URL
            final updatedUser = authState.user!.copyWith(
              profileImageUrl: imageUrl,
              updatedAt: DateTime.now(),
            );
            
            // Update in Supabase database
            final success = await _updateProfileInSupabase(updatedUser);
            
            if (success) {
              // Update the auth provider state
              await ref.read(authProvider.notifier).updateProfile(updatedUser);
              
              _showSuccessSnackBar('Profile picture updated successfully!');
            } else {
              _showErrorSnackBar('Failed to update profile with new image');
            }
          } else {
            _showErrorSnackBar('Failed to upload profile picture');
          }
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showErrorSnackBar('Error uploading image: ${e.toString()}');
    }
  }

  Future<String?> _uploadProfileImageToSupabase(File imageFile, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload file to storage
      await supabase.storage
          .from('profile-pics')
          .upload(fileName, imageFile);

      // Get public URL
      final imageUrl = supabase.storage
          .from('profile-pics')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Profile image upload error: $e');
      return null;
    }
  }

  void _toggleDarkMode(bool value) async {
    try {
      setState(() {
        _darkModeEnabled = value;
      });

      // Save preference to Supabase
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        await _saveUserPreference('dark_mode', value);
        
        if (value) {
          _showSuccessSnackBar('Dark mode enabled');
        } else {
          _showSuccessSnackBar('Dark mode disabled');
        }
      }
    } catch (e) {
      // Revert the state if there's an error
      setState(() {
        _darkModeEnabled = !value;
      });
      _showErrorSnackBar('Failed to update dark mode preference');
    }
  }

  void _toggleNotifications(bool value) async {
    try {
      setState(() {
        _notificationsEnabled = value;
      });

      // Save preference to Supabase
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        await _saveUserPreference('push_notifications', value);
        
        if (value) {
          _showSuccessSnackBar('Push notifications enabled');
        } else {
          _showSuccessSnackBar('Push notifications disabled');
        }
      }
    } catch (e) {
      // Revert the state if there's an error
      setState(() {
        _notificationsEnabled = !value;
      });
      _showErrorSnackBar('Failed to update notification preference');
    }
  }

  Future<void> _saveUserPreference(String key, dynamic value) async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      
      if (authState.user != null) {
        // Check if user preferences exist
        final existing = await supabase
            .from('user_preferences')
            .select('preferences')
            .eq('user_id', authState.user!.id)
            .maybeSingle();

        Map<String, dynamic> preferences = {};
        if (existing != null && existing['preferences'] != null) {
          preferences = Map<String, dynamic>.from(existing['preferences']);
        }

        // Update the specific preference
        preferences[key] = value;

        // Insert or update user preferences
        await supabase.from('user_preferences').upsert({
          'user_id': authState.user!.id,
          'preferences': preferences,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving user preference: $e');
      throw e;
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
            _darkModeEnabled = preferences['dark_mode'] ?? false;
            _notificationsEnabled = preferences['push_notifications'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }
}
