import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../services/menu_item_service.dart';

class MenuItemFormDialog extends StatefulWidget {
  final MenuItem? menuItem;

  const MenuItemFormDialog({super.key, this.menuItem});

  @override
  State<MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  ItemKind _selectedKind = ItemKind.mainCourse;
  bool _isAvailable = true;
  bool _isLoading = false;

  bool get isEditing => widget.menuItem != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.menuItem!.name;
      _priceController.text = widget.menuItem!.price.toString();
      _descriptionController.text = widget.menuItem!.description ?? '';
      _imageUrlController.text = widget.menuItem!.imageUrl ?? '';
      _selectedKind = widget.menuItem!.kind;
      _isAvailable = widget.menuItem!.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text);
      final description = _descriptionController.text.trim();
      final imageUrl = _imageUrlController.text.trim();

      final response =
          isEditing
              ? await MenuItemService.updateMenuItem(
                widget.menuItem!.id,
                UpdateMenuItemRequest(
                  name: name,
                  kind: _selectedKind,
                  price: price,
                  description: description.isEmpty ? null : description,
                  imageUrl: imageUrl.isEmpty ? null : imageUrl,
                  isAvailable: _isAvailable,
                ),
              )
              : await MenuItemService.createMenuItem(
                CreateMenuItemRequest(
                  name: name,
                  kind: _selectedKind,
                  price: price,
                  description: description.isEmpty ? null : description,
                  imageUrl: imageUrl.isEmpty ? null : imageUrl,
                  isAvailable: _isAvailable,
                ),
              );

      if (mounted) {
        if (response.success) {
          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackBar(response.message ?? 'Operation failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Network error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Menu Item' : 'Add New Menu Item'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter menu item name';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<ItemKind>(
                  value: _selectedKind,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ItemKind.values.map((kind) {
                        return DropdownMenuItem(
                          value: kind,
                          child: Text(kind.displayName),
                        );
                      }).toList(),
                  onChanged:
                      _isLoading
                          ? null
                          : (value) {
                            setState(() {
                              _selectedKind = value!;
                            });
                          },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (₫)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Available'),
                  subtitle: Text(
                    _isAvailable
                        ? 'Item is available'
                        : 'Item is not available',
                  ),
                  value: _isAvailable,
                  onChanged:
                      _isLoading
                          ? null
                          : (value) {
                            setState(() {
                              _isAvailable = value;
                            });
                          },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
