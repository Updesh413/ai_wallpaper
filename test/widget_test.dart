// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_wallpaper/widgets/glass/glass_container.dart';
import 'package:ai_wallpaper/widgets/glass/glass_text_field.dart';
import 'package:ai_wallpaper/widgets/glass/glass_button.dart';
import 'package:ai_wallpaper/widgets/glass/glass_bottom_nav_bar.dart';
import 'package:ai_wallpaper/theme/app_theme.dart';

void main() {
  testWidgets('Glass UI Components render correctly in Light & Dark mode', (WidgetTester tester) async {
    final emailController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: GlassContainer(
            child: Column(
              children: [
                GlassTextField(
                  controller: emailController,
                  hintText: 'Enter Email',
                  prefixIcon: const Icon(Icons.email),
                ),
                GlassGradientButton(
                  text: 'Sign In',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Enter Email'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(GlassContainer), findsOneWidget);
    expect(find.byType(GlassGradientButton), findsOneWidget);
  });

  testWidgets('GlassBottomNavBar renders and responds to tap', (WidgetTester tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: GlassBottomNavBar(
                currentIndex: selectedIndex,
                onTap: (i) {
                  setState(() => selectedIndex = i);
                },
                items: const [
                  GlassBottomNavBarItem(
                    icon: Icons.grid_view_rounded,
                    label: "Home",
                  ),
                  GlassBottomNavBarItem(
                    icon: Icons.explore_rounded,
                    label: "Explore",
                  ),
                  GlassBottomNavBarItem(
                    icon: Icons.favorite_rounded,
                    label: "Favorites",
                  ),
                  GlassBottomNavBarItem(
                    icon: Icons.person_rounded,
                    label: "Profile",
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(find.byType(GlassBottomNavBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.explore_rounded));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
    expect(find.text('Explore'), findsOneWidget);
  });
}
