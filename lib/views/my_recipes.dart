import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 🎨 Color Palette - Food themed (consistent across app)
class AppColors {
  static const primary = Color(0xFFFF6B35); // Warm Orange
  static const secondary = Color(0xFFFFBE0B); // Golden Yellow
  static const accent = Color(0xFFFB5607); // Vibrant Red-Orange
  static const dark = Color(0xFF2D3142); // Dark Blue-Gray
  static const light = Color(0xFFFFFBF0); // Cream White
  static const success = Color(0xFF06A77D); // Fresh Green
}

class MyRecipes extends StatelessWidget {
  const MyRecipes({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            const Text(
              "My Recipes",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login,
                    size: 80,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Please log in",
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.dark.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Error: ${snapshot.error}",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.dark.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 100,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No recipes yet",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start sharing your delicious recipes!",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dark.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final recipes = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe =
                        recipes[index].data() as Map<String, dynamic>;

                    final recipeName = recipe['name'] ?? 'No name';
                    final mealType = recipe['mealType'] ?? 'No meal type';
                    final ingredients = recipe['ingredients'] ?? '';
                    final instructions = recipe['instructions'] ?? '';

                    // Get meal type icon and color
                    IconData mealIcon;
                    Color mealColor;
                    switch (mealType) {
                      case 'Breakfast':
                        mealIcon = Icons.wb_sunny;
                        mealColor = AppColors.secondary;
                        break;
                      case 'Lunch':
                        mealIcon = Icons.lunch_dining;
                        mealColor = AppColors.primary;
                        break;
                      case 'Dinner':
                        mealIcon = Icons.dinner_dining;
                        mealColor = AppColors.accent;
                        break;
                      default:
                        mealIcon = Icons.fastfood;
                        mealColor = AppColors.primary;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with gradient
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  mealColor.withOpacity(0.15),
                                  mealColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: mealColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    mealIcon,
                                    color: mealColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipeName,
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
                                            mealIcon,
                                            size: 14,
                                            color: mealColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            mealType,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: mealColor,
                                              fontWeight: FontWeight.w600,
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

                          // Recipe Image (if available)
                          if (recipe['imageUrl'] != null &&
                              recipe['imageUrl'].toString().isNotEmpty)
                            ClipRRect(
                              child: Image.network(
                                recipe['imageUrl'].toString(),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: AppColors.light,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: AppColors.dark.withOpacity(0.3),
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        color: AppColors.light,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ),

                          // Content with fixed height containers
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ingredients.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.list_alt,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Ingredients",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 327,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.light,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        ingredients,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.dark.withOpacity(
                                            0.8,
                                          ),
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (instructions.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.menu_book,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Instructions",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 327,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.light,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        instructions,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.dark.withOpacity(
                                            0.8,
                                          ),
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
