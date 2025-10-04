import 'package:flutter/material.dart';
import 'create_recipe.dart';
import '../widgets/recipe_card.dart';

class MyRecipes extends StatelessWidget {
  const MyRecipes({super.key});

  @override
  Widget build(BuildContext context) {
    // Example user recipes, replace with your data source
    final List<Map<String, String>> userRecipes = [
      {
        "username": "Your Name",
        "recipeTitle": "Adobo",
        "description":
            "Lunch\nIngredients:\nChicken, Soy Sauce, Vinegar, Garlic, Bay Leaf\nInstructions:\nSimmer all ingredients until chicken is tender.",
      },
      {
        "username": "Your Name",
        "recipeTitle": "Pancit Canton",
        "description":
            "Dinner\nIngredients:\nNoodles, Vegetables, Pork, Soy Sauce\nInstructions:\nStir fry all ingredients and mix with noodles.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        automaticallyImplyLeading: false, // <-- Add this line
        title: const Text(
          "My Recipes",
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
          // Post bar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRecipePage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: const [
                  Icon(
                    Icons.account_circle,
                    size: 32,
                    color: Color(0xFF1C1C1C),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Want to share your recipe?",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Strong line below for separation
          Container(
            height: 2,
            color: Color(0xFF1C1C1C),
            margin: const EdgeInsets.symmetric(vertical: 2),
          ),
          // Recipe List
          Expanded(
            child: userRecipes.isEmpty
                ? const Center(
                    child: Text(
                      "You haven't posted any recipes yet.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: userRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = userRecipes[index];
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
