import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool isMusicMuted = false;
  bool isSoundMuted = false;
  bool _isSaving = false;

  // --Name Icon--
  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }  

  // -- Save name edits
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));  //saving

    // TODO: save edits to Firebase

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  // --sign out logic
  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    }
  }

  // --Delete account + data
  Future<void> _deleteAccount() async {
    final confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure want to premanently delete your account and all assciated data? '
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
      // TODO: Delete user data Firebase
      await AuthService.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Text('Save Changes'),
          IconButton(
            onPressed: _isSaving ? null : _saveProfile,
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

          // -- profile avatar
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

          //name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 10),

          //email
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.mail),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 30),

          Text(
            'Audio Settings',
            style:
              theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
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


          //--sign out
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

          //delete account
          FilledButton.icon(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account & Data'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            )
          ),
        ],
      ),
    );

  }

/*
  @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Text(
                            'Logged in!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                            '(### temporary ###)',
                            style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                            onPressed: () async {
                                await AuthService.instance.signOut();
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign out'),
                        ),
                    ],
                ),
            ),
        );
    }

  */  
}