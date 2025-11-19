import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../bloc/seller/seller_bloc.dart';
import '../../bloc/seller/seller_event.dart';
import '../../bloc/seller/seller_state.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _locationController;
  late String _selectedCategory;
  late String _selectedUnit;
  List<XFile> _newImages = []; // New images to add
  List<String> _existingImageUrls = []; // Existing images from server

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _quantityController =
        TextEditingController(text: widget.product.quantity.toString());
    _locationController = TextEditingController(text: widget.product.location);
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
    _existingImageUrls = List<String>.from(widget.product.imagePaths);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // SellerBloc should be provided via BlocProvider.value from parent
    // If not available, create a fallback
    return BlocBuilder<SellerBloc, SellerState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Product'),
            backgroundColor: Colors.green,
          ),
          body: BlocListener<SellerBloc, SellerState>(
            listener: (context, state) {
              if (state is ProductUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true); // Return true to indicate update
              } else if (state is SellerError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter product name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter description' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'fresh_produce',
                            child: Text('Fresh Produce')),
                        DropdownMenuItem(
                            value: 'livestock_poultry',
                            child: Text('Livestock & Poultry')),
                        DropdownMenuItem(
                            value: 'seeds_fertilizers',
                            child: Text('Seeds & Fertilizers')),
                        DropdownMenuItem(
                            value: 'farm_tools', child: Text('Farm Tools')),
                        DropdownMenuItem(
                            value: 'processed_goods',
                            child: Text('Processed Goods')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Use Wrap or Column for smaller screens to prevent overflow
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // On smaller screens (< 600px), stack vertically
                        if (constraints.maxWidth < 600) {
                          return Column(
                            children: [
                              TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter price'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _quantityController,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) => value!.isEmpty
                                          ? 'Please enter quantity'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedUnit,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'piece',
                                            child: Text('Piece')),
                                        DropdownMenuItem(
                                            value: 'pack', child: Text('Pack')),
                                        DropdownMenuItem(
                                            value: 'kg', child: Text('Kg')),
                                        DropdownMenuItem(
                                            value: 'liter',
                                            child: Text('Liter')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedUnit = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        // On larger screens, use horizontal layout
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter price'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter quantity'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'piece', child: Text('Piece')),
                                  DropdownMenuItem(
                                      value: 'pack', child: Text('Pack')),
                                  DropdownMenuItem(
                                      value: 'kg', child: Text('Kg')),
                                  DropdownMenuItem(
                                      value: 'liter', child: Text('Liter')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedUnit = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter location' : null,
                    ),
                    const SizedBox(height: 16),

                    // Existing images
                    if (_existingImageUrls.isNotEmpty) ...[
                      const Text(
                        'Current Images',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImageUrls.length,
                          itemBuilder: (context, index) {
                            final imageUrl = _existingImageUrls[index];
                            final fullUrl = !imageUrl.startsWith('http')
                                ? '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl'
                                : imageUrl;

                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: fullUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _removeExistingImage(index),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Add new images button
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add More Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),

                    // New images preview
                    if (_newImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Stack(
                                children: [
                                  Image.file(
                                    File(_newImages[index].path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () => _removeNewImage(index),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    BlocBuilder<SellerBloc, SellerState>(
                      builder: (context, state) {
                        if (state is SellerLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final updates = <String, dynamic>{
                                'name': _nameController.text.trim(),
                                'description':
                                    _descriptionController.text.trim(),
                                'category': _selectedCategory,
                                'price': double.parse(_priceController.text),
                                'quantity': int.parse(_quantityController.text),
                                'unit': _selectedUnit,
                                'location': _locationController.text.trim(),
                              };

                              // Always send the current state of image_paths
                              // This includes remaining existing images (after removals)
                              // New images will be added by the backend
                              updates['image_paths'] =
                                  List<String>.from(_existingImageUrls);

                              context.read<SellerBloc>().add(
                                    UpdateProductEvent(
                                      productId: widget.product.productId,
                                      updates: updates,
                                      imagePaths: _newImages.isNotEmpty
                                          ? _newImages
                                              .map((e) => e.path)
                                              .toList()
                                          : null,
                                    ),
                                  );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Update Product'),
                        );
                      },
                    ),
                    // Add extra bottom padding to prevent overflow when keyboard is open
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
