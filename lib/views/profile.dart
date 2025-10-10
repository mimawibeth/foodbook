import 'package:cce106_flutter_project/auth/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'follow_list.dart';
import 'edit_profile.dart';
import 'create_recipe.dart';

class Profile extends StatelessWidget {
  final User? user;

  const Profile({super.key, this.user});

  Future<Map<String, String>> _getUserNames(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data == null) return {'firstName': '', 'lastName': ''};
    return {
      'firstName': data['firstName'] ?? '',
      'lastName': data['lastName'] ?? '',
    };
  }

  Future<void> toggleLike(String recipeId, Map<String, dynamic> likes) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final userId = currentUser.uid;
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final userId = currentUser.uid;
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

  // --- Comments helpers (mirrors dashboard/other_profile) ---
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
    final ref = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc();
    await ref.set({
      'userId': user.uid,
      'displayName': displayName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'likes': <String, dynamic>{},
      if (parentId != null) 'parentId': parentId,
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
    BuildContext context,
    String recipeId,
    String commentId,
    String currentText,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: currentText);
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (newText == null || newText.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc(commentId)
        .update({'text': newText});
  }

  Future<void> _deleteComment(String recipeId, String commentId) async {
    final ref = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc(commentId);
    final snap = await ref.get();
    final parentId = (snap.data() ?? {})['parentId'];
    if (parentId == null) {
      // delete all replies first
      final replies = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .collection('comments')
          .where('parentId', isEqualTo: commentId)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final r in replies.docs) {
        batch.delete(r.reference);
      }
      batch.delete(ref);
      await batch.commit();
      await FirebaseFirestore.instance.collection('recipes').doc(recipeId).set({
        'commentsCount': FieldValue.increment(-(replies.docs.length + 1)),
      }, SetOptions(merge: true));
    } else {
      await ref.delete();
      await FirebaseFirestore.instance.collection('recipes').doc(recipeId).set({
        'commentsCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
    }
  }

  void _showCommentsBottomSheet(BuildContext context, String recipeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            String? replyingToId;
            String? replyingToName;
            final controller = TextEditingController();
            return StatefulBuilder(
              builder: (context, setBSState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                    left: 12,
                    right: 12,
                    top: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Comments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _commentsStream(recipeId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final all = snapshot.data?.docs ?? const [];
                            final parents = all
                                .where(
                                  (d) => !(d.data().containsKey('parentId')),
                                )
                                .toList();
                            final replies = all
                                .where((d) => d.data().containsKey('parentId'))
                                .toList();
                            Map<
                              String,
                              List<QueryDocumentSnapshot<Map<String, dynamic>>>
                            >
                            grouped = {};
                            for (final r in replies) {
                              final pid = r.data()['parentId'] as String?;
                              if (pid == null) continue;
                              grouped.putIfAbsent(pid, () => []);
                              grouped[pid]!.add(r);
                            }
                            return ListView(
                              controller: scrollController,
                              children: [
                                for (final pDoc in parents)
                                  Builder(
                                    builder: (context) {
                                      final p = pDoc.data();
                                      final pLikes = Map<String, dynamic>.from(
                                        p['likes'] ?? {},
                                      );
                                      final isMine =
                                          p['userId'] ==
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 0,
                                                ),
                                            leading: const CircleAvatar(
                                              radius: 18,
                                              child: Icon(Icons.person),
                                            ),
                                            title: Text(
                                              p['displayName'] ?? 'User',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            subtitle: Text(p['text'] ?? ''),
                                            trailing: PopupMenuButton<String>(
                                              onSelected: (val) async {
                                                if (val == 'edit' && isMine) {
                                                  await _editComment(
                                                    context,
                                                    recipeId,
                                                    pDoc.id,
                                                    p['text'] ?? '',
                                                  );
                                                } else if (val == 'delete' &&
                                                    isMine) {
                                                  await _deleteComment(
                                                    recipeId,
                                                    pDoc.id,
                                                  );
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
                                              left: 56,
                                              bottom: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () =>
                                                      _toggleCommentLike(
                                                        recipeId,
                                                        pDoc.id,
                                                        pLikes,
                                                      ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        pLikes.containsKey(
                                                              FirebaseAuth
                                                                      .instance
                                                                      .currentUser
                                                                      ?.uid ??
                                                                  '',
                                                            )
                                                            ? Icons.favorite
                                                            : Icons
                                                                  .favorite_border,
                                                        size: 14,
                                                        color: Colors.red,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${pLikes.length}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                InkWell(
                                                  onTap: () async {
                                                    replyingToId = pDoc.id;
                                                    replyingToName =
                                                        p['displayName'] ??
                                                        'User';
                                                    setBSState(() {});
                                                  },
                                                  child: const Text(
                                                    'Reply',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if ((grouped[pDoc.id] ?? const [])
                                              .isNotEmpty) ...[
                                            for (final rDoc
                                                in (grouped[pDoc.id] ??
                                                    const []))
                                              Builder(
                                                builder: (context) {
                                                  final r = rDoc.data();
                                                  final rLikes =
                                                      Map<String, dynamic>.from(
                                                        r['likes'] ?? {},
                                                      );
                                                  final rIsMine =
                                                      r['userId'] ==
                                                      FirebaseAuth
                                                          .instance
                                                          .currentUser
                                                          ?.uid;
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 40,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        ListTile(
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 0,
                                                              ),
                                                          leading:
                                                              const CircleAvatar(
                                                                radius: 16,
                                                                child: Icon(
                                                                  Icons.person,
                                                                ),
                                                              ),
                                                          title: Text(
                                                            r['displayName'] ??
                                                                'User',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          subtitle: Text(
                                                            r['text'] ?? '',
                                                          ),
                                                          trailing: PopupMenuButton<String>(
                                                            onSelected: (val) async {
                                                              if (val ==
                                                                      'edit' &&
                                                                  rIsMine) {
                                                                await _editComment(
                                                                  context,
                                                                  recipeId,
                                                                  rDoc.id,
                                                                  r['text'] ??
                                                                      '',
                                                                );
                                                              } else if (val ==
                                                                      'delete' &&
                                                                  rIsMine) {
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                      'recipes',
                                                                    )
                                                                    .doc(
                                                                      recipeId,
                                                                    )
                                                                    .collection(
                                                                      'comments',
                                                                    )
                                                                    .doc(
                                                                      rDoc.id,
                                                                    )
                                                                    .delete();
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                      'recipes',
                                                                    )
                                                                    .doc(
                                                                      recipeId,
                                                                    )
                                                                    .set(
                                                                      {
                                                                        'commentsCount':
                                                                            FieldValue.increment(
                                                                              -1,
                                                                            ),
                                                                      },
                                                                      SetOptions(
                                                                        merge:
                                                                            true,
                                                                      ),
                                                                    );
                                                              }
                                                            },
                                                            itemBuilder:
                                                                (
                                                                  context,
                                                                ) => rIsMine
                                                                ? const [
                                                                    PopupMenuItem(
                                                                      value:
                                                                          'edit',
                                                                      child: Text(
                                                                        'Edit',
                                                                      ),
                                                                    ),
                                                                    PopupMenuItem(
                                                                      value:
                                                                          'delete',
                                                                      child: Text(
                                                                        'Delete',
                                                                      ),
                                                                    ),
                                                                  ]
                                                                : const [],
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 56,
                                                                bottom: 8,
                                                              ),
                                                          child: InkWell(
                                                            onTap: () =>
                                                                _toggleCommentLike(
                                                                  recipeId,
                                                                  rDoc.id,
                                                                  rLikes,
                                                                ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  rLikes.containsKey(
                                                                        FirebaseAuth.instance.currentUser?.uid ??
                                                                            '',
                                                                      )
                                                                      ? Icons
                                                                            .favorite
                                                                      : Icons
                                                                            .favorite_border,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  '${rLikes.length}',
                                                                  style:
                                                                      const TextStyle(
                                                                        fontSize:
                                                                            12,
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
                                        ],
                                      );
                                    },
                                  ),
                              ],
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user ?? FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
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
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const FoodBook()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
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
      body: currentUser == null
          ? const Center(child: Text('Please log in'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: TextButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfilePage(
                                        userId: currentUser.uid,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                              ),
                              FutureBuilder<Map<String, String>>(
                                future: _getUserNames(currentUser.uid),
                                builder: (context, snapshot) {
                                  final name = () {
                                    if (snapshot.hasData) {
                                      final f =
                                          snapshot.data!['firstName'] ?? '';
                                      final l =
                                          snapshot.data!['lastName'] ?? '';
                                      final full = [
                                        f,
                                        l,
                                      ].where((s) => s.isNotEmpty).join(' ');
                                      if (full.isNotEmpty) return full;
                                    }
                                    return currentUser.email
                                            ?.split('@')
                                            .first ??
                                        'You';
                                  }();
                                  return Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1C1C1C),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentUser.email ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>
                              >(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid)
                                    .snapshots(),
                                builder: (context, snap) {
                                  final data = snap.data?.data() ?? {};
                                  final followers =
                                      (data['followersIds'] as List?)
                                          ?.cast<String>() ??
                                      const <String>[];
                                  final following =
                                      (data['followingIds'] as List?)
                                          ?.cast<String>() ??
                                      const <String>[];
                                  return Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FollowListPage(
                                                userId: currentUser.uid,
                                                title: 'Followers',
                                                showFollowers: true,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.groups,
                                              size: 16,
                                              color: Colors.black54,
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        FollowListPage(
                                                          userId:
                                                              currentUser.uid,
                                                          title: 'Followers',
                                                          showFollowers: true,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                '${followers.length} followers',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FollowListPage(
                                                userId: currentUser.uid,
                                                title: 'Following',
                                                showFollowers: false,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.person_add_alt_1,
                                              size: 16,
                                              color: Colors.black54,
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        FollowListPage(
                                                          userId:
                                                              currentUser.uid,
                                                          title: 'Following',
                                                          showFollowers: false,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                '${following.length} following',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Your Shared Recipes',
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
                      .where('userId', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("You haven't posted anything yet"),
                      );
                    }
                    final recipes = snapshot.data!.docs;
                    return Column(
                      children: recipes.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final likes = Map<String, dynamic>.from(
                          data['likes'] ?? {},
                        );
                        final saves = Map<String, dynamic>.from(
                          data['saves'] ?? {},
                        );
                        final commentsCount = (data['commentsCount'] is int)
                            ? data['commentsCount'] as int
                            : 0;
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
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'You',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.black54,
                                      ),
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          // Navigate to create recipe page in edit mode
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreateRecipePage(
                                                recipeId: doc.id,
                                                initialData: data,
                                              ),
                                            ),
                                          );
                                        } else if (val == 'delete') {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Delete recipe',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this recipe? This action cannot be undone.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
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
                                                  .doc(doc.id)
                                                  .delete();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Recipe deleted',
                                                    ),
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
                                      itemBuilder: (ctx) => const [
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
                                            leading: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            title: Text('Remove'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  data['name'] ?? 'No title',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  data['mealType'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                if ((data['ingredients'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Ingredients:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(data['ingredients']),
                                ],
                                if ((data['instructions'] ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Instructions:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(data['instructions']),
                                ],
                                const Divider(thickness: 1),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    InkWell(
                                      onTap: () => toggleLike(doc.id, likes),
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
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text('${likes.length}'),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _showCommentsBottomSheet(
                                            context,
                                            doc.id,
                                          ),
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
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () => toggleSave(doc.id, saves),
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
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
