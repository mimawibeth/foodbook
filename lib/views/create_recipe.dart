import 'package:flutter/material.dart';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  String? _selectedMealType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Consistent background
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
              onPressed: () {
                // TODO: Handle post action
              },
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
          // Removed borderRadius for a sharp-edged card
          shape: const RoundedRectangleBorder(),
          margin: const EdgeInsets.symmetric(vertical: 16), // Floating effect
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                // ...existing code...
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFD72638),
                      child: Icon(Icons.person, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
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
                // ...rest of your fields...
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFFD72638),
                    ),
                    labelText: "Recipe Name",
                    labelStyle: const TextStyle(color: Colors.black),
                    border: const OutlineInputBorder(), // No border radius
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
                    border: const OutlineInputBorder(), // No border radius
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
                  maxLines: 4,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.list_alt,
                      color: Color(0xFFD72638),
                    ),
                    labelText: "Ingredients",
                    labelStyle: const TextStyle(color: Colors.black),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(), // No border radius
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
                  maxLines: 6,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.menu_book,
                      color: Color(0xFFD72638),
                    ),
                    labelText: "Instructions",
                    labelStyle: const TextStyle(color: Colors.black),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(), // No border radius
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
