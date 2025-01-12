import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'screens/LoginScreen.dart';
import 'screens/HomePage.dart';
import 'screens/RegisterScreen.dart';  // Assuming you have a RegisterScreen widget.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Familicam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: FirebaseAuth.instance.currentUser == null
          ? '/login'
          : '/home', // Define initial route depending on user authentication status
      routes: {
        '/login': (context) =>  LoginScreen(),
        '/home': (context) => const MyHomePage(title: 'FAMILICAM'),
        '/register': (context) =>  RegisterScreen(), // Example route for registration
      },
      onGenerateRoute: (settings) {
        // Additional route handling can be added here if needed
        return MaterialPageRoute(
          builder: (context) {
            // Handling undefined routes
            return const Scaffold(
              body: Center(child: Text('Page not found')),
            );
          },
        );
      },
    );
  }
}


