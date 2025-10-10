import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String _username = ""; // will hold firstName + lastName

  final CollectionReference recipes = FirebaseFirestore.instance.collection(
    'recipes',
  );

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    // If initialData provided (editing), prefill fields after a short delay
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _recipeNameController.text = (d['name'] ?? '').toString();
      _ingredientsController.text = (d['ingredients'] ?? '').toString();
      _instructionsController.text = (d['instructions'] ?? '').toString();
      _selectedMealType = (d['mealType'] ?? '').toString().isNotEmpty
          ? (d['mealType']?.toString())
          : null;
    }
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
      // fallback if fetch fails
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      // If recipeId provided, update existing doc; otherwise create new
      if (widget.recipeId != null) {
        final docRef = recipes.doc(widget.recipeId);
        await docRef.update({
          'name': _recipeNameController.text,
          'mealType': _selectedMealType,
          'ingredients': _ingredientsController.text,
          'instructions': _instructionsController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Generate new recipe document
        final docRef = recipes.doc();
        final recipeId = docRef.id; // unique Firestore ID

        await docRef.set({
          'recipeId': recipeId, // stored but not shown
          'userId': user.uid, // stored but not shown
          'name': _recipeNameController.text,
          'mealType': _selectedMealType,
          'ingredients': _ingredientsController.text,
          'instructions': _instructionsController.text,
          'postedBy': _username, // shown in UI
          'username': _username,
          // Initialize interaction fields to avoid null checks elsewhere
          'likes': <String, dynamic>{},
          'saves': <String, dynamic>{},
          'commentsCount': 0,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.recipeId != null
                ? "Recipe updated"
                : "Recipe added successfully",
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add recipe: $error")));
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        title: const Text(
          "Share Recipe",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFFAFAFA),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              onPressed: addRecipe,
              child: const Text(
                "Post",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: const RoundedRectangleBorder(),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Profile row with username
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFD72638),
                      child: Icon(Icons.person, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _username.isEmpty ? "Loading..." : _username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _recipeNameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFFD72638),
                    ),
                    labelText: "Recipe Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.fastfood, color: Color(0xFFD72638)),
                    labelText: "Meal Type",
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedMealType,
                  items: const [
                    DropdownMenuItem(
                      value: "Breakfast",
                      child: Text("Breakfast"),
                    ),
                    DropdownMenuItem(value: "Lunch", child: Text("Lunch")),
                    DropdownMenuItem(value: "Dinner", child: Text("Dinner")),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedMealType = value),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _ingredientsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.list_alt, color: Color(0xFFD72638)),
                    labelText: "Ingredients",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _instructionsController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.menu_book, color: Color(0xFFD72638)),
                    labelText: "Instructions",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
