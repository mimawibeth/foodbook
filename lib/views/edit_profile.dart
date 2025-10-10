import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;

  const EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstController;
  late TextEditingController _lastController;
  late TextEditingController _displayController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstController = TextEditingController();
    _lastController = TextEditingController();
    _displayController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final data = doc.data() ?? {};
    _firstController.text = (data['firstName'] ?? '').toString();
    _lastController.text = (data['lastName'] ?? '').toString();
    _displayController.text = (data['displayName'] ?? '').toString();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final first = _firstController.text.trim();
    final last = _lastController.text.trim();
    final display = _displayController.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
            'firstName': first,
            'lastName': last,
            if (display.isNotEmpty) 'displayName': display,
          }, SetOptions(merge: true));

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.updateDisplayName(display.isNotEmpty ? display : null);
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _displayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD72638),
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstController,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty &&
                      _displayController.text.trim().isEmpty) {
                    return 'Please provide a first name or display name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastController,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayController,
                decoration: const InputDecoration(labelText: 'Display name'),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty &&
                      _firstController.text.trim().isEmpty) {
                    return 'Please provide a display name or first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD72638),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
