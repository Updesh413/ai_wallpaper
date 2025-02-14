import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/login_screen.dart';

class CustomDrawer extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String? photoURL;

  const CustomDrawer({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.photoURL,
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  /// Load avatar from Firestore or local cache
  Future<void> _loadAvatar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedAvatar = prefs.getString('avatar_${widget.userId}');

    if (cachedAvatar != null) {
      setState(() {
        _avatarBase64 = cachedAvatar;
      });
    } else {
      // Fetch from Firestore if not found locally
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (snapshot.exists && snapshot['avatar'] != null) {
        setState(() {
          _avatarBase64 = snapshot['avatar'];
        });

        // Save to local cache
        await prefs.setString('avatar_${widget.userId}', snapshot['avatar']);
      }
    }
  }

  /// Open image picker and upload selected image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      String base64String = base64Encode(bytes);

      // Save avatar to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({'avatar': base64String}, SetOptions(merge: true));

      // Save locally for faster loading
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_${widget.userId}', base64String);

      setState(() {
        _avatarBase64 = base64String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/img4.webp'), fit: BoxFit.cover),
            ),
            accountName: Text(widget.userName),
            accountEmail: Text(widget.userEmail),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundImage: FirebaseAuth.instance.currentUser?.photoURL !=
                      null
                  ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                  : AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
