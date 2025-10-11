import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'follow_list.dart';

// 🎨 Color Palette - Food themed (consistent across app)
class AppColors {
  static const primary = Color(0xFFFF6B35); // Warm Orange
  static const secondary = Color(0xFFFFBE0B); // Golden Yellow
  static const accent = Color(0xFFFB5607); // Vibrant Red-Orange
  static const dark = Color(0xFF2D3142); // Dark Blue-Gray
  static const light = Color(0xFFFFFBF0); // Cream White
  static const success = Color(0xFF06A77D); // Fresh Green
}

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  final String displayName;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  int _followersCount = 0;
  int _followingCount = 0;
  Stream<QuerySnapshot> _userRecipes() {
    return FirebaseFirestore.instance
        .collection('recipes')
        .where('userId', isEqualTo: widget.userId)
        .snapshots();
  }

  bool _isFollowing = false;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userDocStream;
  final Set<String> _hiddenRecipeIds = <String>{};

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userDocStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots();
      _userDocStream!.listen((doc) {
        final data = doc.data();
        final following =
            (data?['followingIds'] as List?)?.cast<String>() ??
            const <String>[];
        final hiddenRecipes =
            (data?['hiddenRecipeIds'] as List?)?.cast<String>() ??
            const <String>[];
        setState(() {
          _isFollowing = following.contains(widget.userId);
          _hiddenRecipeIds
            ..clear()
            ..addAll(hiddenRecipes);
        });
      });
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
          final data = doc.data() ?? {};
          final followers =
              (data['followersIds'] as List?)?.cast<String>() ??
              const <String>[];
          final following =
              (data['followingIds'] as List?)?.cast<String>() ??
              const <String>[];
          if (mounted) {
            setState(() {
              _followersCount = followers.length;
              _followingCount = following.length;
            });
          }
        });
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

  Future<void> _toggleLike(String recipeId, Map<String, dynamic> likes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final isLiked = likes.containsKey(uid);
    final recipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId);
    if (isLiked) {
      likes.remove(uid);
    } else {
      likes[uid] = true;
    }
    await recipeRef.update({'likes': likes});
  }

  Future<void> _toggleSave(String recipeId, Map<String, dynamic> saves) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final isSaved = saves.containsKey(uid);
    final recipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId);
    if (isSaved) {
      saves.remove(uid);
    } else {
      saves[uid] = true;
    }
    await recipeRef.update({'saves': saves});
  }

  Future<void> _toggleFollow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == widget.userId) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    if (_isFollowing) {
      await userDoc.set({
        'followingIds': FieldValue.arrayRemove([widget.userId]),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
            'followersIds': FieldValue.arrayRemove([uid]),
          }, SetOptions(merge: true));
    } else {
      await userDoc.set({
        'followingIds': FieldValue.arrayUnion([widget.userId]),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
            'followersIds': FieldValue.arrayUnion([uid]),
          }, SetOptions(merge: true));
    }
    setState(() => _isFollowing = !_isFollowing);
  }

  Future<void> _hidePost(String recipeId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _hiddenRecipeIds.add(recipeId));
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Post hidden'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () async {
            setState(() => _hiddenRecipeIds.remove(recipeId));
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'hiddenRecipeIds': FieldValue.arrayRemove([recipeId]),
            }, SetOptions(merge: true));
          },
        ),
      ),
    );
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'hiddenRecipeIds': FieldValue.arrayUnion([recipeId]),
    }, SetOptions(merge: true));
  }

  Future<void> _hideUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == widget.userId) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('User hidden'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () async {
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'hiddenUserIds': FieldValue.arrayRemove([widget.userId]),
            }, SetOptions(merge: true));
          },
        ),
      ),
    );
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'hiddenUserIds': FieldValue.arrayUnion([widget.userId]),
    }, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream(String recipeId) {
    return FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
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
            child: Text('Save', style: TextStyle(color: AppColors.primary)),
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
    final isMe = FirebaseAuth.instance.currentUser?.uid == widget.userId;
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
        title: Text(
          widget.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Profile Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
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
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowListPage(
                                      userId: widget.userId,
                                      title: 'Followers',
                                      showFollowers: true,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.groups,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '$_followersCount',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowListPage(
                                      userId: widget.userId,
                                      title: 'Following',
                                      showFollowers: false,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_add_alt_1,
                                      size: 16,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '$_followingCount',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMe) const SizedBox(width: 12),
                if (!isMe)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? AppColors.dark
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _toggleFollow,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFollowing ? Icons.check : Icons.person_add,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userRecipes(),
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
                          Icons.receipt_long_outlined,
                          size: 100,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This user hasn\'t shared any recipes',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dark.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final docs =
                    snapshot.data!.docs
                        .where((d) => !_hiddenRecipeIds.contains(d.id))
                        .toList()
                      ..sort((a, b) {
                        final ad = a.data() as Map<String, dynamic>;
                        final bd = b.data() as Map<String, dynamic>;
                        final at = ad['timestamp'];
                        final bt = bd['timestamp'];
                        if (at is Timestamp && bt is Timestamp) {
                          return bt.compareTo(at);
                        }
                        return 0;
                      });
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['name'] ?? '';
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
                        ? (data['commentsCount'] as int)
                        : 0;
                    final recipeId = docs[index].id;

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
                                  child: Text(
                                    widget.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.dark,
                                    ),
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
                                  onSelected: (value) async {
                                    final isMe =
                                        FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.uid ==
                                        widget.userId;
                                    if (isMe && value == 'delete') {
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
                                              .doc(recipeId)
                                              .delete();
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Post deleted',
                                              ),
                                              backgroundColor:
                                                  AppColors.success,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to delete: $e',
                                              ),
                                              backgroundColor:
                                                  Colors.red.shade400,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else if (!isMe && value == 'hide') {
                                      await _hidePost(recipeId);
                                    } else if (!isMe && value == 'hide_user') {
                                      await _hideUser();
                                    }
                                  },
                                  itemBuilder: (context) {
                                    final isMe =
                                        FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.uid ==
                                        widget.userId;
                                    if (isMe) {
                                      return const [
                                        PopupMenuItem(
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
                                      ];
                                    }
                                    return [
                                      PopupMenuItem(
                                        value: 'hide_user',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.no_accounts,
                                              color: AppColors.dark,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('Hide User'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'hide',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.visibility_off,
                                              color: AppColors.dark,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('Hide Post'),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                            title,
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
                              ],
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
                                        color: AppColors.dark.withOpacity(0.8),
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
                                        color: AppColors.dark.withOpacity(0.8),
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
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.light,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  InkWell(
                                    onTap: () => _toggleLike(recipeId, likes),
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
                                      recipeId,
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
                                            color: AppColors.dark.withOpacity(
                                              0.7,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _toggleSave(recipeId, saves),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
