import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 🎨 Color Palette - Food themed (consistent across app)
class AppColors {
  static const primary = Color(0xFFFF6B35); // Warm Orange
  static const secondary = Color(0xFFFFBE0B); // Golden Yellow
  static const accent = Color(0xFFFB5607); // Vibrant Red-Orange
  static const dark = Color(0xFF2D3142); // Dark Blue-Gray
  static const light = Color(0xFFFFFBF0); // Cream White
  static const success = Color(0xFF06A77D); // Fresh Green
}

class CreateRecipePage extends StatefulWidget {
  final String? recipeId;
  final Map<String, dynamic>? initialData;

  const CreateRecipePage({super.key, this.recipeId, this.initialData});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  String? _selectedMealType;
  String _username = "";
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;

  final CollectionReference recipes = FirebaseFirestore.instance.collection(
    'recipes',
  );

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _recipeNameController.text = (d['name'] ?? '').toString();
      _ingredientsController.text = (d['ingredients'] ?? '').toString();
      _instructionsController.text = (d['instructions'] ?? '').toString();
      _selectedMealType = (d['mealType'] ?? '').toString().isNotEmpty
          ? (d['mealType']?.toString())
          : null;
      _imageUrl = (d['imageUrl'] ?? '').toString().isNotEmpty
          ? (d['imageUrl']?.toString())
          : null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<String?> _uploadImageToImgBB(File imageFile) async {
    try {
      // ImgBB API Key (Free tier: 5000 uploads/month)
      // Get your own key from https://api.imgbb.com/
      // REPLACE THIS WITH YOUR OWN API KEY:
      const String apiKey = 'de22de3b30c018cb74518c264f60cfb9';

      // Show uploading status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Uploading image...'),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 10),
          ),
        );
      }

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('📤 Starting image upload to ImgBB...');
      print('📦 Image size: ${bytes.length} bytes');

      final response = await http
          .post(
            Uri.parse('https://api.imgbb.com/1/upload'),
            body: {'key': apiKey, 'image': base64Image},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Upload timeout - Check your internet connection',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final imageUrl = jsonData['data']['url'] as String;
        print('✅ Image uploaded successfully: $imageUrl');

        // Hide uploading snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        return imageUrl;
      } else {
        final errorBody = response.body;
        print('❌ Upload failed: $errorBody');
        throw Exception(
          'Failed to upload image: ${response.statusCode}\n$errorBody',
        );
      }
    } catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageFile = null;
      _imageUrl = null;
    });
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;

          String capitalize(String s) =>
              s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : "";

          setState(() {
            _username =
                "${capitalize(data['firstName'])} ${capitalize(data['lastName'])}";
          });
        }
      }
    } catch (e) {
      setState(() {
        _username = "Unknown User";
      });
    }
  }

  Future<void> addRecipe() async {
    if (_recipeNameController.text.isEmpty ||
        _selectedMealType == null ||
        _ingredientsController.text.isEmpty ||
        _instructionsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all fields"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      setState(() => _isUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("User not logged in"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _isUploading = false);
        return;
      }

      // Upload image if a new one was selected
      String? uploadedImageUrl = _imageUrl;
      if (_imageFile != null) {
        uploadedImageUrl = await _uploadImageToImgBB(_imageFile!);
      }

      if (widget.recipeId != null) {
        final docRef = recipes.doc(widget.recipeId);
        await docRef.update({
          'name': _recipeNameController.text,
          'mealType': _selectedMealType,
          'ingredients': _ingredientsController.text,
          'instructions': _instructionsController.text,
          'imageUrl': uploadedImageUrl ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        final docRef = recipes.doc();
        final recipeId = docRef.id;

        await docRef.set({
          'recipeId': recipeId,
          'userId': user.uid,
          'name': _recipeNameController.text,
          'mealType': _selectedMealType,
          'ingredients': _ingredientsController.text,
          'instructions': _instructionsController.text,
          'imageUrl': uploadedImageUrl ?? '',
          'postedBy': _username,
          'username': _username,
          'likes': <String, dynamic>{},
          'saves': <String, dynamic>{},
          'commentsCount': 0,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      setState(() => _isUploading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                widget.recipeId != null
                    ? "Recipe updated"
                    : "Recipe added successfully",
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add recipe: $error"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _recipeNameController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              widget.recipeId != null ? "Edit Recipe" : "Share Recipe",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 50,
                        height: 20,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            "Post",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
              onPressed: _isUploading ? null : addRecipe,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✨ Enhanced Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username.isEmpty ? "Loading..." : _username,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.public,
                                size: 14,
                                color: AppColors.dark.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Everyone",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.dark.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✨ Recipe Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recipe Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recipe Name Field
                    TextField(
                      controller: _recipeNameController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.restaurant_menu,
                          color: AppColors.primary,
                        ),
                        labelText: "Recipe Name",
                        labelStyle: TextStyle(
                          color: AppColors.dark.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: AppColors.light,
                        // Remove border, use subtle colored underline
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Image Upload Section
                    Text(
                      "Recipe Image (Optional)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_imageFile != null || _imageUrl != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _imageFile != null
                                ? Image.file(
                                    _imageFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _imageUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: AppColors.light,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: AppColors.dark.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _removeImage,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 60,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to add image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Make your recipe more appetizing!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.dark.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Meal Type Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.fastfood,
                          color: AppColors.primary,
                        ),
                        labelText: "Meal Type",
                        labelStyle: TextStyle(
                          color: AppColors.dark.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: AppColors.light,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      value: _selectedMealType,
                      items: [
                        DropdownMenuItem(
                          value: "Breakfast",
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_sunny,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              const Text("Breakfast"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Lunch",
                          child: Row(
                            children: [
                              Icon(
                                Icons.lunch_dining,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text("Lunch"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Dinner",
                          child: Row(
                            children: [
                              Icon(
                                Icons.dinner_dining,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              const Text("Dinner"),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedMealType = value),
                    ),
                    const SizedBox(height: 18),

                    // Ingredients Field
                    TextField(
                      controller: _ingredientsController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.list_alt, color: AppColors.primary),
                        ),
                        labelText: "Ingredients",
                        labelStyle: TextStyle(
                          color: AppColors.dark.withOpacity(0.6),
                        ),
                        hintText: "e.g., 2 cups flour, 1 egg, 1 tsp salt...",
                        hintStyle: TextStyle(
                          color: AppColors.dark.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: AppColors.light,
                        alignLabelWithHint: true,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Instructions Field
                    TextField(
                      controller: _instructionsController,
                      maxLines: 7,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Icon(
                            Icons.menu_book,
                            color: AppColors.primary,
                          ),
                        ),
                        labelText: "Instructions",
                        labelStyle: TextStyle(
                          color: AppColors.dark.withOpacity(0.6),
                        ),
                        hintText: "Step-by-step cooking instructions...",
                        hintStyle: TextStyle(
                          color: AppColors.dark.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: AppColors.light,
                        alignLabelWithHint: true,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Sharing this recipe makes it discoverable by all FoodBook users.",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.dark.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
