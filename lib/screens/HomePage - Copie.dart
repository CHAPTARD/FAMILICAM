import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'LoginScreen.dart';
//import 'FamilyProfile.dart';
import '../widgets/challenges.dart';
import '../widgets/familydetails.dart';
import '../global.dart';

Future<String?> _getUserFamilyId() async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final userSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  return userSnapshot['family'];
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _widgets = [
    const FamilyDetails(), // Show family details here
    //FamilyProfileScreen(),
    ChallengesWidget(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Ensures the body extends behind the AppBar
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: familyThemeColor,
            fontFamily: 'MyCustomFont',
            fontSize: 48,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 0, 204, 255)),
            onPressed: _logout,
          ),
        ],
        automaticallyImplyLeading: false, // Disable the back arrow
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: _widgets[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(0, 0, 0, 0).withOpacity(0.5), // Semi-transparent background
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.5), width: 0.5), // Optional border
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // Transparent background
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: familyThemeColor, // Color of the selected label and icon
          unselectedItemColor: Colors.white, // Color of the unselected label and icon
          showSelectedLabels: true, // Show labels for selected items
          showUnselectedLabels: true, // Show labels for unselected items
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom_rounded),
              label: 'Family',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo),
              label: 'Media',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Challenges',
            ),
          ],
        ),
      ),
    );
  }
}
