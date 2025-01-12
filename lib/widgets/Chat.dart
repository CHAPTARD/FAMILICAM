import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../global.dart';

class ChatPage extends StatefulWidget {
  final bool isFamilyChat;

  const ChatPage({Key? key, required this.isFamilyChat}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  String? familyId;
  String familyName = '';
  Color familyThemeColor = Colors.grey;
  bool isGeneralChatExpanded = false;
  bool isFamilyChatExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeFamilyData();
  }

  Future<void> _initializeFamilyData() async {
    familyId = await getUserFamilyId();
    if (familyId != null) {
      final nameMap = await lookupFunction('name');
      final themeMap = await lookupFunction('theme');
      setState(() {
        familyName = nameMap[familyId] ?? 'Family';
        String colorString = themeMap[familyId] ;// ?? '#808080'; // Default to gray if no theme found
        if (!colorString.startsWith('#')) {
          colorString = '#$colorString';
        }
        familyThemeColor = Color(int.parse(colorString.replaceFirst('#', '0xff')));
      });
    }
  }

  void _toggleGeneralChat() {
    setState(() {
      isGeneralChatExpanded = !isGeneralChatExpanded;
      isFamilyChatExpanded = false;
    });
  }

  void _toggleFamilyChat() {
    setState(() {
      isFamilyChatExpanded = !isFamilyChatExpanded;
      isGeneralChatExpanded = false;
    });
  }

  Widget _buildChatSection(String title, String collectionPath, bool isExpanded, Color minimizedColor) {
    return Expanded(
      flex: isExpanded ? 20 : 1,
      child: GestureDetector(
        onTap: () {
          if (title == 'General') {
            _toggleGeneralChat();
          } else {
            _toggleFamilyChat();
          }
        },
        child: Container(
          color: isExpanded ? Colors.transparent : minimizedColor,
          child: isExpanded
              ? Column(
                  children: [
                    Container(
                        padding: EdgeInsets.all(8.0),
                        height: 70, // Add a fixed height
                        alignment: Alignment.center, // Center the text vertically
                        //color: Colors.blue,
                        child: Text(
                        title,
                        style: TextStyle(color: familyThemeColor, fontSize: 40, fontFamily: 'MyCustomFont'),
                        ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(collectionPath)
                            .orderBy('timestamp', descending: true)
                            .limit(20)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          final messages = snapshot.data!.docs;
                          return ListView.builder(
                            padding: EdgeInsets.zero, // Remove default padding
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return ListTile(
                                title: Text(message['text']),
                                subtitle: Text(message['sender']),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () async {
                              if (_messageController.text.isNotEmpty) {
                                await FirebaseFirestore.instance.collection(collectionPath).add({
                                  'text': _messageController.text,
                                  'sender': FirebaseAuth.instance.currentUser!.email,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                                _messageController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Container(), // Display an empty container when minimized
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat',
          style: TextStyle(color: Colors.white, fontSize: 40, fontFamily: 'MyCustomFont'),
        ),
        backgroundColor: familyThemeColor,
        elevation: 0,
      ),
      body: Row(
        children: [
          _buildChatSection('General', 'general_chats', isGeneralChatExpanded, Colors.grey),
          _buildChatSection(familyName, 'family_chats/$familyId/messages', isFamilyChatExpanded, familyThemeColor),
        ],
      ),
    );
  }
}