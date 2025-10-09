import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyRecipes extends StatelessWidget {
  const MyRecipes({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        centerTitle: true, // center the title
        title: const Text(
          "My Recipes",
          style: TextStyle(
            color: Colors.white, // make text white
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please log in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("You haven’t posted anything yet"),
                  );
                }

                final recipes = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe =
                        recipes[index].data() as Map<String, dynamic>;

                    final recipeName = recipe['name'] ?? 'No name';
                    final mealType = recipe['mealType'] ?? 'No meal type';
                    final ingredients = recipe['ingredients'] ?? '';
                    final instructions = recipe['instructions'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mealType,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            if (ingredients.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                "Ingredients:",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(ingredients),
                            ],
                            if (instructions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                "Instructions:",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(instructions),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
