import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cce106_flutter_project/views/create_recipe.dart';
import 'my_recipes.dart';
import 'favorites.dart';
import 'profile.dart';
import 'other_profile.dart';

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
          'FoodBook',
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
  String get searchFieldLabel => 'Search recipes or users...';

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
              final displayName = data['displayName'] ?? 'User';
              final email = data['email'] ?? '';
              final userId = (data['userId'] ?? '').toString();
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(displayName),
                subtitle: Text(email),
                onTap: () {
                  if (userId.isEmpty) return;
                  final current = FirebaseAuth.instance.currentUser?.uid;
                  if (current != null && current == userId) {
                    // If it's me, switch to Profile tab
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
  // Holds IDs of posts the current user chose to hide (persisted via listener)
  final Set<String> _hiddenRecipeIds = <String>{};
  final Set<String> _hiddenUserIds = <String>{};
  // Holds IDs of users the current user follows (persisted)
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

    // Listen for current user's follow/hidden settings
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

    // Listen to the user's hidden recipes to persist hide across sessions
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
        title: const Text('Edit comment'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
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
    // delete the comment and its replies, then decrement commentsCount accordingly
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
      shape: const RoundedRectangleBorder(
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
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Comments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 360,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _commentsStream(recipeId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(child: Text('No comments yet'));
                        }
                        // split into parents and replies
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
                          separatorBuilder: (_, __) => const Divider(height: 1),
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
                                  leading: const CircleAvatar(
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
                                            title: const Text(
                                              'Delete comment?',
                                            ),
                                            content: const Text(
                                              'This will remove the comment and its replies.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text(
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
                                        ? const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ]
                                        : const [],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
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
                                            const SizedBox(width: 4),
                                            Text(
                                              '${likes.length}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      InkWell(
                                        onTap: () {
                                          replyingToId = commentId;
                                          replyingToName =
                                              c['displayName'] ?? 'User';
                                          setBSState(() {});
                                        },
                                        child: const Text(
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
                                // Replies
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
                                      padding: const EdgeInsets.only(left: 48),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            leading: const CircleAvatar(
                                              radius: 14,
                                              child: Icon(
                                                Icons.person,
                                                size: 16,
                                              ),
                                            ),
                                            title: Text(
                                              r['displayName'] ?? 'User',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
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
                                                  ? const [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Text('Edit'),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Text('Delete'),
                                                      ),
                                                    ]
                                                  : const [],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
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
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${rLikes.length}',
                                                    style: const TextStyle(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to ${replyingToName ?? ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              replyingToId = null;
                              replyingToName = null;
                              setBSState(() {});
                            },
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD72638),
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
                        child: const Text(
                          'Post',
                          style: TextStyle(color: Color(0xFFFAFAFA)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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

  // _handlePostMenu removed as the inline PopupMenuButtons are used; keeping the codebase clean.

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
                isScrollable: true,
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

              final recipes = snapshot.data!.docs
                  .where((doc) {
                    if (_selectedMealType == "All") return true;
                    final data = doc.data() as Map<String, dynamic>;
                    return data['mealType'] == _selectedMealType;
                  })
                  // Exclude posts the user chose to hide in this session
                  .where((doc) => !_hiddenRecipeIds.contains(doc.id))
                  // Exclude posts from users the current user has hidden
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = (data['userId'] ?? '').toString();
                    return !_hiddenUserIds.contains(uid);
                  })
                  .toList();

              if (recipes.isEmpty) {
                return const Center(child: Text("No recipes found"));
              }

              return ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final data = recipes[index].data() as Map<String, dynamic>;
                  final username = (data['postedBy'] ?? "Your Name").toString();
                  final recipeTitle = data['name'] ?? "No title";
                  final mealType = data['mealType'] ?? "";
                  final ingredients = data['ingredients'] ?? "";
                  final instructions = data['instructions'] ?? "";
                  final likes = Map<String, dynamic>.from(data['likes'] ?? {});
                  final saves = Map<String, dynamic>.from(data['saves'] ?? {});
                  final authorId = (data['userId'] ?? '').toString();
                  final commentsCount = (data['commentsCount'] is int)
                      ? (data['commentsCount'] as int)
                      : 0;
                  // ownership handled inline where needed; no local var required

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
                                  child: Text(
                                    username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // Only show menu if current user is the owner
                              if (FirebaseAuth.instance.currentUser?.uid ==
                                  authorId)
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.black54,
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
                                          title: const Text('Delete Post'),
                                          content: const Text(
                                            'Are you sure you want to delete this post?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
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
                                              const SnackBar(
                                                content: Text('Post deleted'),
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
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text('Edit'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete),
                                        title: Text('Remove'),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFFAFAFA,
                                        ),
                                        backgroundColor:
                                            _followingIds.contains(authorId)
                                            ? Colors.grey.shade700
                                            : const Color(0xFFD72638),
                                        side: BorderSide(
                                          color:
                                              _followingIds.contains(authorId)
                                              ? Colors.grey.shade700
                                              : const Color(0xFFD72638),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () => _toggleFollow(authorId),
                                      child: Text(
                                        _followingIds.contains(authorId)
                                            ? 'Following'
                                            : 'Follow',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFAFAFA),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.black54,
                                      ),
                                      onSelected: (value) async {
                                        if (value == 'view') {
                                          if (authorId.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    OtherUserProfilePage(
                                                      userId: authorId,
                                                      displayName: username
                                                          .toString(),
                                                    ),
                                              ),
                                            );
                                          }
                                        } else if (value == 'follow') {
                                          await _toggleFollow(authorId);
                                        } else if (value == 'unfollow') {
                                          await _toggleFollow(authorId);
                                        } else if (value == 'hide_user') {
                                          await _hideUser(authorId);
                                        } else if (value == 'hide') {
                                          final hiddenId = recipes[index].id;
                                          _hiddenRecipeIds.add(hiddenId);
                                          setState(() {});
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          messenger.hideCurrentSnackBar();
                                          messenger.showSnackBar(
                                            SnackBar(
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                              content: const Text(
                                                'Post hidden',
                                              ),
                                              action: SnackBarAction(
                                                label: 'Undo',
                                                onPressed: () async {
                                                  _hiddenRecipeIds.remove(
                                                    hiddenId,
                                                  );
                                                  setState(() {});
                                                  final uid = FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid;
                                                  if (uid != null) {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('users')
                                                        .doc(uid)
                                                        .set(
                                                          {
                                                            'hiddenRecipeIds':
                                                                FieldValue.arrayRemove(
                                                                  [hiddenId],
                                                                ),
                                                          },
                                                          SetOptions(
                                                            merge: true,
                                                          ),
                                                        );
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                          final uid = FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid;
                                          if (uid != null) {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(uid)
                                                .set({
                                                  'hiddenRecipeIds':
                                                      FieldValue.arrayUnion([
                                                        hiddenId,
                                                      ]),
                                                }, SetOptions(merge: true));
                                          }
                                        }
                                      },
                                      itemBuilder: (context) {
                                        final items =
                                            <PopupMenuEntry<String>>[];
                                        items.add(
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.person_search,
                                              ),
                                              title: Text('View Profile'),
                                            ),
                                          ),
                                        );
                                        if (_followingIds.contains(authorId)) {
                                          items.add(
                                            const PopupMenuItem(
                                              value: 'unfollow',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.person_remove,
                                                ),
                                                title: Text('Unfollow'),
                                              ),
                                            ),
                                          );
                                        } else {
                                          items.add(
                                            const PopupMenuItem(
                                              value: 'follow',
                                              child: ListTile(
                                                leading: Icon(Icons.person_add),
                                                title: Text('Follow'),
                                              ),
                                            ),
                                          );
                                        }
                                        items.add(
                                          const PopupMenuItem(
                                            value: 'hide_user',
                                            child: ListTile(
                                              leading: Icon(Icons.no_accounts),
                                              title: Text('Hide User'),
                                            ),
                                          ),
                                        );
                                        items.add(
                                          const PopupMenuItem(
                                            value: 'hide',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.visibility_off,
                                              ),
                                              title: Text('Hide Post'),
                                            ),
                                          ),
                                        );
                                        return items;
                                      },
                                    ),
                                  ],
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
                          // Removed inline chips for like/comment counts under the content
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
                              // <-- Fixed: removed `const` from this Row's children so non-const TextStyle won't cause a compile error
                              InkWell(
                                onTap: () {
                                  final recipeId = recipes[index].id;
                                  _showCommentsBottomSheet(context, recipeId);
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.comment_outlined,
                                      size: 20,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$commentsCount',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
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
                                                '',
                                          )
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${saves.length}'),
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
    // local update will be reflected by the listener; optional optimistic update:
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
        duration: const Duration(seconds: 3),
        content: const Text('User hidden'),
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
}
