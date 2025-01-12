import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/global.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import '../functions/FileUpload.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import '../global.dart';


class ChallengesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('challenges').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No challenges available'));
        }

        final challenges = snapshot.data!.docs;

        // Sort challenges: active (status == true) first
        challenges.sort((a, b) {
          final aStatus = (a.data() as Map<String, dynamic>)['status'] ?? false;
          final bStatus = (b.data() as Map<String, dynamic>)['status'] ?? false;
          return bStatus.toString().compareTo(aStatus.toString());
        });

        return ListView.builder(
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final data = challenge.data() as Map<String, dynamic>;

            final name = data['name'] ?? 'Unnamed Challenge';
            final description = data['description'] ?? 'No description';
            final status = data['status'] is bool ? data['status'] : false;
            final mediaUrls = List<String>.from(data['media'] ?? []);
            final privacy = data['privacy'] ?? false;
            final family = data['family'] ?? 'Unknown Family';

            return ChallengeItem(
              name: name,
              description: description,
              status: status,
              privacy: privacy,
              mediaUrls: mediaUrls,
              family: family,
              challengeId: challenge.id,
            );
          },
        );
      },
    );
  }
}

class ChallengeItem extends StatefulWidget {
  final String name;
  final String description;
  final bool status;
  final bool privacy;
  final List<String> mediaUrls;
  final String family;
  final String challengeId;

  const ChallengeItem({
    required this.name,
    required this.description,
    required this.status,
    required this.privacy,
    required this.mediaUrls,
    required this.family,
    required this.challengeId,
    Key? key,
  }) : super(key: key);

  @override
  _ChallengeItemState createState() => _ChallengeItemState();
}

class _ChallengeItemState extends State<ChallengeItem> {
  bool isExpanded = false;
  bool privacyState = false;
  bool isUploading = false; // Tracks file upload
  bool isMediaLoading = true; // Tracks media loading
  List<Widget> mediaWidgets = [];

  @override
  void initState() {
    super.initState();
    privacyState = widget.privacy;
    if (!widget.status) {
      _loadMedia();
    }
  }

  Future<void> _loadMedia() async {
    setState(() {
      isMediaLoading = true;
    });

    List<Widget> mediaItems = [];
    final cacheManager = DefaultCacheManager();

    for (String mediaUrl in widget.mediaUrls) {
      try {
        final response = await http.get(Uri.parse(mediaUrl));
        
        // Check if the file is already cached
        FileInfo? cachedFile = await cacheManager.getFileFromCache(mediaUrl);

        if (cachedFile != null) {
          // Media is cached, use the cached file
          String cachedPath = cachedFile.file.path;
          _addMediaWidget(mediaUrl, cachedPath, mediaItems);
        } else {
          if (response.statusCode == 200) {
            // Save the downloaded file to cache
            final file = await cacheManager.putFile(mediaUrl, response.bodyBytes);
            _addMediaWidget(mediaUrl, file.path, mediaItems);
          } else {
            mediaItems.add(Text('Error fetching media: ${response.statusCode}'));
          }
        }
      } catch (e) {
        //mediaItems.add(Text('Error loading media: $e'));
      }
    }

    setState(() {
      mediaWidgets = mediaItems;
      isMediaLoading = false; // Media has finished loading
    });
  }

  void _addMediaWidget(String mediaUrl, String filePath, List<Widget> mediaItems) {
    final fileName = mediaUrl.split('/').last;
    final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv', '.webm', '.mpeg', '.mpg'];
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final isVideo = videoExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
    final isImage = imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));

    print('Processing media: $mediaUrl');
    print('File path: $filePath');
    print('Is video: $isVideo');
    print('Is image: $isImage');

    if (!mediaUrl.contains("privacy:true")) {
      if (isVideo) {
        final videoPlayer = VideoPlayerController.file(
          File(filePath),
          videoPlayerOptions: VideoPlayerOptions(
            allowBackgroundPlayback: true,
          ),
        );

        videoPlayer.initialize().then((_) {
          setState(() {
            mediaItems.add(
              AspectRatio(
                aspectRatio: videoPlayer.value.aspectRatio,
                child: VideoPlayer(videoPlayer),
              ),
            );
            videoPlayer.play();
            videoPlayer.setLooping(true);
          });
        });
      } else if (isImage) {
        mediaItems.add(Image.file(File(filePath)));
      } else {
        mediaItems.add(Text('Unsupported file type: $fileName'));
        print('Unsupported file type: $fileName');
      }
    }
  }

    @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 34, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.status ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                widget.name,
                style: TextStyle(
                  fontFamily: 'MyCustomFont',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.status ? dark : Colors.grey,
                ),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              if (widget.status) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Privacy: '),
                    Switch(
                      value: privacyState,
                      onChanged: (value) {
                        setState(() {
                          privacyState = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles();
                          if (result != null && result.files.single.path != null) {
                            String filePath = result.files.single.path!;
                            setState(() {
                              isUploading = true;
                            });
                            try {
                              await FileUploader(
                                filePath: filePath,
                                classType: 'challenges',
                                challengeId: widget.challengeId,
                                isPrivate: privacyState,
                                onUploading: (isLoading) {
                                  setState(() {
                                    isUploading = isLoading;
                                  });
                                },
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('File uploaded successfully!')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Upload failed: $e')),
                              );
                            }
                          }
                        },
                  child: isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Submit Proof'),
                ),
              ],
              if (!widget.status) ...[
                const SizedBox(height: 10),
                if (isMediaLoading)
                  const CircularProgressIndicator()
                else if (mediaWidgets.isNotEmpty)
                  Column(
                    children: mediaWidgets,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}