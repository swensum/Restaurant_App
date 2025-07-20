import 'dart:io';
import 'package:admin_panel/utils/supabase_clients.dart';
import 'package:admin_panel/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';

class EditFoodPage extends StatefulWidget {
  final Map<String, dynamic> foodItem;

  const EditFoodPage({super.key, required this.foodItem});

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final SupabaseService _supabaseService = SupabaseService();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late bool _availability;

  String? _imageUrl;
  File? _newImageFile;
  String? _selectedCategory;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  int _descCharCount = 0;
  List<String> _categories = [];
  final SupabaseService _service = SupabaseService();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.foodItem['name']);
    _priceController = TextEditingController(text: widget.foodItem['price'].toString());
    _descriptionController = TextEditingController(text: widget.foodItem['description'] ?? '');
    _imageUrl = widget.foodItem['image_url'];
    _descCharCount = _descriptionController.text.length;
    _availability = widget.foodItem['availability'] ?? true;
    _selectedCategory = widget.foodItem['category'];

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final fetched = await _service.fetchCategories();

    // Combine fetched and selected category if missing, then remove duplicates
    final combined = List<String>.from(fetched);
    if (_selectedCategory != null && !combined.contains(_selectedCategory)) {
      combined.insert(0, _selectedCategory!);
    }

    setState(() {
      _categories = combined.toSet().toList(); // Remove duplicates
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final controller = TextEditingController();
    int localDescCharCount = 0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[200],
          title: const Text("Add New Category"),
          content: Stack(
            children: [
              TextFormField(
                controller: controller,
                maxLength: 60,
                maxLines: 2,
                onChanged: (val) => setDialogState(() => localDescCharCount = val.length),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Please add description..",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(196, 147, 156, 157),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
              ),
              Positioned(
                bottom: 6,
                right: 12,
                child: Text(
                  "$localDescCharCount/60",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: Theme.of(context).textTheme.bodyMedium),
            ),
            ElevatedButton(
              child: const Text("Add", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final added = await _service.addCategory(name);
                if (!mounted) return;
                Navigator.pop(context);

                if (added) {
                  await _loadCategories();
                  setState(() => _selectedCategory = name);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ "$name" added')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ Category already exists')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateFoodItem() async {
    if (!_formKey.currentState!.validate()) return;

    final oldData = widget.foodItem;

    final name = _nameController.text.trim();
    final category = _selectedCategory ?? '';
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();
    final availability = _availability;

    final price = double.tryParse(priceText) ?? 0.0;

    final hasChanges = name != oldData['name'] ||
        category != oldData['category'] ||
        price != (oldData['price'] as num?)?.toDouble() ||
        description != (oldData['description'] ?? '') ||
        availability != (oldData['availability'] ?? true) ||
        _newImageFile != null;

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to update.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? imageUrl = _imageUrl;

    try {
      if (_newImageFile != null) {
        if (_imageUrl != null && _imageUrl!.isNotEmpty) {
          final deleted = await _supabaseService.deleteImageByUrl(_imageUrl!);
          if (!deleted) debugPrint('⚠️ Old image not deleted.');
        }

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(_newImageFile!.path)}';
        final mimeType = lookupMimeType(_newImageFile!.path) ?? 'image/jpeg';

        final uploadedUrl = await _supabaseService.uploadImageFile(_newImageFile!, fileName, mimeType);
        if (uploadedUrl == null) throw Exception("Image upload failed");

        imageUrl = uploadedUrl;
      }

      final updatedData = {
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'availability': availability,
        'image_url': imageUrl,
      };

      debugPrint('📦 Updating food item ID: ${oldData['id']}');
      debugPrint('➡️ With data: $updatedData');

      final success = await _supabaseService.updateFoodItem(oldData['id'], updatedData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Food item updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Update failed");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _imagePreview() {
    return GestureDetector(
      onTap: _pickImageFromGallery,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_newImageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _newImageFile!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else if (_imageUrl != null && _imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text('Tap to add image', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Material(
                color: Theme.of(context).bottomAppBarTheme.color,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickImageFromGallery,
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.edit, color: AppTheme.defaultIconColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        title: const Text('Edit Food Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _updateFoodItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 55),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imagePreview(),
              const SizedBox(height: 24),

              // Name Field
              Text('Food Name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.fastfood,  color: AppTheme.defaultIconColor,),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Category Field
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  borderRadius: BorderRadius.circular(16),
                  value: _categories.contains(_selectedCategory) ? _selectedCategory : null,
                  isExpanded: true,
                  hint: const Text(
                    "Please select category...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(196, 147, 156, 157),
                    ),
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.category,
                      color: AppTheme.defaultIconColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    ..._categories.map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: '__create_new__',
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Create New",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) async {
                    if (val == '__create_new__') {
                      await _showCreateCategoryDialog();
                    } else {
                      setState(() => _selectedCategory = val);
                    }
                  },
                  validator: (val) => val == null || val == '__create_new__' ? 'Please select a category' : null,
                ),
              ),
              const SizedBox(height: 20),

              // Price Field
              Text('Price', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                style: const TextStyle(fontSize: 16),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Price',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.payments,color:  AppTheme.defaultIconColor,),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              Text('Description', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Stack(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: 500,
                    maxLines: 5,
                    onChanged: (val) => setState(() => _descCharCount = val.length),
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "Please add description..",
                      hintStyle: TextStyle(fontSize: 16, color: Color.fromARGB(196, 147, 156, 157)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 12,
                    child: Text("$_descCharCount/300", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Availability Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Available', style: Theme.of(context).textTheme.titleMedium),
                  Switch(
                    value: _availability,
                    onChanged: (val) => setState(() => _availability = val),
                    activeColor: AppTheme.defaultIconColor,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _updateFoodItem,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.defaultIconColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
