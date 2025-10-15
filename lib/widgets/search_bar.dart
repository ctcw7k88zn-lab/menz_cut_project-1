import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'glass_card.dart';

class SearchBar extends StatefulWidget {
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showFilterButton;
  final VoidCallback? onFilterTap;

  const SearchBar({
    super.key,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.showFilterButton = false,
    this.onFilterTap,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.radiusLarge,
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              readOnly: widget.readOnly,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hint ?? 'Search salons, services...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textLight,
                ),
                prefixIcon: widget.prefixIcon ?? Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing16,
                ),
              ),
            ),
          ),
          
          // Filter button
          if (widget.showFilterButton) ...[
            Container(
              width: 1,
              height: 32,
              color: AppTheme.textLight.withOpacity(0.3),
            ),
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Icon(
                  Icons.tune,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FilterChipRow extends StatelessWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final ValueChanged<List<String>> onSelectionChanged;
  final bool allowMultipleSelection;
  final String? label;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.allowMultipleSelection = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacing8),
                child: FilterChip(
                  label: Text(
                    option,
                    style: AppTheme.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (allowMultipleSelection) {
                      final newSelection = List<String>.from(selectedOptions);
                      if (selected) {
                        newSelection.add(option);
                      } else {
                        newSelection.remove(option);
                      }
                      onSelectionChanged(newSelection);
                    } else {
                      onSelectionChanged(selected ? [option] : []);
                    }
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: AppTheme.primaryMauve,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryMauve : AppTheme.textLight,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryMauve 
              : AppTheme.primaryMauve.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryMauve 
                : AppTheme.primaryMauve.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.primaryMauve,
              ),
              const SizedBox(width: AppTheme.spacing4),
            ],
            Text(
              category,
              style: AppTheme.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.primaryMauve,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriceRangeSlider extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final double currentMinPrice;
  final double currentMaxPrice;
  final ValueChanged<(double, double)> onChanged;

  const PriceRangeSlider({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.currentMinPrice,
    required this.currentMaxPrice,
    required this.onChanged,
  });

  @override
  State<PriceRangeSlider> createState() => _PriceRangeSliderState();
}

class _PriceRangeSliderState extends State<PriceRangeSlider> {
  late double _currentMinPrice;
  late double _currentMaxPrice;

  @override
  void initState() {
    super.initState();
    _currentMinPrice = widget.currentMinPrice;
    _currentMaxPrice = widget.currentMaxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        // Price display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${_currentMinPrice.toInt()}',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryMauve,
              ),
            ),
            Text(
              '\$${_currentMaxPrice.toInt()}',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryMauve,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        
        // Slider
        RangeSlider(
          values: RangeValues(_currentMinPrice, _currentMaxPrice),
          min: widget.minPrice,
          max: widget.maxPrice,
          divisions: ((widget.maxPrice - widget.minPrice) / 10).round(),
          activeColor: AppTheme.primaryMauve,
          inactiveColor: AppTheme.textLight.withOpacity(0.3),
          onChanged: (values) {
            setState(() {
              _currentMinPrice = values.start;
              _currentMaxPrice = values.end;
            });
            widget.onChanged((_currentMinPrice, _currentMaxPrice));
          },
        ),
      ],
    );
  }
}
