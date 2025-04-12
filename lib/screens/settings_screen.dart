import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  String userName;
  String? avatarBase64;

  SettingsScreen({
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.avatarBase64,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.userName;
    _avatarBase64 = widget.avatarBase64;
  }

  /// Open image picker and upload selected image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      String base64String = base64Encode(bytes);

      setState(() {
        _avatarBase64 = base64String;
      });
    }
  }

  /// Save user details to Firestore and SharedPreferences
  Future<void> _saveUserDetails() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    // Save data to Firestore
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).set(
      {
        'avatar': _avatarBase64,
        'username': newUsername,
      },
      SetOptions(merge: true),
    );

    // Save locally
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_${widget.userId}', _avatarBase64 ?? '');
    await prefs.setString('username_${widget.userId}', newUsername);

    // Notify the parent widget (CustomDrawer) to update the UI
    Navigator.pop(context, {
      'username': newUsername,
      'avatar': _avatarBase64,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveUserDetails,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatarBase64 != null
                    ? MemoryImage(base64Decode(_avatarBase64!))
                    : (FirebaseAuth.instance.currentUser?.photoURL != null
                            ? NetworkImage(
                                FirebaseAuth.instance.currentUser!.photoURL!)
                            : AssetImage('assets/default_avatar.png'))
                        as ImageProvider,
                child: _avatarBase64 == null &&
                        FirebaseAuth.instance.currentUser?.photoURL == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
