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

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  int? _expandedIndex;

  Stream<QuerySnapshot> _fetchSavedRecipes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('recipes')
        .where('saves.${user.uid}', isEqualTo: true)
        .snapshots();
  }

  void _toggleExpansion(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  Future<void> _unsaveRecipe(String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({'saves.${user.uid}': FieldValue.delete()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.bookmark_remove, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Removed from favorites'),
              ],
            ),
            backgroundColor: AppColors.dark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            const Text(
              "Favorites",
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchSavedRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 100,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No saved recipes yet",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start saving recipes you love!",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.dark.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          final savedRecipes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedRecipes.length,
            itemBuilder: (context, index) {
              final data = savedRecipes[index].data() as Map<String, dynamic>;
              final recipeId = savedRecipes[index].id;
              final isExpanded = _expandedIndex == index;
              final mealType = data['mealType'] ?? 'No meal type';
              final recipeName = data['name'] ?? 'Untitled Recipe';
              final postedBy = data['postedBy'] ?? 'Unknown';
              final ingredients =
                  data['ingredients'] ?? 'No ingredients listed';
              final instructions =
                  data['instructions'] ?? 'No instructions provided';

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
                    InkWell(
                      onTap: () => _toggleExpansion(index),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Container(
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
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(isExpanded ? 0 : 16),
                            bottomRight: Radius.circular(isExpanded ? 0 : 16),
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
                              child: Icon(mealIcon, color: mealColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: AppColors.dark.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'by $postedBy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.dark.withOpacity(
                                            0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.bookmark,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Text(
                                          'Remove from favorites?',
                                          style: TextStyle(
                                            color: AppColors.dark,
                                          ),
                                        ),
                                        content: const Text(
                                          'This recipe will be removed from your saved list.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: AppColors.dark,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _unsaveRecipe(recipeId);
                                    }
                                  },
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recipe Image (if available)
                    if (data['imageUrl'] != null &&
                        data['imageUrl'].toString().isNotEmpty)
                      ClipRRect(
                        child: Image.network(
                          data['imageUrl'].toString(),
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
                          loadingBuilder: (context, child, loadingProgress) {
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

                    // Expanded Content
                    if (isExpanded)
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
                                      color: AppColors.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    ingredients,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.dark.withOpacity(0.8),
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
                                      color: AppColors.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    instructions,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.dark.withOpacity(0.8),
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
