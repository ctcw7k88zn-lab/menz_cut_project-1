import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/ai_provider.dart';
import '../../models/ai_suggestion_model.dart';
import '../../widgets/lottie_loader.dart';

class AIHairSuggestionsScreen extends ConsumerStatefulWidget {
  const AIHairSuggestionsScreen({super.key});

  @override
  ConsumerState<AIHairSuggestionsScreen> createState() => _AIHairSuggestionsScreenState();
}

class _AIHairSuggestionsScreenState extends ConsumerState<AIHairSuggestionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _uploadAnimationController;
  late AnimationController _suggestionAnimationController;
  late Animation<double> _uploadScaleAnimation;
  late Animation<double> _suggestionFadeAnimation;
  
  String? _selectedImagePath;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _uploadAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _suggestionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _uploadScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _uploadAnimationController, curve: Curves.easeInOut),
    );
    
    _suggestionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _suggestionAnimationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiProvider.notifier).loadAllSuggestions();
    });
  }

  @override
  void dispose() {
    _uploadAnimationController.dispose();
    _suggestionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);

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
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                              ),
                              const Expanded(
                                child: Text(
                                  'AI Hair Suggestions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'AI',
                                      style: TextStyle(
                                        color: AppTheme.accentGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload Section
                    _buildUploadSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Suggestions Section
                    if (_selectedImagePath != null || aiState.suggestions.isNotEmpty) ...[
                      const Text(
                        'AI Suggestions',
                        style: AppTheme.heading2,
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isGenerating)
                        const LottieLoader(
                          assetPath: 'assets/lottie/loading.json',
                          message: 'Generating AI suggestions...',
                        )
                      else if (aiState.isLoading)
                        const LottieLoader(
                          assetPath: 'assets/lottie/loading.json',
                          message: 'Loading suggestions...',
                        )
                      else if (aiState.error != null)
                        _buildErrorState(aiState.error!)
                      else if (aiState.suggestions.isNotEmpty)
                        FadeTransition(
                          opacity: _suggestionFadeAnimation,
                          child: Column(
                            children: aiState.suggestions.map((suggestion) {
                              return _buildSuggestionCard(suggestion);
                            }).toList(),
                          ),
                        ),
                    ] else ...[
                      _buildEmptyState(),
                    ],
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
            currentIndex: 3,
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
                  // Already on AI suggestions
                  break;
                case 4:
                  context.go('/customer-profile');
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

  Widget _buildUploadSection() {
    return AppTheme.glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Your Photo',
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 8),
          const Text(
            'Get personalized hair style suggestions based on your face shape and preferences',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          if (_selectedImagePath == null)
            _buildUploadOptions()
          else
            _buildImagePreview(),
        ],
      ),
    );
  }

  Widget _buildUploadOptions() {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _uploadScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _uploadScaleAnimation.value,
                child: GestureDetector(
                  onTap: () => _selectImage('camera'),
                  onTapDown: (_) => _uploadAnimationController.forward(),
                  onTapUp: (_) => _uploadAnimationController.reverse(),
                  onTapCancel: () => _uploadAnimationController.reverse(),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryMauve.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Take Photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedBuilder(
            animation: _uploadScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _uploadScaleAnimation.value,
                child: GestureDetector(
                  onTap: () => _selectImage('gallery'),
                  onTapDown: (_) => _uploadAnimationController.forward(),
                  onTapUp: (_) => _uploadAnimationController.reverse(),
                  onTapCancel: () => _uploadAnimationController.reverse(),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Choose from Gallery',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryMauve.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _selectedImagePath != null
                ? Image.network(
                    _selectedImagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primaryMauve.withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 64,
                          color: AppTheme.primaryMauve,
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppTheme.primaryMauve.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 64,
                      color: AppTheme.primaryMauve,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectImage('gallery'),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Change Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryMauve,
                  side: const BorderSide(color: AppTheme.primaryMauve),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generateSuggestions,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Generate AI Suggestions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMauve,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const LottieLoader(
            assetPath: 'assets/lottie/upload_photo.json',
            message: 'Upload your photo to get AI hair suggestions',
          ),
          const SizedBox(height: 24),
          Text(
            'How it works:',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.camera_alt,
            title: 'Upload Photo',
            description: 'Take a selfie or choose from gallery',
          ),
          _buildFeatureItem(
            icon: Icons.auto_awesome,
            title: 'AI Analysis',
            description: 'Our AI analyzes your face shape and features',
          ),
          _buildFeatureItem(
            icon: Icons.style,
            title: 'Get Suggestions',
            description: 'Receive personalized hair style recommendations',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMauve.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryMauve.withOpacity(0.1)),
      ),
      child: Row(
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
                  style: AppTheme.heading3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error generating suggestions',
            style: AppTheme.heading3.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateSuggestions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(AISuggestionModel suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with confidence score
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${(suggestion.confidence * 100).toInt()}% Match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _bookSuggestion(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Book This Style',
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
            
            // Style image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                suggestion.styleImageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMauve.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.style,
                      size: 64,
                      color: AppTheme.primaryMauve,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Style details
            Text(
              suggestion.styleName,
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.description,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Features
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestion.features.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMauve.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryMauve.withOpacity(0.3)),
                  ),
                  child: Text(
                    feature,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryMauve,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _selectImage(String source) {
    // Mock image selection
    setState(() {
      _selectedImagePath = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400';
    });
  }

  void _generateSuggestions() async {
    if (_selectedImagePath == null) return;
    
    setState(() {
      _isGenerating = true;
    });
    
    try {
      // Create a mock File object for the image URL
      // In a real app, you would use image_picker to get an actual File
      final mockFile = File(_selectedImagePath!);
      
      // Generate AI suggestions using the provider
      await ref.read(aiProvider.notifier).generateSuggestions('customer_1', mockFile);
      
      // Start suggestion animation
      _suggestionAnimationController.forward();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI suggestions generated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate suggestions: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _bookSuggestion(AISuggestionModel suggestion) {
    // Navigate to booking screen with pre-filled data
    context.go('/booking', extra: {
      'suggestion': suggestion,
      'isAISuggestion': true,
    });
  }
}