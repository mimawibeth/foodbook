import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'other_profile.dart';

class FollowListPage extends StatelessWidget {
  final String userId;
  final String title; // "Followers" or "Following"
  final bool showFollowers; // true => followersIds, false => followingIds

  const FollowListPage({
    super.key,
    required this.userId,
    required this.title,
    required this.showFollowers,
  });

  Stream<List<String>> _idsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          final data = doc.data() ?? {};
          final List<dynamic> arr =
              (showFollowers ? data['followersIds'] : data['followingIds']) ??
              [];
          return arr.cast<String>();
        });
  }

  Future<Map<String, dynamic>?> _getUserDoc(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return snap.data();
  }

  String _displayNameFromData(
    Map<String, dynamic>? data,
    String fallbackEmailPrefix,
  ) {
    if (data == null) return fallbackEmailPrefix;
    final first = (data['firstName'] ?? '').toString().trim();
    final last = (data['lastName'] ?? '').toString().trim();
    final dn = (data['displayName'] ?? '').toString().trim();
    if (dn.isNotEmpty) return dn;
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : fallbackEmailPrefix;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        title: Text(title, style: const TextStyle(color: Color(0xFFFAFAFA))),
        iconTheme: const IconThemeData(color: Color(0xFFFAFAFA)),
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: StreamBuilder<List<String>>(
        stream: _idsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ids = snapshot.data!;
          if (ids.isEmpty) {
            return Center(
              child: Text(
                showFollowers ? 'No followers yet' : "Not following anyone",
              ),
            );
          }
          return ListView.separated(
            itemCount: ids.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final uid = ids[index];
              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserDoc(uid),
                builder: (context, snap) {
                  final data = snap.data;
                  // Fallback to email prefix if available from auth only at runtime
                  final emailPrefix = uid.substring(
                    0,
                    uid.length > 6 ? 6 : uid.length,
                  );
                  final name = _displayNameFromData(data, emailPrefix);
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(name),
                    onTap: () {
                      final currentUid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid.isEmpty || currentUid == uid) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtherUserProfilePage(
                            userId: uid,
                            displayName: name,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
