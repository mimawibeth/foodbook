import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cce106_flutter_project/views/create_recipe.dart';
import 'my_recipes.dart';
import 'favorites.dart';
import 'profile.dart';
import 'other_profile.dart';

// 🎨 Color Palette - Food themed (same as register.dart)
class AppColors {
  static const primary = Color(0xFFFF6B35); // Warm Orange
  static const secondary = Color(0xFFFFBE0B); // Golden Yellow
  static const accent = Color(0xFFFB5607); // Vibrant Red-Orange
  static const dark = Color(0xFF2D3142); // Dark Blue-Gray
  static const light = Color(0xFFFFFBF0); // Cream White
  static const success = Color(0xFF06A77D); // Fresh Green
}

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
      backgroundColor: AppColors.light,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 2,
        title: const Text(
          'FoodBook',
          style: TextStyle(
            color: AppColors.light,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),

            child: IconButton(
              icon: Icon(Icons.search, color: AppColors.light),
              onPressed: () async {
                await showSearch(
                  context: context,
                  delegate: RecipeSearchDelegate(),
                );
              },
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.dark.withOpacity(0.6),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
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
      ),
    );
  }
}

// --- SEARCH DELEGATE ---
class RecipeSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search recipes or users...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: AppColors.dark),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: AppColors.dark),
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
      return Center(
        child: Text(
          'Type to search recipes or users',
          style: TextStyle(color: AppColors.dark.withOpacity(0.6)),
        ),
      );
    }
    return _buildRecipeResults(query);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  Widget _buildRecipeResults(String searchQuery) {
    final lowerQuery = searchQuery.toLowerCase();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchResults(lowerQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text(
              'No results found',
              style: TextStyle(color: AppColors.dark.withOpacity(0.6)),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final data = results[index];
            if (data['type'] == 'recipe') {
              final recipeTitle = data['name'] ?? 'No title';
              final mealType = data['mealType'] ?? '';
              final ingredients = data['ingredients'] ?? '';
              final instructions = data['instructions'] ?? '';
              final username = data['postedBy'] ?? 'Unknown';
              final authorId = (data['userId'] ?? '') as String;
              final imageUrl = data['imageUrl'] ?? '';
              final timeAgo = _formatTimestamp(data['timestamp']);

              // Get meal type icon and color (matching discover page)
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
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 22,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (authorId.isNotEmpty &&
                                    FirebaseAuth.instance.currentUser?.uid !=
                                        authorId) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OtherUserProfilePage(
                                        userId: authorId,
                                        displayName: username.toString(),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  if (timeAgo.isNotEmpty)
                                    Text(
                                      timeAgo,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.dark.withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recipe Content with gradient header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            mealColor.withOpacity(0.1),
                            mealColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: mealColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(mealIcon, color: mealColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipeTitle,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mealColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    mealType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: mealColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recipe Image (if available)
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 250,
                              color: AppColors.light,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: AppColors.dark.withOpacity(0.3),
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 250,
                              color: AppColors.light,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Ingredients & Instructions
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
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Ingredients',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.dark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.light,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                ingredients,
                                style: TextStyle(
                                  color: AppColors.dark.withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          if (instructions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.format_list_numbered,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Instructions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.dark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.light,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                instructions,
                                style: TextStyle(
                                  color: AppColors.dark.withOpacity(0.8),
                                  height: 1.4,
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
            } else if (data['type'] == 'user') {
              final displayName = data['displayName'] ?? 'User';
              final email = data['email'] ?? '';
              final userId = data['userId'] as String? ?? '';
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.person, color: AppColors.secondary),
                  title: Text(displayName),
                  subtitle: Text(email),
                  onTap: () {
                    if (userId.isEmpty) return;
                    final current = FirebaseAuth.instance.currentUser?.uid;
                    if (current != null && current == userId) {
                      Navigator.pop(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtherUserProfilePage(
                            userId: userId,
                            displayName: displayName,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            } else {
              return SizedBox.shrink();
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
        .map((doc) {
          final data = doc.data();
          final haystack = [
            (data['name'] ?? '').toString(),
            (data['mealType'] ?? '').toString(),
            (data['ingredients'] ?? '').toString(),
            (data['instructions'] ?? '').toString(),
            (data['postedBy'] ?? '').toString(),
          ].join(' ').toLowerCase();
          if (haystack.contains(lowerQuery)) {
            return {...data, 'type': 'recipe'};
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    final userResults = userSnap.docs
        .map((doc) {
          final data = doc.data();
          final first = (data['firstName'] ?? '').toString();
          final last = (data['lastName'] ?? '').toString();
          final dn = (data['displayName'] ?? '').toString();
          final email = (data['email'] ?? '').toString();
          final username = (data['username'] ?? '').toString();
          final full = [first, last].where((s) => s.isNotEmpty).join(' ');
          final displayName = dn.isNotEmpty
              ? dn
              : (full.isNotEmpty
                    ? full
                    : (email.isNotEmpty ? email.split('@').first : 'User'));
          final haystack = [
            displayName,
            first,
            last,
            email,
            username,
          ].where((s) => s.isNotEmpty).join(' ').toLowerCase();
          if (haystack.contains(lowerQuery)) {
            return <String, dynamic>{
              'type': 'user',
              'userId': doc.id,
              'displayName': displayName,
              'email': email,
            };
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    return [...recipeResults, ...userResults];
  }
}

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
  final Set<String> _hiddenRecipeIds = <String>{};
  final Set<String> _hiddenUserIds = <String>{};
  final Set<String> _followingIds = <String>{};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _hiddenSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mealTypes.length, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedMealType = _mealTypes[_tabController.index]);
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userDocSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            final data = doc.data();
            final hiddenRecipes =
                (data?['hiddenRecipeIds'] as List?)?.cast<String>() ??
                const <String>[];
            final hiddenUsers =
                (data?['hiddenUserIds'] as List?)?.cast<String>() ??
                const <String>[];
            final following =
                (data?['followingIds'] as List?)?.cast<String>() ??
                const <String>[];
            setState(() {
              _hiddenRecipeIds
                ..clear()
                ..addAll(hiddenRecipes);
              _hiddenUserIds
                ..clear()
                ..addAll(hiddenUsers);
              _followingIds
                ..clear()
                ..addAll(following);
            });
          });
    }

    if (user != null) {
      _hiddenSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            final list =
                (doc.data()?['hiddenRecipeIds'] as List?)?.cast<String>() ??
                const <String>[];
            setState(() {
              _hiddenRecipeIds
                ..clear()
                ..addAll(list);
            });
          });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream(String recipeId) {
    return FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> _getDisplayNameForUid(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      final first = (data['firstName'] ?? '').toString().trim();
      final last = (data['lastName'] ?? '').toString().trim();
      final dn = (data['displayName'] ?? '').toString().trim();
      final full = [first, last].where((s) => s.isNotEmpty).join(' ');
      if (dn.isNotEmpty) return dn;
      if (full.isNotEmpty) return full;
    } catch (_) {}
    final authName = FirebaseAuth.instance.currentUser?.displayName;
    if (authName != null && authName.trim().isNotEmpty) return authName.trim();
    return 'User';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  Future<void> _addComment(
    String recipeId,
    String text, {
    String? parentId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final displayName = await _getDisplayNameForUid(user.uid);
    await FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .add({
          'userId': user.uid,
          'displayName': displayName,
          'text': text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'likes': <String, bool>{},
          'parentId': parentId,
        });
    await FirebaseFirestore.instance.collection('recipes').doc(recipeId).set({
      'commentsCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> _toggleCommentLike(
    String recipeId,
    String commentId,
    Map<String, dynamic> likes,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final isLiked = likes.containsKey(uid);
    final ref = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc(commentId);
    if (isLiked) {
      likes.remove(uid);
    } else {
      likes[uid] = true;
    }
    await ref.update({'likes': likes});
  }

  Future<void> _editComment(
    String recipeId,
    String commentId,
    String initialText,
  ) async {
    final controller = TextEditingController(text: initialText);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit comment'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .collection('comments')
          .doc(commentId)
          .update({'text': controller.text.trim()});
    }
  }

  Future<void> _deleteComment(String recipeId, String commentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final commentsCol = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments');
    final replies = await commentsCol
        .where('parentId', isEqualTo: commentId)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(commentsCol.doc(commentId));
    for (final d in replies.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    final totalRemoved = 1 + replies.docs.length;
    await FirebaseFirestore.instance.collection('recipes').doc(recipeId).set({
      'commentsCount': FieldValue.increment(-totalRemoved),
    }, SetOptions(merge: true));
  }

  void _showCommentsBottomSheet(BuildContext context, String recipeId) {
    final controller = TextEditingController();
    String? replyingToId;
    String? replyingToName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setBSState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Comments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 360,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _commentsStream(recipeId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return Center(child: Text('No comments yet'));
                        }
                        final parents =
                            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                        final repliesByParent =
                            <
                              String,
                              List<QueryDocumentSnapshot<Map<String, dynamic>>>
                            >{};
                        for (final d in docs) {
                          final data = d.data();
                          final parentId = data['parentId'] as String?;
                          if (parentId == null) {
                            parents.add(d);
                          } else {
                            (repliesByParent[parentId] ??= []).add(d);
                          }
                        }
                        return ListView.separated(
                          itemCount: parents.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final parentDoc = parents[index];
                            final c = parentDoc.data();
                            final commentId = parentDoc.id;
                            final likes = Map<String, dynamic>.from(
                              c['likes'] ?? {},
                            );
                            final isMine =
                                c['userId'] ==
                                FirebaseAuth.instance.currentUser?.uid;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(c['displayName'] ?? 'User'),
                                  subtitle: Text(c['text'] ?? ''),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (val) async {
                                      if (val == 'edit' && isMine) {
                                        await _editComment(
                                          recipeId,
                                          commentId,
                                          c['text'] ?? '',
                                        );
                                      } else if (val == 'delete' && isMine) {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Delete comment?'),
                                            content: Text(
                                              'This will remove the comment and its replies.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          await _deleteComment(
                                            recipeId,
                                            commentId,
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => isMine
                                        ? [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 72,
                                    right: 12,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _toggleCommentLike(
                                          recipeId,
                                          commentId,
                                          likes,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              likes.containsKey(
                                                    FirebaseAuth
                                                            .instance
                                                            .currentUser
                                                            ?.uid ??
                                                        '',
                                                  )
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${likes.length}',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      InkWell(
                                        onTap: () {
                                          replyingToId = commentId;
                                          replyingToName =
                                              c['displayName'] ?? 'User';
                                          setBSState(() {});
                                        },
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...List.generate(
                                  (repliesByParent[commentId] ?? const [])
                                      .length,
                                  (ri) {
                                    final rDoc =
                                        repliesByParent[commentId]![ri];
                                    final r = rDoc.data();
                                    final rLikes = Map<String, dynamic>.from(
                                      r['likes'] ?? {},
                                    );
                                    final rIsMine =
                                        r['userId'] ==
                                        FirebaseAuth.instance.currentUser?.uid;
                                    return Padding(
                                      padding: EdgeInsets.only(left: 48),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            leading: CircleAvatar(
                                              radius: 14,
                                              child: Icon(
                                                Icons.person,
                                                size: 16,
                                              ),
                                            ),
                                            title: Text(
                                              r['displayName'] ?? 'User',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            subtitle: Text(r['text'] ?? ''),
                                            trailing: PopupMenuButton<String>(
                                              onSelected: (val) async {
                                                if (val == 'edit' && rIsMine) {
                                                  await _editComment(
                                                    recipeId,
                                                    rDoc.id,
                                                    r['text'] ?? '',
                                                  );
                                                } else if (val == 'delete' &&
                                                    rIsMine) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('recipes')
                                                      .doc(recipeId)
                                                      .collection('comments')
                                                      .doc(rDoc.id)
                                                      .delete();
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('recipes')
                                                      .doc(recipeId)
                                                      .set({
                                                        'commentsCount':
                                                            FieldValue.increment(
                                                              -1,
                                                            ),
                                                      }, SetOptions(merge: true));
                                                }
                                              },
                                              itemBuilder: (context) => rIsMine
                                                  ? [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Text('Edit'),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Text('Delete'),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: 56,
                                              bottom: 8,
                                            ),
                                            child: InkWell(
                                              onTap: () => _toggleCommentLike(
                                                recipeId,
                                                rDoc.id,
                                                rLikes,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    rLikes.containsKey(
                                                          FirebaseAuth
                                                                  .instance
                                                                  .currentUser
                                                                  ?.uid ??
                                                              '',
                                                        )
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    size: 14,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '${rLikes.length}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (replyingToId != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to ${replyingToName ?? ''}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              replyingToId = null;
                              replyingToName = null;
                              setBSState(() {});
                            },
                            child: Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () async {
                          if (controller.text.trim().isEmpty) return;
                          await _addComment(
                            recipeId,
                            controller.text,
                            parentId: replyingToId,
                          );
                          controller.clear();
                          replyingToId = null;
                          replyingToName = null;
                          setBSState(() {});
                        },
                        child: Text(
                          'Post',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _hiddenSub?.cancel();
    _userDocSub?.cancel();
    _tabController.dispose();
    super.dispose();
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

  Future<void> _toggleFollow(String targetUid) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || targetUid.isEmpty || uid == targetUid) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final isFollowing = _followingIds.contains(targetUid);
    if (isFollowing) {
      await userDoc.set({
        'followingIds': FieldValue.arrayRemove([targetUid]),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('users').doc(targetUid).set({
        'followersIds': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    } else {
      await userDoc.set({
        'followingIds': FieldValue.arrayUnion([targetUid]),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('users').doc(targetUid).set({
        'followersIds': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    }
    setState(() {
      if (isFollowing) {
        _followingIds.remove(targetUid);
      } else {
        _followingIds.add(targetUid);
      }
    });
  }

  Future<void> _hideUser(String targetUid) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || targetUid.isEmpty || uid == targetUid) return;
    _hiddenUserIds.add(targetUid);
    setState(() {});
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 3),
        content: Text('User hidden'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            _hiddenUserIds.remove(targetUid);
            setState(() {});
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'hiddenUserIds': FieldValue.arrayRemove([targetUid]),
            }, SetOptions(merge: true));
          },
        ),
      ),
    );
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'hiddenUserIds': FieldValue.arrayUnion([targetUid]),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Enhanced Post bar
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRecipePage()),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Want to share your recipe?",
                    style: TextStyle(color: AppColors.dark.withOpacity(0.7)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Post",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Enhanced Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.dark,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: _mealTypes.map((type) => Tab(text: type)).toList(),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fetchAllRecipes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No recipes found",
                    style: TextStyle(color: AppColors.dark.withOpacity(0.6)),
                  ),
                );
              }

              final recipes = snapshot.data!.docs
                  .where((doc) {
                    if (_selectedMealType == "All") return true;
                    final data = doc.data() as Map<String, dynamic>;
                    return data['mealType'] == _selectedMealType;
                  })
                  .where((doc) => !_hiddenRecipeIds.contains(doc.id))
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = (data['userId'] ?? '') as String;
                    return !_hiddenUserIds.contains(uid);
                  })
                  .toList();

              if (recipes.isEmpty) {
                return Center(
                  child: Text(
                    "No recipes found",
                    style: TextStyle(color: AppColors.dark.withOpacity(0.6)),
                  ),
                );
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
                  final authorId = (data['userId'] ?? '') as String;
                  final commentsCount = (data['commentsCount'] is int)
                      ? (data['commentsCount'] as int)
                      : 0;
                  final timeAgo = _formatTimestamp(data['timestamp']);

                  // Get meal type icon and color (matching profile.dart)
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
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.accent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    size: 22,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (authorId.isNotEmpty &&
                                        FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid !=
                                            authorId) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OtherUserProfilePage(
                                            userId: authorId,
                                            displayName: username.toString(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                      if (timeAgo.isNotEmpty)
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.dark.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Only show menu if current user is the owner
                              if (FirebaseAuth.instance.currentUser?.uid ==
                                  authorId)
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: AppColors.dark.withOpacity(0.6),
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateRecipePage(
                                            recipeId: recipes[index].id,
                                            initialData: data,
                                          ),
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            'Delete Recipe',
                                            style: TextStyle(
                                              color: AppColors.dark,
                                            ),
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete this recipe?',
                                            style: TextStyle(
                                              color: AppColors.dark.withOpacity(
                                                0.7,
                                              ),
                                            ),
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
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('recipes')
                                              .doc(recipes[index].id)
                                              .delete();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Recipe deleted',
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to delete: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Edit Recipe'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Delete Recipe'),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient:
                                            _followingIds.contains(authorId)
                                            ? null
                                            : LinearGradient(
                                                colors: [
                                                  AppColors.primary,
                                                  AppColors.accent,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        color: _followingIds.contains(authorId)
                                            ? AppColors.dark.withOpacity(0.1)
                                            : null,
                                      ),
                                      height: 36,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _toggleFollow(authorId),
                                        child: Text(
                                          _followingIds.contains(authorId)
                                              ? 'Following'
                                              : 'Follow',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                _followingIds.contains(authorId)
                                                ? AppColors.dark
                                                : Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: AppColors.dark.withOpacity(0.6),
                                      ),
                                      onSelected: (value) async {
                                        if (value == 'hide') {
                                          final hiddenId = recipes[index].id;
                                          _hiddenRecipeIds.add(hiddenId);
                                          setState(() {});
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Post hidden',
                                              ),
                                              backgroundColor: AppColors.dark,
                                              action: SnackBarAction(
                                                label: 'Undo',
                                                textColor: AppColors.secondary,
                                                onPressed: () async {
                                                  _hiddenRecipeIds.remove(
                                                    hiddenId,
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          );
                                        } else if (value == 'hide_user') {
                                          await _hideUser(authorId);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'hide',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.visibility_off,
                                                color: AppColors.dark,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text('Hide Post'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'hide_user',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.no_accounts,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text('Hide User'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        // Recipe Content with gradient header (matching profile.dart)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                mealColor.withOpacity(0.1),
                                mealColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: mealColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  mealIcon,
                                  color: mealColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipeTitle,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: mealColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        mealType,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: mealColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Recipe Image (if available)
                        if (data['imageUrl'] != null &&
                            data['imageUrl'].toString().isNotEmpty)
                          ClipRRect(
                            child: Image.network(
                              data['imageUrl'].toString(),
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 250,
                                  color: AppColors.light,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: AppColors.dark.withOpacity(0.3),
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 250,
                                      color: AppColors.light,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),

                        // Ingredients & Instructions (matching profile.dart style)
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
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Ingredients',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.light,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    ingredients,
                                    style: TextStyle(
                                      color: AppColors.dark.withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                              if (instructions.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_list_numbered,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Instructions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.light,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    instructions,
                                    style: TextStyle(
                                      color: AppColors.dark.withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Action Buttons (matching profile.dart style)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        toggleLike(recipes[index].id, likes),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            color:
                                                likes.containsKey(
                                                  FirebaseAuth
                                                          .instance
                                                          .currentUser
                                                          ?.uid ??
                                                      "",
                                                )
                                                ? AppColors.accent
                                                : AppColors.dark.withOpacity(
                                                    0.6,
                                                  ),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${likes.length}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.dark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _showCommentsBottomSheet(
                                      context,
                                      recipes[index].id,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.comment_outlined,
                                            color: AppColors.dark.withOpacity(
                                              0.6,
                                            ),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$commentsCount',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.dark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        toggleSave(recipes[index].id, saves),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            saves.containsKey(
                                                  FirebaseAuth
                                                          .instance
                                                          .currentUser
                                                          ?.uid ??
                                                      '',
                                                )
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color:
                                                saves.containsKey(
                                                  FirebaseAuth
                                                          .instance
                                                          .currentUser
                                                          ?.uid ??
                                                      '',
                                                )
                                                ? AppColors.secondary
                                                : AppColors.dark.withOpacity(
                                                    0.6,
                                                  ),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${saves.length}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.dark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
