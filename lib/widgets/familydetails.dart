import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../global.dart';

class FamilyDetails extends StatefulWidget {
  const FamilyDetails({Key? key}) : super(key: key);

  @override
  _FamilyDetailsState createState() => _FamilyDetailsState();
}

class _FamilyDetailsState extends State<FamilyDetails> {
  String _familyName = '';
  String _familyDescription = '';
  Color _familyThemeColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchFamilyDetails();
  }

  Future<void> _fetchFamilyDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      try {
        // Query Firestore for the family containing this user
        final snapshot = await FirebaseFirestore.instance
            .collection('families')
            .where('members', arrayContains: uid)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final familyData = snapshot.docs.first.data();

          setState(() {
            _familyName = familyData['name'] ?? 'Unknown Family';
            _familyDescription = familyData['description'] ?? 'No description available.';

            // Safely parse the theme color from string to Color
            final themeString = familyData['theme'] ?? 'FFFFFFFF'; // Default white
            _familyThemeColor = _parseColor(themeString);
            familyThemeColor = _familyThemeColor;  // Stores the color globally
          });
        } else {
          setState(() {
            _familyName = 'No family found';
            _familyDescription = '';
            _familyThemeColor = Colors.grey;
          });
        }
      } catch (e) {
        print('Error fetching family details: $e');
        setState(() {
          _familyName = 'Error loading family';
          _familyDescription = '';
          _familyThemeColor = Colors.grey;
        });
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.length == 6) {
        // Assume RGB; add full opacity (FF)
        colorString = 'FF$colorString';
      }
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      print('Error parsing color: $e');
      return Colors.white; // Fallback to white
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_familyName.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          //border: Border.all(color: Colors.deepPurpleAccent),
          borderRadius: BorderRadius.circular(16.0),
          color: _familyThemeColor.withOpacity(0.2),
        ),
        constraints: const BoxConstraints(
          maxWidth: 300, // Adjust width to fit content
          minWidth: 200, // Optional: prevent it from being too narrow
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Only take up as much space as needed
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _familyName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _familyDescription,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
