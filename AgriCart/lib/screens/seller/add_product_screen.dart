import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../bloc/seller/seller_bloc.dart';
import '../../bloc/seller/seller_event.dart';
import '../../bloc/seller/seller_state.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final String sellerId;

  const AddProductScreen({super.key, required this.sellerId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'fresh_produce';
  String _selectedUnit = 'piece';
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

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
        _selectedImages = images;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerBloc(apiService: ApiService()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Product'),
          backgroundColor: Colors.green,
        ),
        body: BlocListener<SellerBloc, SellerState>(
          listener: (context, state) {
            if (state is ProductCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product created successfully!')),
              );
              Navigator.pop(context);
            } else if (state is SellerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          value: 'fresh_produce', child: Text('Fresh Produce')),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter price' : null,
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
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter quantity' : null,
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
                            DropdownMenuItem(value: 'piece', child: Text('Piece')),
                            DropdownMenuItem(value: 'kg', child: Text('Kg')),
                            DropdownMenuItem(value: 'liter', child: Text('Liter')),
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
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Select Images'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.file(
                              File(_selectedImages[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
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
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final product = Product(
                              productId: '',
                              sellerId: widget.sellerId,
                              name: _nameController.text.trim(),
                              description: _descriptionController.text.trim(),
                              category: _selectedCategory,
                              price: double.parse(_priceController.text),
                              quantity: int.parse(_quantityController.text),
                              unit: _selectedUnit,
                              location: _locationController.text.trim(),
                              imagePaths: [],
                              isActive: true,
                            );

                            context.read<SellerBloc>().add(
                                  CreateProductEvent(
                                    product: product,
                                    imagePaths:
                                        _selectedImages.map((e) => e.path).toList(),
                                  ),
                                );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Create Product'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

