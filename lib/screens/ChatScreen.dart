// screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final bool isFamilyChat; // True for family chat, false for general chat
  final String familyId;

  ChatScreen({required this.isFamilyChat, this.familyId = ""});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final String chatCollection = widget.isFamilyChat
        ? 'family_chats/${widget.familyId}/messages'
        : 'general_chat';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFamilyChat ? "Chat Familial" : "Chat Général"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(chatCollection)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    return ListTile(
                      title: Text(message['senderName']),
                      subtitle: Text(message['text']),
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
                      hintText: "Écrire un message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    sendMessage(chatCollection);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void sendMessage(String chatCollection) {
    if (_messageController.text.trim().isEmpty) return;

    FirebaseFirestore.instance.collection(chatCollection).add({
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'senderName': FirebaseAuth.instance.currentUser!.displayName ?? "Anonyme",
    });
    _messageController.clear();
  }
}