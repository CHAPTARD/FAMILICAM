import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'package:http/http.dart' as http;
import '../global.dart'; // Ensure this contains the lookupFunction and FileUploader
import '../functions/FileUpload.dart';



class FamilySpecific extends StatefulWidget {
  final String familyID;

  const FamilySpecific({Key? key, required this.familyID}) : super(key: key);

  @override
  _FamilySpecificState createState() => _FamilySpecificState();
}

class _FamilySpecificState extends State<FamilySpecific> {
  String familyName = '';
  String familyDescription = '';
  String familyLogo = '';
  List<String> mediaUrls = [];
  bool isUploading = false;
  late Future<void> _fetchFamilyDataFuture;
  Color familyThemeColor = const Color.fromARGB(255, 121, 121, 121);

  @override
  void initState() {
    super.initState();
    _fetchFamilyDataFuture = fetchFamilyData();
    _fetchFamilyThemeColor();
  }

  Future<void> fetchFamilyData() async {
    try {
      final familyID = widget.familyID;
      final nameMap = await lookupFunction('name');
      final descriptionMap = await lookupFunction('description');
      final logoMap = await lookupFunction('logo');
      final mediaMap = await lookupFunction('media');

      setState(() {
        familyName = nameMap[familyID] ?? '';
        familyDescription = descriptionMap[familyID] ?? '';
        familyLogo = logoMap[familyID] ?? '';
        mediaUrls = List<String>.from(mediaMap[familyID] ?? []);
      });

      print('Family data fetched successfully');
      print('Family Name: $familyName');
      print('Family Description: $familyDescription');
      print('Family Logo URL: $familyLogo');
      print('Media URLs: $mediaUrls');
    } catch (e) {
      print('Error in fetchFamilyData: $e');
    }
  }

  Future<void> _fetchFamilyThemeColor() async {
    try {
      final color = await getFamilyThemeColor();
      setState(() {
        familyThemeColor = color;
      });
      print('Family Theme Color: $familyThemeColor');
    } catch (e) {
      print('Error fetching family theme color: $e');
    }
  }

  Future<String?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return result.files.single.path;
    }
    return null;
  }

  Future<bool> _isCurrentUserFamily() async {
    final currentUserFamilyID = await getUserFamilyId();
    return currentUserFamilyID == widget.familyID;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<void>(
          future: _fetchFamilyDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('Fetching family data...');
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              print('Error fetching family data: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            print('Family data fetched, building UI...');
            return Padding(
              padding: const EdgeInsets.only(top: 120.0), // Adjust the top padding as needed
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                    CircleAvatar(
                    radius: 90,
                    backgroundImage: familyLogo.isNotEmpty
                      ? NetworkImage(familyLogo)
                      : null, // Handles the case where no logo is provided
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading family logo: $exception');
                    },
                    child: familyLogo.isEmpty
                      ? Icon(Icons.error, color: const Color.fromARGB(255, 0, 255, 64)) // Display an error icon if no logo is provided
                      : ClipOval(
                        child: Image.network(
                          familyLogo,
                          fit: BoxFit.cover,
                          width: 180,
                          height: 180,
                          errorBuilder: (context, error, stackTrace) {
                          print('Error loading family logo: $error');
                          return Icon(Icons.error, color: Colors.red);
                          },
                        ),
                        ),
                    ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: dark,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.white, width: 8.0),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          familyName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text color for visibility
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          familyDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white, // Text color for visibility
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: mediaUrls.length,
                    itemBuilder: (context, index) {
                      final mediaUrl = mediaUrls[index];
                      final fileName = mediaUrl.split('/').last;
                      final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv', '.webm', '.mpeg', '.mpg'];
                      final isVideo = videoExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));

                      if (isVideo) {
                        return FutureBuilder<File>(
                          future: _downloadFile(mediaUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Icon(Icons.error, color: Colors.red);
                            } else if (snapshot.hasData) {
                              final videoPlayer = VideoPlayerController.file(snapshot.data!);
                              return FutureBuilder<void>(
                                future: videoPlayer.initialize(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    videoPlayer.setVolume(0); // Mute the video
                                    videoPlayer.play();
                                    videoPlayer.setLooping(true);
                                    return FittedBox(
                                      fit: BoxFit.contain,
                                      child: SizedBox(
                                        width: videoPlayer.value.size.width,
                                        height: videoPlayer.value.size.height,
                                        child: VideoPlayer(videoPlayer),
                                      ),
                                    );
                                  } else {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                },
                              );
                            } else {
                              return Icon(Icons.error, color: Colors.red);
                            }
                          },
                        );
                      } else {
                        return Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading media URL: $error');
                            return Icon(Icons.error, color: Colors.red);
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _isCurrentUserFamily(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(); // Return an empty container while waiting
          } else if (snapshot.hasError) {
            return Container(); // Handle error case
          } else if (snapshot.data == true) {
            return FloatingActionButton(
              onPressed: () async {
                final filePath = await _pickFile();
                if (filePath != null) {
                  try {
                    await FileUploader(
                      filePath: filePath,
                      classType: 'families',
                      familyId: widget.familyID,
                      isPrivate: false,
                      onUploading: (isLoading) {
                        setState(() {
                          isUploading = isLoading;
                        });
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File uploaded successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File upload failed: $e')),
                    );
                  }
                }
              },
              child: Icon(Icons.add),
            );
          } else {
            return Container(); // Return an empty container if the user is not part of the family
          }
        },
      ),
    );
  }

  Future<File> _downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));
    final documentDirectory = await getApplicationDocumentsDirectory();
    final file = File('${documentDirectory.path}/${url.split('/').last}');
    file.writeAsBytesSync(response.bodyBytes);
    return file;
  }
}
