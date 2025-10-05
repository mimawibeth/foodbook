import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        _expandedIndex = null; // collapse if already expanded
      } else {
        _expandedIndex = index; // expand the clicked item
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        automaticallyImplyLeading: false,
        title: const Text(
          "Favorites",
          style: TextStyle(
            color: Color(0xFFFAFAFA),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchSavedRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("You haven't saved any recipes yet."),
            );
          }

          final savedRecipes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: savedRecipes.length,
            itemBuilder: (context, index) {
              final data = savedRecipes[index].data() as Map<String, dynamic>;
              final isExpanded = _expandedIndex == index;

              return GestureDetector(
                onTap: () => _toggleExpansion(index),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              data['name'] ?? "Untitled Recipe",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.redAccent,
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(data['postedBy'] ?? "Unknown",
                            style: const TextStyle(color: Colors.grey)),
                        if (isExpanded) ...[
                          const Divider(),
                          const SizedBox(height: 4),
                          Text(
                            "Ingredients:",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(data['ingredients'] ?? "No ingredients listed"),
                          const SizedBox(height: 8),
                          Text(
                            "Instructions:",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(data['instructions'] ?? "No instructions provided"),
                        ],
                      ],
                    ),
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
