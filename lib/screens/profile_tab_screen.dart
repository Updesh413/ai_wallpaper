import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../services/biometric_service.dart';
import '../services/favorites_service.dart';
import '../widgets/glass/glass_container.dart';
import '../theme/app_theme.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  String? _avatarBase64;
  String _userName = 'User';
  String _userEmail = '';
  String _userId = '';
  bool _biometricEnabled = false;
  late BiometricService _biometricService;
  String _appVersion = '2.0.0';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadBiometricSetting();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _userEmail = user.email ?? '';
      _userName = user.displayName ?? 'User';

      final prefs = await SharedPreferences.getInstance();
      final cachedAvatar = prefs.getString('avatar_$_userId');
      final cachedUsername = prefs.getString('username_$_userId');

      if (cachedAvatar != null || cachedUsername != null) {
        if (mounted) {
          setState(() {
            if (cachedAvatar != null) _avatarBase64 = cachedAvatar;
            if (cachedUsername != null && cachedUsername.isNotEmpty) {
              _userName = cachedUsername;
            }
          });
        }
      }

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();

        if (snapshot.exists && mounted) {
          final data = snapshot.data();
          if (data != null) {
            setState(() {
              if (data['avatar'] != null && (data['avatar'] as String).isNotEmpty) {
                _avatarBase64 = data['avatar'];
                prefs.setString('avatar_$_userId', _avatarBase64!);
              }
              if (data['username'] != null && (data['username'] as String).isNotEmpty) {
                _userName = data['username'];
                prefs.setString('username_$_userId', _userName);
              }
            });
          }
        }
      } catch (e) {
        debugPrint("Error fetching user from Firestore: $e");
      }
    }
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
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
          setState(() => _biometricEnabled = value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Biometric authentication ${value ? 'enabled' : 'disabled'}',
              ),
              backgroundColor: value ? Colors.green.shade700 : const Color(0xFF1E293B),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Authentication failed. Please try again.'),
              backgroundColor: Colors.redAccent.shade700,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication is not supported on this device.'),
          ),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        Uint8List bytes = await pickedFile.readAsBytes();
        
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 400,
          minHeight: 400,
          quality: 60,
        );
        final compressedBase64 = base64Encode(compressedBytes);

        if (_userId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(_userId).set(
            {'avatar': compressedBase64},
            SetOptions(merge: true),
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('avatar_$_userId', compressedBase64);
        }

        if (mounted) {
          setState(() {
            _avatarBase64 = compressedBase64;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Avatar updated successfully!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: $e'),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
    }
  }

  void _editUsernameDialog() {
    final controller = TextEditingController(text: _userName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Edit Username",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: "Enter your username",
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && _userId.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _userName = newName);

                await FirebaseFirestore.instance.collection('users').doc(_userId).set(
                  {'username': newName},
                  SetOptions(merge: true),
                );

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('username_$_userId', newName);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Username updated successfully!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showCreditsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.photo_library_rounded, color: Color(0xFF0072FF)),
            const SizedBox(width: 10),
            Text(
              "Credits & Attribution",
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "High-definition wallpapers in this application are proudly powered by Pexels API.\n\nAll photos are free to use under the Pexels License. Respect photographer copyright by clicking on photographer names.",
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Sign Out",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "Are you sure you want to sign out of your account?",
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<FavoritesService>().clearForLogout();
      await context.read<UserAuthProvider>().signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const LoginScreen(),
            transitionsBuilder: (context, a1, a2, child) =>
                FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    ImageProvider avatarImage;
    if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
      avatarImage = MemoryImage(base64Decode(_avatarBase64!));
    } else if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
      avatarImage = NetworkImage(currentUser.photoURL!);
    } else {
      avatarImage = const AssetImage('assets/default_avatar.png');
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 170),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Profile & Settings",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Header Glass Card
            GlassContainer(
              blur: 24,
              borderRadius: 28,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar with Edit Button
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                              : Image(
                                  image: avatarImage,
                                  fit: BoxFit.cover,
                                  width: 76,
                                  height: 76,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: AppTheme.primaryGradient,
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Name & Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _userName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              color: AppTheme.primaryLightColor,
                              onPressed: _editUsernameDialog,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail.isNotEmpty ? _userEmail : 'Logged in user',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader("Preferences", isDark),
            const SizedBox(height: 10),
            GlassContainer(
              blur: 20,
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: const Color(0xFF0072FF),
                    title: "Biometric Login",
                    subtitle: "Unlock app with fingerprint or Face ID",
                    trailing: Switch.adaptive(
                      value: _biometricEnabled,
                      activeTrackColor: AppTheme.primaryColor,
                      onChanged: _toggleBiometric,
                    ),
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSettingTile(
                    icon: Icons.brightness_auto_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "Theme Mode",
                    subtitle: "Follows System Default",
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      child: Text(
                        "System",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // General Section
            _buildSectionHeader("General", isDark),
            const SizedBox(height: 10),
            GlassContainer(
              blur: 20,
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.rate_review_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "Send Feedback",
                    subtitle: "Rate us or request new features",
                    onTap: () async {
                      final Uri url = Uri.parse(
                        'https://play.google.com/store/apps/details?id=com.Updesh.AIWallpaper',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSettingTile(
                    icon: Icons.photo_library_rounded,
                    iconColor: const Color(0xFF06B6D4),
                    title: "Wallpaper Credits",
                    subtitle: "Powered by Pexels API",
                    onTap: _showCreditsDialog,
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSettingTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF64748B),
                    title: "App Version",
                    subtitle: "v$_appVersion",
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Section
            GlassContainer(
              blur: 20,
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildSettingTile(
                icon: Icons.logout_rounded,
                iconColor: Colors.redAccent,
                title: "Sign Out",
                subtitle: "Sign out of this device",
                onTap: _logout,
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.redAccent,
                ),
                isDark: isDark,
                titleColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: iconColor.withValues(alpha: 0.15),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      trailing: trailing,
    );
  }
}
