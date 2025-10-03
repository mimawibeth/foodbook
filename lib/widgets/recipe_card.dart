import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String username;
  final String recipeTitle;
  final String description;

  const RecipeCard({
    super.key,
    required this.username,
    required this.recipeTitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, 
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1, 
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Row
            Row(
              children: [
                const Icon(Icons.account_circle, size: 40, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.more_horiz,
                  color: Colors.black,
                ), 
              ],
            ),

            const SizedBox(height: 10),

            // Recipe Title
            if (recipeTitle.isNotEmpty)
              Text(
                recipeTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

            // Description
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),

            const SizedBox(height: 12),

            // Divider before actions
            Divider(color: Colors.grey[300], thickness: 1),

            const SizedBox(height: 4),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 6),
                    Text("Like", style: TextStyle(color: Colors.black54)),
                  ],
                ),
                Row(
                  children: const [
                    Icon(
                      Icons.comment_outlined,
                      size: 20,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 6),
                    Text("Comment", style: TextStyle(color: Colors.black54)),
                  ],
                ),
                Row(
                  children: const [
                    Icon(
                      Icons.bookmark_border,
                      size: 20,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 6),
                    Text("Save", style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
