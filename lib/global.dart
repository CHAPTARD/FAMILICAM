import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Color> getFamilyThemeColor() async {
  final familyId = await getUserFamilyId();
  if (familyId != null) {
    final themeData = await lookupFunction('theme');
    if (themeData.containsKey(familyId)) {
      String colorString = themeData[familyId];
      if (!colorString.startsWith('#')) {
        colorString = '#$colorString';
      }
      try {
        return Color(int.parse(colorString.replaceFirst('#', '0xff')));
      } catch (e) {
        print('Error parsing color string: $colorString');
        return Colors.white; // Default value if parsing fails
      }
    }
  }
  return Colors.white;  // Default value if no theme is found
}

Future<Color> familyThemeColor = getFamilyThemeColor();
Color dark = Color(0xFF19162a);

/// Fetches a map of family document IDs to the requested field value.
/// Example: lookupFunction('theme') -> {familyID1: '#FFFFFF', familyID2: '#FF5733'}
Future<Map<String, dynamic>> lookupFunction(String field) async {
  try {
    // Fetch all documents from the 'families' collection
    final snapshot = await FirebaseFirestore.instance.collection('families').get();

    // Map to store the results
    final Map<String, dynamic> result = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey(field)) {
        result[doc.id] = data[field];
      }
    }

    return result;
  } catch (e) {
    print('Error in lookupFunction: $e');
    return {};
  }
}

/// Fetches the family document ID of the current user.
/// Returns the family document ID if found, or null if the user does not belong to any family.
Future<String?> getUserFamilyId() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user is currently logged in.');
      return null;
    }

    final uid = user.uid;

    // Query Firestore to find the family the user belongs to
    final snapshot = await FirebaseFirestore.instance
        .collection('families')
        .where('members', arrayContains: uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id; // Return the document ID of the first matching family
    } else {
      print('User does not belong to any family.');
      return null;
    }
  } catch (e) {
    print('Error in getUserFamilyId: $e');
    return null;
  }
}
