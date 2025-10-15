import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentPage = 0;
  final int _totalPages = 3;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Find Your Perfect Salon',
      description: 'Discover top-rated salons near you with detailed reviews, photos, and service menus.',
      image: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
      color: AppTheme.primaryMauve,
    ),
    OnboardingPage(
      title: 'Book with Ease',
      description: 'Schedule appointments instantly with real-time availability and instant confirmations.',
      image: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400',
      color: AppTheme.primaryLavender,
    ),
    OnboardingPage(
      title: 'AI-Powered Suggestions',
      description: 'Get personalized hair style recommendations based on your face shape and preferences.',
      image: 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400',
      color: AppTheme.accentGold,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
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
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60), // Placeholder for balance
                    Text(
                      '${_currentPage + 1} of $_totalPages',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppTheme.primaryMauve,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _fadeAnimationController.reset();
                    _slideAnimationController.reset();
                    _fadeAnimationController.forward();
                    _slideAnimationController.forward();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_pages[index]);
                  },
                ),
              ),

              // Bottom Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _totalPages,
                        (index) => _buildPageIndicator(index),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Navigation Buttons
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousPage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryMauve,
                                side: const BorderSide(color: AppTheme.primaryMauve),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Previous'),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 16),
                        Expanded(
                          flex: _currentPage == 0 ? 1 : 2,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryMauve,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(_currentPage == _totalPages - 1 ? 'Get Started' : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image
              Flexible(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: page.color.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Image.network(
                        page.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  page.color,
                                  page.color.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.business,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              page.color.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
              const SizedBox(height: 24),

              // Title
              Flexible(
                flex: 1,
                child: Text(
                  page.title,
                  style: AppTheme.heading2.copyWith(
                    fontSize: 24,
                    color: page.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Flexible(
                flex: 2,
                child: Text(
                  page.description,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Feature Icons
              Flexible(
                flex: 1,
                child: _buildFeatureIcons(_currentPage),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcons(int pageIndex) {
    List<IconData> icons;
    List<String> labels;

    switch (pageIndex) {
      case 0:
        icons = [Icons.search, Icons.star, Icons.location_on];
        labels = ['Search', 'Reviews', 'Location'];
        break;
      case 1:
        icons = [Icons.calendar_today, Icons.schedule, Icons.check_circle];
        labels = ['Schedule', 'Availability', 'Confirm'];
        break;
      case 2:
        icons = [Icons.face, Icons.auto_awesome, Icons.recommend];
        labels = ['AI Analysis', 'Suggestions', 'Personalized'];
        break;
      default:
        icons = [];
        labels = [];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(icons.length, (index) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _pages[pageIndex].color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icons[index],
                color: _pages[pageIndex].color,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[index],
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    final page = _pages[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? page.color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    // Navigate to role selection
    context.go('/role-select');
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}