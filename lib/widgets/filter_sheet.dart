import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class FilterSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersApplied;
  final Map<String, dynamic> initialFilters;

  const FilterSheet({
    super.key,
    required this.onFiltersApplied,
    this.initialFilters = const {},
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Filter state
  double _minPrice = 0;
  double _maxPrice = 200;
  double _minRating = 0;
  List<String> _selectedCategories = [];
  List<String> _selectedServices = [];
  String _sortBy = 'distance';

  final List<String> _categories = [
    'Hair Salon',
    'Nail Salon',
    'Spa',
    'Barbershop',
    'Beauty Salon',
    'Massage',
  ];

  final List<String> _services = [
    'Haircut',
    'Hair Color',
    'Manicure',
    'Pedicure',
    'Facial',
    'Massage',
    'Eyebrow',
    'Makeup',
  ];

  final List<String> _sortOptions = [
    'distance',
    'rating',
    'price_low',
    'price_high',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Initialize with provided filters
    _minPrice = widget.initialFilters['minPrice']?.toDouble() ?? 0;
    _maxPrice = widget.initialFilters['maxPrice']?.toDouble() ?? 200;
    _minRating = widget.initialFilters['minRating']?.toDouble() ?? 0;
    _selectedCategories = List<String>.from(widget.initialFilters['categories'] ?? []);
    _selectedServices = List<String>.from(widget.initialFilters['services'] ?? []);
    _sortBy = widget.initialFilters['sortBy'] ?? 'distance';

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _applyFilters() {
    final filters = {
      'minPrice': _minPrice,
      'maxPrice': _maxPrice,
      'minRating': _minRating,
      'categories': _selectedCategories,
      'services': _selectedServices,
      'sortBy': _sortBy,
    };
    
    widget.onFiltersApplied(filters);
    _close();
  }

  void _resetFilters() {
    setState(() {
      _minPrice = 0;
      _maxPrice = 200;
      _minRating = 0;
      _selectedCategories.clear();
      _selectedServices.clear();
      _sortBy = 'distance';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge),
                  topRight: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: AppTheme.spacing12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Row(
                      children: [
                        Text(
                          'Filters',
                          style: AppTheme.heading2,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetFilters,
                          child: Text(
                            'Reset',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryMauve,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _close,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price Range
                          _buildSection(
                            title: 'Price Range',
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('\$${_minPrice.toInt()}'),
                                    Text('\$${_maxPrice.toInt()}'),
                                  ],
                                ),
                                RangeSlider(
                                  values: RangeValues(_minPrice, _maxPrice),
                                  min: 0,
                                  max: 200,
                                  divisions: 20,
                                  onChanged: (values) {
                                    setState(() {
                                      _minPrice = values.start;
                                      _maxPrice = values.end;
                                    });
                                  },
                                  activeColor: AppTheme.primaryMauve,
                                ),
                              ],
                            ),
                          ),
                          
                          // Rating
                          _buildSection(
                            title: 'Minimum Rating',
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${_minRating.toStringAsFixed(1)} ⭐'),
                                  ],
                                ),
                                Slider(
                                  value: _minRating,
                                  min: 0,
                                  max: 5,
                                  divisions: 10,
                                  onChanged: (value) {
                                    setState(() {
                                      _minRating = value;
                                    });
                                  },
                                  activeColor: AppTheme.primaryMauve,
                                ),
                              ],
                            ),
                          ),
                          
                          // Categories
                          _buildSection(
                            title: 'Categories',
                            child: Wrap(
                              spacing: AppTheme.spacing8,
                              runSpacing: AppTheme.spacing8,
                              children: _categories.map((category) {
                                final isSelected = _selectedCategories.contains(category);
                                return FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedCategories.add(category);
                                      } else {
                                        _selectedCategories.remove(category);
                                      }
                                    });
                                  },
                                  selectedColor: AppTheme.primaryMauve.withOpacity(0.2),
                                  checkmarkColor: AppTheme.primaryMauve,
                                  backgroundColor: AppTheme.surfaceLight,
                                );
                              }).toList(),
                            ),
                          ),
                          
                          // Services
                          _buildSection(
                            title: 'Services',
                            child: Wrap(
                              spacing: AppTheme.spacing8,
                              runSpacing: AppTheme.spacing8,
                              children: _services.map((service) {
                                final isSelected = _selectedServices.contains(service);
                                return FilterChip(
                                  label: Text(service),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedServices.add(service);
                                      } else {
                                        _selectedServices.remove(service);
                                      }
                                    });
                                  },
                                  selectedColor: AppTheme.primaryMauve.withOpacity(0.2),
                                  checkmarkColor: AppTheme.primaryMauve,
                                  backgroundColor: AppTheme.surfaceLight,
                                );
                              }).toList(),
                            ),
                          ),
                          
                          // Sort By
                          _buildSection(
                            title: 'Sort By',
                            child: Column(
                              children: _sortOptions.map((option) {
                                return RadioListTile<String>(
                                  title: Text(_getSortOptionLabel(option)),
                                  value: option,
                                  groupValue: _sortBy,
                                  onChanged: (value) {
                                    setState(() {
                                      _sortBy = value!;
                                    });
                                  },
                                  activeColor: AppTheme.primaryMauve,
                                  contentPadding: EdgeInsets.zero,
                                );
                              }).toList(),
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing24),
                        ],
                      ),
                    ),
                  ),
                  
                  // Apply Button
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: AppTheme.glassButton(
                      text: 'Apply Filters',
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.heading3,
        ),
        const SizedBox(height: AppTheme.spacing12),
        child,
        const SizedBox(height: AppTheme.spacing24),
      ],
    );
  }

  String _getSortOptionLabel(String option) {
    switch (option) {
      case 'distance':
        return 'Distance';
      case 'rating':
        return 'Rating';
      case 'price_low':
        return 'Price: Low to High';
      case 'price_high':
        return 'Price: High to Low';
      default:
        return option;
    }
  }
}
