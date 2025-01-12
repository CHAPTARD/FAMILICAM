import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({Key? key}) : super(key: key);

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  List<String> mediaUrls = [];

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    try {
      final ListResult result = await FirebaseStorage.instance.ref().listAll();
      final List<String> urls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()).toList(),
      );
      setState(() {
        mediaUrls = urls;
      });
    } catch (e) {
      print('Failed to fetch media: $e');
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        // Upload file to Firebase Storage
        await FirebaseStorage.instance.ref(fileName).putFile(file);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );

        // Refresh media list
        _fetchMedia();
      }
    } catch (e) {
      print('Failed to upload file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload File',
            onPressed: _uploadFile,
          ),
        ],
        automaticallyImplyLeading: false, // Disable the back arrow
      ),
      body: mediaUrls.isEmpty
          ? const Center(child: Text('No media available.'))
          : ListView.builder(
              itemCount: mediaUrls.length,
              itemBuilder: (context, index) {
                final mediaUrl = mediaUrls[index];
                return ListTile(
                  title: Text('File ${index + 1}'),
                  subtitle: Text(mediaUrl),
                  onTap: () {
                    // Open the file in a browser
                    // Use a package like url_launcher to launch the link
                  },
                );
              },
            ),
    );
  }
}
