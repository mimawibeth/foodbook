import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'follow_list.dart';

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
        .orderBy('timestamp', descending: true)
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

    // Listen to the viewed user's followers/following counts
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
        action: SnackBarAction(
          label: 'Undo',
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
        action: SnackBarAction(
          label: 'Undo',
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
  Widget build(BuildContext context) {
    final isMe = FirebaseAuth.instance.currentUser?.uid == widget.userId;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        title: Text(
          widget.displayName,
          style: const TextStyle(color: Color(0xFFFAFAFA)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFAFAFA)),
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.groups,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$_followersCount followers',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_add_alt_1,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$_followingCount following',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMe)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? Colors.grey[700]
                          : const Color(0xFFD72638),
                    ),
                    onPressed: _toggleFollow,
                    child: Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(color: Color(0xFFFAFAFA)),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No posts yet'));
                }
                final docs = snapshot.data!.docs
                    .where((d) => !_hiddenRecipeIds.contains(d.id))
                    .toList();
                return ListView.builder(
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
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.displayName,
                                    style: const TextStyle(
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
                                        await FirebaseFirestore.instance
                                            .collection('recipes')
                                            .doc(recipeId)
                                            .delete();
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Post deleted'),
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
                                          child: ListTile(
                                            leading: Icon(Icons.delete),
                                            title: Text('Remove'),
                                          ),
                                        ),
                                      ];
                                    }
                                    return const [
                                      PopupMenuItem(
                                        value: 'hide_user',
                                        child: ListTile(
                                          leading: Icon(Icons.no_accounts),
                                          title: Text('Hide User'),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'hide',
                                        child: ListTile(
                                          leading: Icon(Icons.visibility_off),
                                          title: Text('Hide Post'),
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
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
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                  color: Colors.black12,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${likes.length}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  color: Colors.black12,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.black54,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$commentsCount',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (ingredients.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Ingredients:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(ingredients),
                            ],
                            if (instructions.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Instructions:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(instructions),
                            ],
                            const Divider(thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('${likes.length}'),
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
      ),
    );
  }
}
