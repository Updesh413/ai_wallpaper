import 'package:flutter/material.dart';
import 'custom_drawer.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final String userId;
  final String userEmail;
  final String userName;
  final String title;

  const CustomScaffold({
    super.key,
    required this.body,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
      ),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: body,
    );
  }
}
