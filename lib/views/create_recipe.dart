import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  String? _selectedMealType;

  final CollectionReference recipes = FirebaseFirestore.instance.collection(
    'recipes',
  );

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
      await recipes.add({
        'name': _recipeNameController.text,
        'mealType': _selectedMealType,
        'ingredients': _ingredientsController.text,
        'instructions': _instructionsController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe added successfully")),
      );

      Navigator.pop(context); // go back after posting
    } catch (error) {
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
                backgroundColor: const Color(0xFFF2A541),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              onPressed: addRecipe, // <-- Call the function to save recipe
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
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFD72638),
                      child: Icon(Icons.person, size: 32, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Your name",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF1C1C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _recipeNameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFFD72638),
                    ),
                    labelText: "Recipe Name",
                    labelStyle: const TextStyle(color: Colors.black),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFF2A541),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.fastfood,
                      color: Color(0xFFD72638),
                    ),
                    labelText: "Meal Type",
                    labelStyle: const TextStyle(color: Colors.black),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFF2A541),
                        width: 2,
                      ),
                    ),
                  ),
                  value: _selectedMealType,
                  items: const [
                    DropdownMenuItem(
                      value: "Breakfast",
                      child: Text("Breakfast"),
                    ),
                    DropdownMenuItem(value: "Lunch", child: Text("Lunch")),
                    DropdownMenuItem(value: "Dinner", child: Text("Dinner")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMealType = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _ingredientsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.list_alt,
                      color: Color(0xFFD72638),
                    ),
                    labelText: "Ingredients",
                    labelStyle: const TextStyle(color: Colors.black),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFF2A541),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _instructionsController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.menu_book,
                      color: Color(0xFFD72638),
                    ),
                    labelText: "Instructions",
                    labelStyle: const TextStyle(color: Colors.black),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFF2A541),
                        width: 2,
                      ),
                    ),
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
