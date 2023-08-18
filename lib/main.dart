import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_search/screens/home_screen.dart';
import 'package:voice_search/utils/app_strings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeModel>(
      create: (context) => ThemeModel(), // Initialize the theme model
      child: Consumer<ThemeModel>(
        builder: (context, theme, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppStrings.voiceSearch,
            theme: theme.isDark
                ? ThemeData.dark(useMaterial3: true)
                : ThemeData(
                    useMaterial3: true,
                  ), // Use the selected theme
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

class ThemeModel with ChangeNotifier {
  bool _isDark = false; // Default to light theme

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners(); // Notify listeners to update the UI
  }
}
