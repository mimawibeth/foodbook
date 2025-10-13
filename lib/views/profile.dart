import 'package:cce106_flutter_project/auth/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'follow_list.dart';
import 'edit_profile.dart';
import 'create_recipe.dart';

// 🎨 Color Palette - Food themed (consistent across app)
class AppColors {
  static const primary = Color(0xFFFF6B35); // Warm Orange
  static const secondary = Color(0xFFFFBE0B); // Golden Yellow
  static const accent = Color(0xFFFB5607); // Vibrant Red-Orange
  static const dark = Color(0xFF2D3142); // Dark Blue-Gray
  static const light = Color(0xFFFFFBF0); // Cream White
  static const success = Color(0xFF06A77D); // Fresh Green
}

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
              child: Text('Save', style: TextStyle(color: AppColors.primary)),
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
    final controller = TextEditingController();
    String? replyingToId;
    String? replyingToName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.comment, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 360,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _commentsStream(recipeId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 60,
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    color: AppColors.dark.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
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
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
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
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.2),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  title: Text(
                                    c['displayName'] ?? 'User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  subtitle: Text(c['text'] ?? ''),
                                  trailing: isMine
                                      ? PopupMenuButton<String>(
                                          onSelected: (val) async {
                                            if (val == 'edit') {
                                              await _editComment(
                                                context,
                                                recipeId,
                                                commentId,
                                                c['text'] ?? '',
                                              );
                                            } else if (val == 'delete') {
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
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
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
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
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
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
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
                                      padding: const EdgeInsets.only(left: 48),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            leading: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppColors
                                                  .secondary
                                                  .withOpacity(0.3),
                                              child: Icon(
                                                Icons.person,
                                                size: 16,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                            title: Text(
                                              r['displayName'] ?? 'User',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.dark,
                                              ),
                                            ),
                                            subtitle: Text(r['text'] ?? ''),
                                            trailing: rIsMine
                                                ? PopupMenuButton<String>(
                                                    onSelected: (val) async {
                                                      if (val == 'edit') {
                                                        await _editComment(
                                                          context,
                                                          recipeId,
                                                          rDoc.id,
                                                          r['text'] ?? '',
                                                        );
                                                      } else if (val ==
                                                          'delete') {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'recipes',
                                                            )
                                                            .doc(recipeId)
                                                            .collection(
                                                              'comments',
                                                            )
                                                            .doc(rDoc.id)
                                                            .delete();
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'recipes',
                                                            )
                                                            .doc(recipeId)
                                                            .set(
                                                              {
                                                                'commentsCount':
                                                                    FieldValue.increment(
                                                                      -1,
                                                                    ),
                                                              },
                                                              SetOptions(
                                                                merge: true,
                                                              ),
                                                            );
                                                      }
                                                    },
                                                    itemBuilder: (context) =>
                                                        const [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.edit,
                                                                  size: 16,
                                                                ),
                                                                SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Text('Edit'),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.delete,
                                                                  size: 16,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Text(
                                                                  'Delete',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                  )
                                                : null,
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
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Replying to ${replyingToName ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.dark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              replyingToId = null;
                              replyingToName = null;
                              setBSState(() {});
                            },
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.primary,
                            ),
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
                            hintStyle: TextStyle(
                              color: AppColors.dark.withOpacity(0.4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.light,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        child: const Icon(Icons.send, size: 18),
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
  Widget build(BuildContext context) {
    final currentUser = user ?? FirebaseAuth.instance.currentUser;
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
            Icon(Icons.person, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),

              child: const Icon(Icons.menu, color: Colors.white),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: currentUser == null
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
                    'Please log in',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.dark.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Enhanced Profile Header Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Row(
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
                              radius: 38,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 42,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                          'User';
                                    }();
                                    return Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.dark,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUser.email ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.dark.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .snapshots(),
                        builder: (context, snap) {
                          final data = snap.data?.data() ?? {};
                          final followers =
                              (data['followersIds'] as List?)?.cast<String>() ??
                              const <String>[];
                          final following =
                              (data['followingIds'] as List?)?.cast<String>() ??
                              const <String>[];
                          return Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
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
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.groups,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${followers.length}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Followers',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
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
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_add_alt_1,
                                          size: 18,
                                          color: AppColors.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${following.length}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Following',
                                          style: TextStyle(
                                            color: AppColors.secondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Bio Section
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .snapshots(),
                        builder: (context, bioSnap) {
                          final bioData = bioSnap.data?.data() ?? {};
                          final bio = (bioData['bio'] ?? '').toString().trim();

                          if (bio.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.light,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Bio',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      bio,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.dark.withOpacity(0.8),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfilePage(userId: currentUser.uid),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section Header
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Shared Recipes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('recipes')
                      .where('userId', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text('Error: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 100,
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No recipes yet',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start sharing your delicious recipes!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.dark.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Sort recipes by timestamp (newest first)
                    final recipes = snapshot.data!.docs.toList()
                      ..sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>?;
                        final bData = b.data() as Map<String, dynamic>?;
                        final aTime = aData?['timestamp'] as Timestamp?;
                        final bTime = bData?['timestamp'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime);
                      });

                    return Column(
                      children: recipes.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final recipeName = data['name'] ?? 'No title';
                        final mealType = data['mealType'] ?? '';
                        final ingredients = data['ingredients'] ?? '';
                        final instructions = data['instructions'] ?? '';
                        final likes = Map<String, dynamic>.from(
                          data['likes'] ?? {},
                        );
                        final saves = Map<String, dynamic>.from(
                          data['saves'] ?? {},
                        );
                        final commentsCount = (data['commentsCount'] is int)
                            ? data['commentsCount'] as int
                            : 0;

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
                              // Post Header
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
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
                                        radius: 18,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.person,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FutureBuilder<Map<String, String>>(
                                        future: _getUserNames(currentUser.uid),
                                        builder: (context, snapshot) {
                                          final name = () {
                                            if (snapshot.hasData) {
                                              final f =
                                                  snapshot.data!['firstName'] ??
                                                  '';
                                              final l =
                                                  snapshot.data!['lastName'] ??
                                                  '';
                                              final full = [f, l]
                                                  .where((s) => s.isNotEmpty)
                                                  .join(' ');
                                              if (full.isNotEmpty) return full;
                                            }
                                            return currentUser.email
                                                    ?.split('@')
                                                    .first ??
                                                'User';
                                          }();
                                          final timeAgo = _formatTimestamp(
                                            data['timestamp'],
                                          );
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.dark,
                                                ),
                                              ),
                                              if (timeAgo.isNotEmpty)
                                                Text(
                                                  timeAgo,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.dark
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: AppColors.dark.withOpacity(0.6),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (val) async {
                                        if (val == 'edit') {
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
                                                  SnackBar(
                                                    content: const Text(
                                                      'Recipe deleted',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.success,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
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
                                                    backgroundColor:
                                                        Colors.red.shade400,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: AppColors.dark,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              const Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Remove',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Recipe Content with gradient header
                              Container(
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
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: mealColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
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
                                          const SizedBox(height: 2),
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
                                            color: AppColors.dark.withOpacity(
                                              0.3,
                                            ),
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
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Ingredients',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.dark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 327,

                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.light,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
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
                                    ],
                                    if (instructions.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.menu_book,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Instructions',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.dark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 327,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.light,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
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
                                    ],
                                  ],
                                ),
                              ),

                              // Action Buttons
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.light,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
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
                                              size: 22,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${likes.length}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _showCommentsBottomSheet(
                                          context,
                                          doc.id,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.comment_outlined,
                                              size: 22,
                                              color: AppColors.dark.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$commentsCount',
                                              style: TextStyle(
                                                color: AppColors.dark
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
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
                                              color: AppColors.secondary,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${saves.length}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
