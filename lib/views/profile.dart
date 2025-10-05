import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  Future<void> toggleLike(String recipeId, Map<String, dynamic> likes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    final isLiked = likes.containsKey(userId);
    final recipeRef =
        FirebaseFirestore.instance.collection('recipes').doc(recipeId);

    if (isLiked) {
      likes.remove(userId);
    } else {
      likes[userId] = true;
    }
    await recipeRef.update({'likes': likes});
  }

  Future<void> toggleSave(String recipeId, Map<String, dynamic> saves) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    final isSaved = saves.containsKey(userId);
    final recipeRef =
        FirebaseFirestore.instance.collection('recipes').doc(recipeId);

    if (isSaved) {
      saves.remove(userId);
    } else {
      saves[userId] = true;
    }
    await recipeRef.update({'saves': saves});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Example friends list (replace later if you want dynamic)
    final List<String> friends = ["Maria Clara", "Juan Dela Cruz", "Jose Rizal"];

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
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => [
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
      body: user == null
          ? const Center(child: Text("Please log in"))
          : ListView(
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
                          child: Icon(Icons.person,
                              size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? "Your Name",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C1C1C),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user.email ?? "your.email@example.com",
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
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                                    child:
                                        Icon(Icons.person, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(friend,
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

                // User Recipes Section
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

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('recipes')
                      .where('userId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text("You haven’t posted anything yet"));
                    }

                    final recipes = snapshot.data!.docs;

                    return Column(
                      children: recipes.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final likes =
                            Map<String, dynamic>.from(data['likes'] ?? {});
                        final saves =
                            Map<String, dynamic>.from(data['saves'] ?? {});

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Color(0xFF1C1C1C),
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        user.displayName ??
                                            user.email!.split('@')[0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.more_vert,
                                        color: Colors.black54),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  data['name'] ?? "No title",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  data['mealType'] ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                if ((data['ingredients'] ?? "").isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Ingredients:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(data['ingredients']),
                                ],
                                if ((data['instructions'] ?? "").isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    "Instructions:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(data['instructions']),
                                ],
                                const Divider(thickness: 1),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          toggleLike(doc.id, likes),
                                      child: Row(
                                        children: [
                                          Icon(
                                            likes.containsKey(
                                                  FirebaseAuth.instance
                                                          .currentUser?.uid ??
                                                      "",
                                                )
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text("${likes.length}"),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.comment_outlined,
                                          size: 20,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Comment",
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          toggleSave(doc.id, saves),
                                      child: Row(
                                        children: [
                                          Icon(
                                            saves.containsKey(
                                                  FirebaseAuth.instance
                                                          .currentUser?.uid ??
                                                      "",
                                                )
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: Colors.black87,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text("Save"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
