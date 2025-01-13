import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'LoginScreen.dart';
import '../widgets/Chat.dart';
import '../widgets/challenges.dart';
import '../widgets/FamiliesRank.dart'; // Correct import for FamiliesRank
import '../widgets/FamilySpecific.dart';
import '../global.dart';
import '../functions/CustomIcons.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _widgets = [
    FamiliesRank(),
    ChallengesWidget(),
    FutureBuilder<String?>(
      future: getUserFamilyId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Waiting for family ID...');
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          print('No family ID found');
          return Center(child: Text('No family ID found'));
        }

        final familyID = snapshot.data!;
        print('Family ID: $familyID');
        return FamilySpecific(familyID: familyID);
      },
    ),
  ];

  void _onItemTapped(int index) {
    print('BottomNavigationBar tapped: index = $index, _currentIndex = $_currentIndex');
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
    print('Building MyHomePage: _currentIndex = $_currentIndex');
    return FutureBuilder<Color>(
      future: getFamilyThemeColor(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No theme color found'));
        }

        final familyThemeColor = snapshot.data!;

        return WillPopScope(
          onWillPop: () async => false,  // This prevents back button
          child: Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white, //familyThemeColor,
                  fontFamily: 'MyCustomFont',
                  fontSize: 36,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat, color: Color.fromARGB(255, 255, 255, 255)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ChatPage(isFamilyChat: true)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color.fromARGB(255, 0, 204, 255)),
                  onPressed: _logout,
                ),
              ],
              automaticallyImplyLeading: false,
            ),
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              // Replace PageView with IndexedStack
              child: IndexedStack(
                index: _currentIndex,
                children: _widgets,
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(0, 0, 0, 0).withOpacity(0.5),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.5), width: 0.5),
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: dark,
                currentIndex: _currentIndex,
                onTap: _onItemTapped,
                selectedItemColor: familyThemeColor == const Color(0xFF19162A) ? const Color.fromARGB(255, 91, 91, 99) : familyThemeColor,
                unselectedItemColor: Colors.white,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                items: const [
                    BottomNavigationBarItem(
                    icon: Icon(CustomIcons.familiesrank, size: 38),
                    label: 'Ranking',
                    ),
                    BottomNavigationBarItem(
                    icon: Icon(CustomIcons.challenges, size: 38),
                    label: 'Challenges',
                    ),
                    BottomNavigationBarItem(
                    icon: Icon(CustomIcons.familyspecific, size: 28),
                    label: 'Family',
                    ),
                ],
              ),
            ),
          )
        );
      },
    );
  }
}

