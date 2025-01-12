import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:flutter_application_2/global.dart';

const String uploadServerUrl = "http://192.168.1.32:8000/api/upload"; // Ensure this is the correct URL for your server
const String fileAccessUrlBase = "http://192.168.1.32:8000"; // Base URL for accessing uploaded files

Future<void> FileUploader({
  required String filePath,
  required String classType,
  String? familyId,
  String? challengeId,
  required bool isPrivate,
  required Function(bool) onUploading,
}) async {
  // Fetch user details
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }

  // Determine the upload path and filename based on classType
  String uploadPath;
  String uploadFileName;
  final file = File(filePath);
  final originalFileName = basename(filePath); // Extract original file name

  if (classType == 'families' && familyId != null) {
    uploadPath = "families/$familyId";
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    uploadFileName = "User[${user.uid}]Family[$familyId]Date[$now]Original[$originalFileName";
  } else if (classType == 'challenges' && challengeId != null) {
    uploadPath = "challenges/$challengeId";
    final privacy = isPrivate ? "true" : "false";
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    uploadFileName =
        "User[${user.uid}]Family[$familyId]Challenge[$challengeId]Privacy[$privacy]Date[$now]Original[$originalFileName";
  } else {
    throw Exception("Invalid classType or missing familyId/challengeId");
  }

  print('Uploading file to: $uploadPath/$uploadFileName');

  // Send the file via HTTP POST with pathName query parameter
  final request = http.MultipartRequest('POST', Uri.parse("$uploadServerUrl?pathName=$uploadPath"))
    ..files.add(await http.MultipartFile.fromPath('file', filePath, filename: uploadFileName));

  onUploading(true);
  final response = await request.send();
  onUploading(false);

  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    final uploadedFileUrl = "$fileAccessUrlBase/$uploadPath/$uploadFileName";

    print('File uploaded successfully: $uploadedFileUrl');

    // Update Firestore with the uploaded file URL
    if (classType == 'families' && familyId != null) {
      final familyDocRef = FirebaseFirestore.instance.collection('families').doc(familyId);
      await familyDocRef.update({
        'media': FieldValue.arrayUnion([uploadedFileUrl]),
      });
      print('Family media updated successfully');
    } else if (classType == 'challenges' && challengeId != null) {
      final challengeDocRef = FirebaseFirestore.instance.collection('challenges').doc(challengeId);
      await challengeDocRef.update({
        'media': FieldValue.arrayUnion([uploadedFileUrl]),
      });
      print('Challenge media updated successfully');
    }
  } else {
    final responseBody = await response.stream.bytesToString();
    print('Error uploading file: $responseBody');
    throw Exception('Failed to upload file: ${response.reasonPhrase}');
  }
}

/*
import 'package:flutter_application_2/global.dart';
const String uploadServerUrl = "http://192.168.1.32:8000/api/upload"; //use https://www.npmjs.com/package/files-upload-server

Future<void> FileUploader({
  required String filePath,
  required bool isPrivate,
  required Function(bool) onUploading,
  required String classType,
  String? familyId,
  String? challengeId,
}) async {
  try {
    // Notify UI that upload has started
    onUploading(true);

    // Fetch user details
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    // Determine the upload path and filename based on classType
    String uploadPath;
    String uploadFileName;
    final file = File(filePath);
    final originalFileName = basename(filePath); // Extract original file name

    if (classType == 'families' && familyId != null) {
      uploadPath = "upload/families/$familyId";
      uploadFileName = "User[${user.uid}]Original[$originalFileName";
    } else if (classType == 'challenges') {
      // Fetch the family ID
      final familyId = await getUserFamilyId();
      if (familyId == null) {
        throw Exception("Could not fetch family ID for user");
      }

      uploadPath = "upload/challenges/$challengeId";
      final privacy = isPrivate ? "true" : "false";
      final now = DateTime.now().toIso8601String().replaceAll(':', '-');
      uploadFileName =
          "User[${user.uid}]Family[${familyId}]Challenge[${challengeId}]Privacy[${privacy}]Date[${now}]Original[${originalFileName}]";
    } else {
      throw Exception("Invalid classType or missing familyId");
    }

    // Send the file via HTTP POST
    final request = http.MultipartRequest('POST', Uri.parse("$uploadServerUrl/$uploadPath"))
      ..files.add(await http.MultipartFile.fromPath(
        'files',
        filePath,
        filename: uploadFileName,
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      print("File uploaded successfully.");

      // Update Firestore with the file's metadata
      final fileUrl = "$uploadServerUrl/$uploadPath/$uploadFileName";
      await FirebaseFirestore.instance.collection('challenges').doc(challengeId).update({
        'media': FieldValue.arrayUnion([fileUrl]),
      });
    } else {
      throw Exception("File upload failed with status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error uploading file: $e");
    rethrow; // Re-throw the error to handle in UI
  } finally {
    // Notify UI that upload has completed
    onUploading(false);
  }
}
*/