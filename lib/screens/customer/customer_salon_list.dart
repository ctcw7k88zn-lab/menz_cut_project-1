import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/salons_provider.dart';
import '../../widgets/salon_card.dart';
import '../../widgets/search_bar.dart' as custom;
import '../../widgets/filter_sheet.dart';
import '../../widgets/lottie_loader.dart';

class CustomerSalonListScreen extends ConsumerStatefulWidget {
  const CustomerSalonListScreen({super.key});

  @override
  ConsumerState<CustomerSalonListScreen> createState() => _CustomerSalonListScreenState();
}

class _CustomerSalonListScreenState extends ConsumerState<CustomerSalonListScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  Map<String, dynamic> _filters = {};
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  String _sortBy = 'rating'; // Default sort by rating
  bool _isGridView = false; // Default to list view

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salonsProvider.notifier).loadSalons();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salonsState = ref.watch(salonsProvider);
    final salons = salonsState.salons;

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
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_back, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'All Salons',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _showFilterSheet,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.filter_list, color: Colors.white),
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

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: custom.SearchBar(
                  controller: _searchController,
                  hint: 'Search salons, services...',
                  onChanged: (value) {
                    // Implement search functionality
                    ref.read(salonsProvider.notifier).loadSalons(
                      filters: SalonFilters(search: value),
                    );
                  },
                ),
              ),
            ),

            // Sort and View Options
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        underline: Container(),
                        items: const [
                          DropdownMenuItem(value: 'rating', child: Text('Sort by Rating')),
                          DropdownMenuItem(value: 'distance', child: Text('Sort by Distance')),
                          DropdownMenuItem(value: 'price', child: Text('Sort by Price')),
                          DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                          _sortSalons();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                      icon: Icon(
                        _isGridView ? Icons.view_list : Icons.grid_view,
                        color: AppTheme.primaryMauve,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Salon Count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '${salons.length} salons found',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Salon List
            if (salonsState.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: LottieLoader(
                    assetPath: 'assets/lottie/loading.json',
                    message: 'Finding the best salons...',
                  ),
                ),
              )
            else if (salonsState.error != null)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          salonsState.error!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(salonsProvider.notifier).loadSalons();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (salons.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No salons found',
                          style: AppTheme.heading3.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final salon = salons[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _isGridView
                          ? SizedBox(
                              height: 200,
                              child: SalonCard(
                                salon: salon,
                                onTap: () {
                                  context.go('/salon-detail', extra: salon);
                                },
                              ),
                            )
                          : SalonListCard(
                              salon: salon,
                              onTap: () {
                                context.go('/salon-detail', extra: salon);
                              },
                            ),
                    );
                  },
                  childCount: salons.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: () {
                context.go('/customer-map');
              },
              backgroundColor: AppTheme.primaryMauve,
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text(
                'View on Map',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
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
            currentIndex: 0, // Salon list is part of home section
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

  void _sortSalons() {
    // Implement sorting logic
    // This would be handled by the salons provider
    ref.read(salonsProvider.notifier).loadSalons();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialFilters: _filters,
        onFiltersApplied: (filters) {
          setState(() {
            _filters = filters;
          });
          // Apply filters to salon list
          ref.read(salonsProvider.notifier).loadSalons();
        },
      ),
    );
  }
}
