import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:html' as html;
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

  final List<String> _sampleImages = [
    'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
    'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400',
    'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400',
    'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400',
    'https://images.unsplash.com/photo-1582095133179-bfd08e2fc75b?w=400',
    'https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=400',
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
    } else {
      _selectedImageUrl = _sampleImages[0];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSelector(),
                    const SizedBox(height: 20),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildPriceField(),
                    const SizedBox(height: 16),
                    _buildDurationDropdown(),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 20),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryMauve.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            widget.service != null ? Icons.edit : Icons.add_circle,
            color: AppTheme.primaryMauve,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            widget.service != null ? 'Edit Service' : 'Add New Service',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.primaryMauve),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _sampleImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _sampleImages.length) {
                return _buildAddImageButton();
              }
              
              final imageUrl = _sampleImages[index];
              final isSelected = _selectedImageUrl == imageUrl && _selectedImageBytes == null;
              
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedImageUrl = imageUrl;
                  _selectedImageBytes = null;
                  _selectedImageFileName = null;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryMauve : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppTheme.primaryMauve.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.primaryMauve,
                          child: const Icon(Icons.image, color: Colors.white, size: 30),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Show selected uploaded image
        if (_selectedImageBytes != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryMauve, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryMauve,
            width: 2,
            style: BorderStyle.solid,
          ),
          color: AppTheme.primaryMauve.withOpacity(0.1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: AppTheme.primaryMauve,
              size: 30,
            ),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                color: AppTheme.primaryMauve,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      // For web, use HTML file input
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          
          reader.onLoadEnd.listen((e) {
            final bytes = reader.result as List<int>;
            setState(() {
              _selectedImageBytes = Uint8List.fromList(bytes);
              _selectedImageFileName = file.name;
              _selectedImageUrl = null; // Clear sample image selection
            });
          });
          
          reader.readAsArrayBuffer(file);
        }
      });
    } catch (e) {
      print('Image picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image picker not available on web. Please use sample images.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Service Name',
        prefixIcon: const Icon(Icons.business_center, color: AppTheme.primaryMauve),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryMauve, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter service name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        prefixIcon: const Icon(Icons.description, color: AppTheme.primaryMauve),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryMauve, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter service description';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Price (\$)',
        prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryMauve),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryMauve, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter service price';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid price';
        }
        return null;
      },
    );
  }

  Widget _buildDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDuration,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryMauve),
              items: _durations.map((duration) {
                return DropdownMenuItem<String>(
                  value: duration,
                  child: Text('$duration minutes'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDuration = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryMauve),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _saveService,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryMauve,
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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                widget.service != null ? 'Update Service' : 'Add Service',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _saveService() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        final authState = ref.read(authProvider);
        if (authState.user == null) {
          throw Exception('User not authenticated');
        }

        // Get or create salon for the owner
        String salonId;
        try {
          print('Getting salon for user: ${authState.user!.id}');
          final salon = await AppApi.getSalonByOwnerId(authState.user!.id);
          print('Salon result: $salon');
          
          if (salon != null) {
            salonId = salon.id;
            print('Using existing salon: $salonId');
          } else {
            print('No salon found, creating new one...');
            // Create a salon for the owner if it doesn't exist
            final newSalon = await AppApi.createSalonForOwner(
              authState.user!.id,
              name: authState.user!.fullName + "'s Salon",
              description: 'Professional salon services',
              address: '123 Main St', // Default address
              phone: authState.user!.phone ?? '',
              email: authState.user!.email,
            );
            salonId = newSalon.id;
            print('Created new salon: $salonId');
          }
        } catch (e) {
          print('Error getting salon: $e');
          throw Exception('Failed to get salon: $e');
        }

        // Upload image if selected
        String? imageUrl = _selectedImageUrl;
        if (_selectedImageBytes != null && _selectedImageFileName != null) {
          try {
            imageUrl = await AppApi.uploadServiceImage(
              authState.user!.id,
              _selectedImageBytes!,
              _selectedImageFileName!,
            );
          } catch (e) {
            throw Exception('Failed to upload image: $e');
          }
        }

        final service = ServiceModel(
          id: widget.service?.id ?? const Uuid().v4(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          durationMinutes: int.parse(_selectedDuration),
          category: _selectedCategory,
          imageUrl: imageUrl,
          salonId: salonId,
          createdAt: widget.service?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        widget.onSave(service);
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.service != null 
                  ? 'Service updated successfully!' 
                  : 'Service added successfully!'
            ),
            backgroundColor: AppTheme.primaryMauve,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
