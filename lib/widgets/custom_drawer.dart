import 'dart:convert';
import 'package:ai_wallpaper/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart'; // Import the SettingsScreen
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBiometricSetting();
    _getAppVersion();
  }

  /// Load app version info
  Future<void> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}';
    });
  }

  /// Load user data (avatar & username) from Firestore or local cache
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedAvatar = prefs.getString('avatar_${widget.userId}');
    String? cachedUsername = prefs.getString('username_${widget.userId}');

    if (cachedAvatar != null && cachedUsername != null) {
      setState(() {
        _avatarBase64 = cachedAvatar;
        widget.userName = cachedUsername;
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
          // Uncomment the following ListTile if you want to add a subscription feature
          // ListTile(
          //   leading: Icon(Icons.subscriptions_rounded),
          //   title: const Text('Subscribe'),
          //   trailing: Lottie.asset(
          //     'assets/subscribe.json',
          //     height: 45,
          //     width: 45,
          //     repeat: true,
          //   ),
          //   onTap: () {
          //     // Handle subscription click here
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Subscribe tapped!')),
          //     );
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () async {
              // Navigate to SettingsScreen and wait for the result
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    userId: widget.userId,
                    userEmail: widget.userEmail,
                    userName: widget.userName,
                    avatarBase64: _avatarBase64,
                  ),
                ),
              );

              // Update the UI with the new username and avatar
              if (result != null) {
                setState(() {
                  widget.userName = result['username'];
                  _avatarBase64 = result['avatar'];
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Enable Biometric Authentication'),
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '   Version $_appVersion',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.photo_library, color: Colors.teal),
            title: Text(
              'Wallpapers provided by Pexels',
              style: TextStyle(fontSize: 14),
            ),
            onTap: () {
              // Optionally open Pexels website on tap
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Credits'),
                  content: Text(
                      'Images and wallpapers in this app are powered by Pexels (https://www.pexels.com).'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
