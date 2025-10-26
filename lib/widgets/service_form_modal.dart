import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:typed_data';
import '../config/app_theme.dart';
import '../models/service_model.dart';
import '../providers/auth_provider.dart';
import '../services/app_api.dart';

class ServiceFormModal extends ConsumerStatefulWidget {
  final ServiceModel? service;
  final Function(ServiceModel) onSave;

  const ServiceFormModal({
    super.key,
    this.service,
    required this.onSave,
  });

  @override
  ConsumerState<ServiceFormModal> createState() => _ServiceFormModalState();
}

class _ServiceFormModalState extends ConsumerState<ServiceFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedDuration = '30';
  String _selectedCategory = 'Haircut';
  String? _selectedImageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageFileName;
  bool _isUploading = false;

  final List<String> _durations = ['15', '30', '45', '60', '90', '120'];
  final List<String> _categories = [
    'Haircut',
    'Beard',
    'Styling',
    'Coloring',
    'Facial',
    'Hair Treatment',
    'Massage',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _descriptionController.text = widget.service!.description;
      _priceController.text = widget.service!.price.toString();
      _selectedDuration = widget.service!.durationMinutes.toString();
      _selectedCategory = widget.service!.category;
      _selectedImageUrl = widget.service!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // For now, disable image upload on mobile platforms
    // This can be enhanced later with image_picker package for mobile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image upload feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      final service = ServiceModel(
        id: widget.service?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        durationMinutes: int.parse(_selectedDuration),
        category: _selectedCategory,
        imageUrl: _selectedImageUrl,
        salonId: authState.user!.id,
        isActive: true,
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save service via API
      await AppApi.addService(service);
      
      widget.onSave(service);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.service == null 
                ? 'Service created successfully!' 
                : 'Service updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save service: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  Text(
                    widget.service == null ? 'Add Service' : 'Edit Service',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Service Image
              _buildImageSection(),
              const SizedBox(height: 24),
              
              // Service Name
                    _buildNameField(),
                    const SizedBox(height: 16),
              
              // Service Description
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
              
              // Price and Duration Row
              Row(
                children: [
                  Expanded(child: _buildPriceField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDurationField()),
                ],
              ),
                    const SizedBox(height: 16),
              
              // Category
              _buildCategoryField(),
              const SizedBox(height: 24),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Image',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
                child: Container(
            height: 120,
            width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.primaryMauve.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
                        borderRadius: BorderRadius.circular(12),
              color: AppTheme.primaryMauve.withOpacity(0.05),
            ),
            child: _selectedImageUrl != null || _selectedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _selectedImageBytes != null
                        ? Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                          )
                        : Image.network(
                            _selectedImageUrl!,
                            fit: BoxFit.cover,
          width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          ),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
          Icons.add_photo_alternate_outlined,
          size: 32,
          color: AppTheme.primaryMauve.withOpacity(0.6),
        ),
        const SizedBox(height: 8),
            Text(
          'Tap to add image',
              style: TextStyle(
            color: AppTheme.primaryMauve.withOpacity(0.6),
            fontSize: 14,
              ),
            ),
          ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Service Name',
        hintText: 'e.g., Haircut & Styling',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.content_cut),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a service name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Describe your service...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.description),
        ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        labelText: 'Price (\$)',
        hintText: '0.00',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.attach_money),
        ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a price';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Please enter a valid price';
        }
        return null;
      },
    );
  }

  Widget _buildDurationField() {
    return DropdownButtonFormField<String>(
      value: _selectedDuration,
      decoration: InputDecoration(
        labelText: 'Duration',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        prefixIcon: const Icon(Icons.access_time),
      ),
              items: _durations.map((duration) {
        return DropdownMenuItem(
                  value: duration,
                  child: Text('$duration minutes'),
                );
              }).toList(),
      onChanged: (value) {
                setState(() {
          _selectedDuration = value!;
                });
              },
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        prefixIcon: const Icon(Icons.category),
      ),
              items: _categories.map((category) {
        return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
      onChanged: (value) {
                setState(() {
          _selectedCategory = value!;
                });
              },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
      child: ElevatedButton(
        onPressed: _isUploading ? null : _saveService,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryMauve,
              foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUploading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.service == null ? 'Create Service' : 'Update Service'),
          ),
        ),
      ],
    );
  }
}
