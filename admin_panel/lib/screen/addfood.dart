import 'dart:io';
import 'package:admin_panel/utils/supabase_clients.dart';
import 'package:admin_panel/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class AdminAddFoodPage extends StatefulWidget {
  const AdminAddFoodPage({super.key});

  @override
  State<AdminAddFoodPage> createState() => _AdminAddFoodPageState();
}

class _AdminAddFoodPageState extends State<AdminAddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  bool _availability = true;
  File? _selectedImage;
  bool _isLoading = false;
  int _descCharCount = 0;
  String? _selectedCategory;
  List<String> _categories = [];

  final SupabaseService _service = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _descCharCount = _descController.text.length;
  }

  Future<void> _loadCategories() async {
    final fetched = await _service.fetchCategories();
    setState(() {
      _categories = fetched;
    });
  }
  

  Future<void> _showCreateCategoryDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey[200],
            title: const Text("Add New Category"),
            content: Stack(
              children: [
                TextFormField(
                  controller: controller, // use this local controller!
                  maxLength: 60,
                  maxLines: 2,
                  onChanged:
                      (val) => setState(() => _descCharCount = val.length),
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
                    "$_descCharCount/60",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Cancel",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('✅ "$name" added')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚠️ Category already exists')),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final uuid = const Uuid().v4();
      final ext = path.extension(imageFile.path);
      final filePath = '$uuid$ext';

      await Supabase.instance.client.storage
          .from('restaurant.menu')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('restaurant.menu')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) {
         if (!mounted) return; 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to upload image')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    final foodData = {
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'description': _descController.text.trim(),
      'image_url': imageUrl,
      'availability': _availability,
      'category': _selectedCategory ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await Supabase.instance.client.from('food').insert(foodData);
       if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Food item added successfully!')),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedImage = null;
        _selectedCategory = null;
        _descCharCount = 0;
      });
    } catch (e) {
      debugPrint('❌ Error saving food: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving food item: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller, {
    String? hint,
    IconData? icon,
    Color? iconColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(196, 147, 156, 157),
            ),
            prefixIcon: icon != null ? Icon(icon, color: iconColor) : null,

            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator:
              (val) =>
                  val!.isEmpty ? 'Please enter $label'.toLowerCase() : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Food',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Theme.of(context).bottomAppBarTheme.color,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabeledField(
                    "Food Name",
                    _nameController,
                    hint: "Please type food name..",
                    icon: Icons.fastfood,
                    iconColor: AppTheme.defaultIconColor,
                  ),
                  const SizedBox(height: 16),
                  _buildLabeledField(
                    "Price",
                    _priceController,
                    hint: "Please add price..",
                    icon: Icons.payments,
                    iconColor: AppTheme.defaultIconColor,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Description",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      TextFormField(
                        controller: _descController,
                        maxLength: 500,
                        maxLines: 5,
                        onChanged: (val) {
                          debugPrint(
                            'desc changed: "$val" length: ${val.length}',
                          );
                          setState(() => _descCharCount = val.length);
                        },

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
                          "$_descCharCount/300",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Category",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 250,
                    child: DropdownButtonFormField<String>(
                      borderRadius: BorderRadius.circular(16),
                      value: _selectedCategory,
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
                          // no setState here to keep previous value
                        } else {
                          setState(() => _selectedCategory = val);
                        }
                      },
                      validator:
                          (val) =>
                              val == null || val == '__create_new__'
                                  ? 'Please select a category'
                                  : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Available",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      value: _availability,
                      activeColor: AppTheme.defaultIconColor,
                      inactiveThumbColor: AppTheme.defaultIconColor,
                      inactiveTrackColor: Colors.white,
                      onChanged: (val) => setState(() => _availability = val),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _selectedImage != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, height: 160),
                      )
                      : Text(
                        "No image selected",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image_outlined, color: Colors.white),
                    label: const Text(
                      "Pick Image",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.defaultIconColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppTheme.defaultIconColor,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Add Food",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
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
