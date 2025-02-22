import 'dart:convert';
import 'dart:typed_data';
import 'package:ai_wallpaper/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart'; // Add this import
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class CustomDrawer extends StatefulWidget {
  final String userId;
  final String userEmail;
  String userName;
  final String? photoURL;

  CustomDrawer({
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
  bool _biometricEnabled = false; // Track biometric state
  late BiometricService _biometricService; // Biometric service instance

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBiometricSetting();
  }

  /// Load user data (avatar & username) from Firestore or local cache
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedAvatar = prefs.getString('avatar_${widget.userId}');
    String? cachedUsername = prefs.getString('username_${widget.userId}');

    if (cachedAvatar != null && cachedUsername != null) {
      setState(() {
        _avatarBase64 = cachedAvatar;
      });
    } else {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _avatarBase64 = snapshot['avatar'];
          widget.userName = snapshot['username']; // Update username
        });

        // Save to local cache
        await prefs.setString('avatar_${widget.userId}', snapshot['avatar']);
        await prefs.setString(
            'username_${widget.userId}', snapshot['username']);
      }
    }
  }

  /// Load biometric setting from SharedPreferences
  Future<void> _loadBiometricSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _biometricService = BiometricService(prefs); // Initialize biometric service
    setState(() {
      _biometricEnabled = _biometricService.isBiometricEnabled();
    });
  }

  /// Toggle biometric authentication
  Future<void> _toggleBiometric(bool value) async {
    print("Toggling biometric authentication: $value");

    if (await _biometricService.isBiometricSupported()) {
      print("Biometric authentication is supported.");
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        print("Biometric authentication successful.");
        await _biometricService.enableBiometric(value);
        setState(() {
          _biometricEnabled = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Biometric authentication ${value ? 'enabled' : 'disabled'}')),
        );
      } else {
        print("Biometric authentication failed.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication failed. Please try again.')),
        );
      }
    } else {
      print("Biometric authentication is not supported.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Biometric authentication is not supported on this device.')),
      );
    }
  }

  /// Open image picker and upload selected image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      String base64String = base64Encode(bytes);

      // Ask for username if missing
      String newUsername = widget.userName;
      if (widget.userName == 'User') {
        newUsername = await _promptForUsername();
      }

      // Save data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set(
        {'avatar': base64String, 'username': newUsername},
        SetOptions(merge: true),
      );

      // Save locally
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_${widget.userId}', base64String);
      await prefs.setString('username_${widget.userId}', newUsername);

      setState(() {
        _avatarBase64 = base64String;
        widget.userName = newUsername;
      });
    }
  }

  /// Prompt user to enter a username
  Future<String> _promptForUsername() async {
    String username = '';
    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text("Set Username"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter username"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                username = controller.text;
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    return username.isNotEmpty ? username : "User";
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
                image: AssetImage('assets/img4.webp'),
                fit: BoxFit.cover,
              ),
            ),
            accountName: Text(widget.userName),
            accountEmail: Text(widget.userEmail),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundImage: _avatarBase64 != null
                  ? MemoryImage(
                      base64Decode(_avatarBase64!)) // Load from Firestore
                  : (FirebaseAuth.instance.currentUser?.photoURL != null
                          ? NetworkImage(FirebaseAuth
                              .instance.currentUser!.photoURL!) // Google login
                          : AssetImage('assets/default_avatar.png'))
                      as ImageProvider, // Default image
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  userId: widget.userId,
                  userEmail: widget.userEmail,
                  userName: widget.userName,
                ),
              ),
            ),
          ),
          // Add the biometric switch here
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Enable Biometric Authentication'),
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ),
          // In your logout button (e.g., in CustomDrawer)
          // In your logout button (e.g., in CustomDrawer)
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              final authService = AuthService();
              await authService
                  .clearAuthState(); // Clear Firebase and Google auth state
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Clear SharedPreferences
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
