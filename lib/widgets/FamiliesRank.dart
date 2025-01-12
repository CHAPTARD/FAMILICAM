import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../global.dart';
import 'FamilySpecific.dart';

class FamiliesRank extends StatefulWidget {
  @override
  _FamiliesRankState createState() => _FamiliesRankState();
}

class _FamiliesRankState extends State<FamiliesRank> {
  Future<List<Family>> _fetchFamilies() async {
    try {
      final names = await lookupFunction('name');
      final descriptions = await lookupFunction('description');
      final themes = await lookupFunction('theme');
      final points = await lookupFunction('points');

      List<Family> families = [];
      names.forEach((id, name) {
        try {
          final description = descriptions[id] ?? '';
          final themeColorString = themes[id] ?? '#FFFFFF'; // Default color if empty
          final pointsValue = points[id] as int; // Direct cast to int

          Color themeColor;
          try {
            if (themeColorString.length == 7 && themeColorString.startsWith('#')) {
              themeColor = Color(int.parse(themeColorString.replaceFirst('#', '0xff')));
            } else {
              themeColor = Color.fromARGB(255, 48, 48, 48); // Default to white if invalid format
            }
          } catch (e) {
            themeColor = Color.fromARGB(255, 48, 48, 48); // Default to white if parsing fails
          }

          families.add(Family(
            id: id,
            name: name,
            description: description,
            points: pointsValue,
            themeColor: themeColor,
          ));
        } catch (e) {
          print('Error processing family ID: $id, Error: $e');
        }
      });

      // Sort by points in descending order
      families.sort((a, b) => b.points.compareTo(a.points));

      return families;
    } catch (e) {
      print('Error fetching families: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Family>>(
      future: _fetchFamilies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No families found'));
        }

        final families = snapshot.data!;
        return ListView.builder(
          itemCount: families.length,
          itemBuilder: (context, index) {
            final family = families[index];
            final textColor = Colors.white;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FamilySpecific(familyID: family.id),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(16.0),
                margin: EdgeInsets.symmetric(horizontal: 34.0),
                decoration: BoxDecoration(
                  color: family.themeColor,
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                    color: Colors.white, // Black outline
                    width: 12.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      family.name,
                      style: TextStyle(fontFamily: 'MyCustomFont', fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      '${family.points} pts',
                      style: TextStyle(fontFamily: 'MyCustomFont',fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class Family {
  final String id;
  final String name;
  final String description;
  final int points;
  final Color themeColor;

  Family({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.themeColor,
  });
}