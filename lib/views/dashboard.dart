import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cce106_flutter_project/views/create_recipe.dart';
import 'my_recipes.dart';
import 'favorites.dart';
import 'profile.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardHome(), // 🚀 no const here
    const MyRecipes(),
    const Favorites(),
    const Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFD72638),
        title: const Text(
          "FoodBook",
          style: TextStyle(
            color: Color(0xFFFAFAFA),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.search, color: Color(0xFFFAFAFA)),
              onPressed: () async {
                final result = await showSearch(
                  context: context,
                  delegate: RecipeSearchDelegate(),
                );
                // Optionally handle result
              },
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex], // 👈 only the page content goes here
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFD72638),
        unselectedItemColor: const Color(0xFF1C1C1C),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'My Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// --- SEARCH DELEGATE ---
class RecipeSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search recipes...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildRecipeResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search recipes'));
    }
    return _buildRecipeResults(query);
  }

  Widget _buildRecipeResults(String searchQuery) {
    final lowerQuery = searchQuery.toLowerCase();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchResults(lowerQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No results found'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final data = results[index];
            if (data['type'] == 'recipe') {
              final recipeTitle = data['name'] ?? 'No title';
              final mealType = data['mealType'] ?? '';
              final ingredients = data['ingredients'] ?? '';
              final instructions = data['instructions'] ?? '';
              return ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: Text(recipeTitle),
                subtitle: Text(mealType),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(recipeTitle),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Meal Type: $mealType'),
                            const SizedBox(height: 8),
                            Text('Ingredients: $ingredients'),
                            const SizedBox(height: 8),
                            Text('Instructions: $instructions'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else if (data['type'] == 'user') {
              final username = data['username'] ?? 'No username';
              final email = data['email'] ?? '';
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(username),
                subtitle: Text(email),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(username),
                      content: Text('Email: $email'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchResults(String lowerQuery) async {
    final recipeSnap = await FirebaseFirestore.instance
        .collection('recipes')
        .get();
    final userSnap = await FirebaseFirestore.instance.collection('users').get();

    final recipeResults = recipeSnap.docs
        .map((doc) => doc.data())
        .where(
          (data) => (data['name'] ?? '').toString().toLowerCase().contains(
            lowerQuery,
          ),
        )
        .map((data) => {...data, 'type': 'recipe'})
        .toList();

    final userResults = userSnap.docs
        .map((doc) => doc.data())
        .where(
          (data) => (data['username'] ?? '').toString().toLowerCase().contains(
            lowerQuery,
          ),
        )
        .map((data) => {...data, 'type': 'user'})
        .toList();

    return [...recipeResults, ...userResults];
  }
}

// ...existing code...
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _mealTypes = ["All", "Breakfast", "Lunch", "Dinner"];
  String _selectedMealType = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mealTypes.length, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedMealType = _mealTypes[_tabController.index]);
    });
  }

  Stream<QuerySnapshot> _fetchAllRecipes() {
    return FirebaseFirestore.instance
        .collection('recipes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> toggleLike(String recipeId, Map<String, dynamic> likes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    final isLiked = likes.containsKey(userId);
    final recipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId);

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
    final recipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId);

    if (isSaved) {
      saves.remove(userId);
    } else {
      saves[userId] = true;
    }
    await recipeRef.update({'saves': saves});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Post bar
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRecipePage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: const Row(
              children: [
                Icon(Icons.account_circle, size: 32, color: Color(0xFF1C1C1C)),
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
        Container(
          height: 2,
          color: const Color(0xFF1C1C1C),
          margin: const EdgeInsets.symmetric(vertical: 2),
        ),
        Container(
          color: Colors.white,
          width: double.infinity, // full width
          child: LayoutBuilder(
            builder: (context, constraints) {
              // adjust font size based on available width
              double fontSize = constraints.maxWidth / (_mealTypes.length * 6);
              fontSize = fontSize.clamp(12, 16); // min 12, max 16

              return TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFD72638),
                unselectedLabelColor: const Color(0xFF1C1C1C),
                indicatorColor: const Color(0xFFD72638),
                labelStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(fontSize: fontSize),
                tabs: _mealTypes.map((type) => Tab(text: type)).toList(),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fetchAllRecipes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No recipes found"));
              }

              final recipes = snapshot.data!.docs.where((doc) {
                if (_selectedMealType == "All") return true;
                final data = doc.data() as Map<String, dynamic>;
                return data['mealType'] == _selectedMealType;
              }).toList();

              if (recipes.isEmpty) {
                return const Center(child: Text("No recipes found"));
              }

              return ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final data = recipes[index].data() as Map<String, dynamic>;
                  final username = data['postedBy'] ?? "Your Name";
                  final recipeTitle = data['name'] ?? "No title";
                  final mealType = data['mealType'] ?? "";
                  final ingredients = data['ingredients'] ?? "";
                  final instructions = data['instructions'] ?? "";
                  final likes = Map<String, dynamic>.from(data['likes'] ?? {});
                  final saves = Map<String, dynamic>.from(data['saves'] ?? {});

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
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.more_vert,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            recipeTitle,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            mealType,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          if (ingredients.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              "Ingredients:",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(ingredients),
                          ],
                          if (instructions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text(
                              "Instructions:",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(instructions),
                          ],
                          const Divider(thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              InkWell(
                                onTap: () =>
                                    toggleLike(recipes[index].id, likes),
                                child: Row(
                                  children: [
                                    Icon(
                                      likes.containsKey(
                                            FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid ??
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
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () =>
                                    toggleSave(recipes[index].id, saves),
                                child: Row(
                                  children: [
                                    Icon(
                                      saves.containsKey(
                                            FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid ??
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
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
