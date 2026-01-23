import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../features/wallpaper/presentation/screens/home_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../screens/settings_screen.dart';
import '../services/biometric_service.dart';

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
  late String _userName;
  bool _biometricEnabled = false;
  late BiometricService _biometricService;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _loadUserData();
    _loadBiometricSetting();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedAvatar = prefs.getString('avatar_${widget.userId}');
    String? cachedUsername = prefs.getString('username_${widget.userId}');

    if (cachedAvatar != null && cachedUsername != null) {
      if (mounted) {
        setState(() {
          _avatarBase64 = cachedAvatar;
          _userName = cachedUsername;
        });
      }
    } else {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (snapshot.exists && mounted) {
        setState(() {
          _avatarBase64 = snapshot['avatar'];
          _userName = snapshot['username'];
        });

        await prefs.setString('avatar_${widget.userId}', snapshot['avatar']);
        await prefs.setString(
            'username_${widget.userId}', snapshot['username']);
      }
    }
  }

  Future<void> _loadBiometricSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _biometricService = BiometricService(prefs);
    if (mounted) {
      setState(() {
        _biometricEnabled = _biometricService.isBiometricEnabled();
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (await _biometricService.isBiometricSupported()) {
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        await _biometricService.enableBiometric(value);
        if (mounted) {
          setState(() {
            _biometricEnabled = value;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Biometric authentication ${value ? 'enabled' : 'disabled'}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Authentication failed. Please try again.')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Biometric authentication is not supported on this device.')),
        );
      }
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
            accountName: Text(_userName),
            accountEmail: Text(widget.userEmail),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundImage: _avatarBase64 != null
                  ? MemoryImage(
                      base64Decode(_avatarBase64!))
                  : (FirebaseAuth.instance.currentUser?.photoURL != null
                          ? NetworkImage(FirebaseAuth
                              .instance.currentUser!.photoURL!)
                          : const AssetImage('assets/default_avatar.png'))
                      as ImageProvider,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    userId: widget.userId,
                    userEmail: widget.userEmail,
                    userName: _userName,
                    avatarBase64: _avatarBase64,
                  ),
                ),
              );

              if (result != null && mounted) {
                setState(() {
                  _userName = result['username'];
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
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Feedback'),
            onTap: () async {
              final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.Updesh.AIWallpaper');
              if (!await launchUrl(url)) {
                throw Exception('Could not launch $url');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await context.read<UserAuthProvider>().signOut();
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '   Version $_appVersion',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.teal),
            title: const Text(
              'Wallpapers provided by Pexels',
              style: TextStyle(fontSize: 14),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Credits'),
                  content: const Text(
                      'Images and wallpapers in this app are powered by Pexels (https://www.pexels.com).'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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
