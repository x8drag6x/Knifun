import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MetroAroundTehranApp());
}

class MetroAroundTehranApp extends StatelessWidget {
  const MetroAroundTehranApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0B5FFF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نزدیک مترو',
      theme: ThemeData(
        useMaterial3: true,
        // Traffic is registered in pubspec.yaml. Because the whole app is
        // themed here, every Text widget inherits the Traffic family unless
        // it explicitly overrides its own font family.
        fontFamily: 'Traffic',
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(),
      ),
    );
  }
}
