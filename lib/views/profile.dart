import 'package:flutter/material.dart';
import '../widgets/recipe_card.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    // Example user data and friends
    final String username = "Your Name";
    final String email = "your.email@example.com";
    final List<String> friends = [
      "Maria Clara",
      "Juan Dela Cruz",
      "Jose Rizal",
    ];
    final List<Map<String, String>> userRecipes = [
      {
        "username": username,
        "recipeTitle": "Adobo",
        "description":
            "Lunch\nIngredients:\nChicken, Soy Sauce, Vinegar, Garlic, Bay Leaf\nInstructions:\nSimmer all ingredients until chicken is tender.",
      },
      {
        "username": username,
        "recipeTitle": "Pancit Canton",
        "description":
            "Dinner\nIngredients:\nNoodles, Vegetables, Pork, Soy Sauce\nInstructions:\nStir fry all ingredients and mix with noodles.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Color(0xFFFAFAFA),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Color(0xFFFAFAFA)),
            onSelected: (value) {
              if (value == 'logout') {
                // Handle logout
              } else if (value == 'settings') {
                // Handle settings
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Card(
            color: Colors.white,
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF1C1C1C),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Friends Section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Friends",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
              ),
            ),
          ),
          Card(
            color: Colors.white,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: friends
                    .map(
                      (friend) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF1C1C1C),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(friend, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          // Feed Section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              "Your Shared Recipes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
              ),
            ),
          ),
          // Recipe cards (same as my_recipes.dart)
          ...userRecipes.map(
            (recipe) => RecipeCard(
              username: recipe["username"] ?? "",
              recipeTitle: recipe["recipeTitle"] ?? "",
              description: recipe["description"] ?? "",
            ),
          ),
        ],
      ),
    );
  }
}
