import 'dart:developer';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Allows users to view their profile, manage settings, logout, and delete account data

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
  with AutomaticKeepAliveClientMixin<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  // TODO: Add support for the user to change email
  final TextEditingController _emailController = TextEditingController();

  // Placeholder variables for Sprint 1
  bool isMusicMuted = false;
  bool isSoundMuted = false;
  bool _isSaving = false;

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    // Triggers data fetch on screen load
    _loadUserProfile();
  }

  // Fetching user's profile infrom from the 'users' collection in the database
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['username'] ?? user.displayName ?? '';
    } else {
      // fallback if doc doesn't exist
      _nameController.text = user.displayName ?? '';
    }

    setState(() {}); // refresh initials/avatar
  }

  // Gets username initials
  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // Saves user profile changes
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final username = _nameController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
      }, SetOptions(merge: true));
    } catch (e) {
      log('ERROR: Firestore write failed: $e');
    }

    setState(() => _isSaving = false);
  }

  // Log out functionality
  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed out')));
    }
  }

  // Delete account functionality
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account and all associated data? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();

          await user.delete();
          await AuthService.instance.signOut();
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Account deleted')));
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please sign in again before deleting your account for security reasons.',
                ),
              ),
            );
          }
        } else {
          rethrow;
        }
      }
    }
  }

  // Build for profile screen UI
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Text('Save Changes'),
          IconButton(
            onPressed: () {
              if (!_isSaving) {
                _saveProfile();
              }
            },
            icon: _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save changes',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.primary,
              child: _initials.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.white70)
                  : Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 5,),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 30),
          Text(
            'Audio Settings',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Mute Game Music'),
            value: isMusicMuted,
            onChanged: (value) => setState(() => isMusicMuted = value),
          ),
          SwitchListTile(
            title: const Text('Mute Sound Effects'),
            value: isSoundMuted,
            onChanged: (value) => setState(() => isSoundMuted = value),
          ),
          const Divider(height: 40),
          FilledButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blueGrey[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          SizedBox(height: 5),
          FilledButton.icon(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account & Data'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
