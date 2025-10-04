import 'package:flutter/material.dart';
import '../widgets/recipe_card.dart';

class Favorites extends StatelessWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context) {
    // Example favorite recipes, replace with your actual saved data
    final List<Map<String, String>> favoriteRecipes = [
      {
        "username": "Maria Clara",
        "recipeTitle": "Sinigang na Baboy",
        "description":
            "Lunch\nIngredients:\nPork, Tamarind, Vegetables\nInstructions:\nBoil pork and add vegetables and tamarind mix.",
      },
      {
        "username": "Your Name",
        "recipeTitle": "Adobo",
        "description":
            "Lunch\nIngredients:\nChicken, Soy Sauce, Vinegar, Garlic, Bay Leaf\nInstructions:\nSimmer all ingredients until chicken is tender.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        automaticallyImplyLeading: false, // <-- Add this line
        title: const Text(
          "Favorites",
          style: TextStyle(
            color: Color(0xFFFAFAFA),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Saved Recipes",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Recipe List
          Expanded(
            child: favoriteRecipes.isEmpty
                ? const Center(
                    child: Text(
                      "You haven't saved any recipes yet.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: favoriteRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = favoriteRecipes[index];
                      return RecipeCard(
                        username: recipe["username"] ?? "",
                        recipeTitle: recipe["recipeTitle"] ?? "",
                        description: recipe["description"] ?? "",
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
