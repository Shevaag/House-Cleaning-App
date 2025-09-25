import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'screens/starting_screen.dart';
import 'secrets.dart';

final ThemeData appTheme = ThemeData( //defines the overall styling for the app
  primarySwatch: Colors.blue, // Main color theme
  colorScheme: ColorScheme.light(
    primary: Colors.blue, // Primary color
    secondary: Colors.orange, // Accent color
    background: Colors.white, // Background color
    surface: Colors.white, // Surface color
    onPrimary: Colors.white, // Text color on primary color
    onSecondary: Colors.black, // Text color on secondary color
    onBackground: Colors.black, // Text color on background
    onSurface: Colors.black, // Text color on surface
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity, //adjust spacing for different platforms
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "",
        authDomain: "house-cleaning-app-d5253.firebaseapp.com",
        projectId: "house-cleaning-app-d5253",
        storageBucket: "house-cleaning-app-d5253.firebasestorage.app",
        messagingSenderId: "1077960793929",
        appId: "1:1077960793929:web:20da36f01c0c6625ba0498",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'House Cleaning App',
      theme: appTheme, // Apply the custom theme
      home: StartScreen(),
    );
  }
}