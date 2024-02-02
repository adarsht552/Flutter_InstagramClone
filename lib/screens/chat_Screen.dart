import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ChatScreen widget
class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String chatUserId;

  ChatScreen({required this.currentUserId, required this.chatUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _chatUsername = '';
  String _chatUserProfilePicUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchChatUserInfo();
  }

  void _fetchChatUserInfo() async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.chatUserId)
        .get();

    if (userSnapshot.exists) {
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;

      if (userData != null) {
        setState(() {
          _chatUsername = userData['username'] ?? '';
          _chatUserProfilePicUrl = userData['profilePicUrl'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_chatUserProfilePicUrl),
            ),
            SizedBox(width: 10),
            Text(_chatUsername),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                List<DocumentSnapshot> messages = snapshot.data!.docs;

                // Filter messages for this chat
                messages = messages
                    .where((message) =>
                        (message['senderId'] == widget.currentUserId &&
                            message['receiverId'] == widget.chatUserId) ||
                        (message['senderId'] == widget.chatUserId &&
                            message['receiverId'] == widget.currentUserId))
                    .toList();

                if (messages.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> message =
                        messages[index].data() as Map<String, dynamic>;
                    bool isCurrentUser =
                        message['senderId'] == widget.currentUserId;

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          message['content'],
                          style: TextStyle(
                              color:
                                  isCurrentUser ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    String messageContent = _messageController.text.trim();
    if (messageContent.isNotEmpty) {
      // Store message in Firestore
      FirebaseFirestore.instance.collection('chats').add({
        'senderId': widget.currentUserId,
        'receiverId': widget.chatUserId,
        'content': messageContent,
        'timestamp': DateTime.now(),
      });

      // Clear message input field
      _messageController.clear();
    }
  }
}

// UserListPage widget
class UserListPage extends StatefulWidget {
  final String currentUserId;

  UserListPage({required this.currentUserId});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            final List<DocumentSnapshot> users = snapshot.data!.docs;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                final userId = users[index].id;

                if (userId == widget.currentUserId) {
                  return SizedBox.shrink();
                }

                final username = user['username'] ?? 'No Username';
                final profilePicUrl = user['profilePicUrl'] ?? '';
                final hasUnreadMessages = user['hasUnreadMessages'] ?? false;

                return Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: profilePicUrl.isNotEmpty
                              ? NetworkImage(profilePicUrl)
                              : null,
                        ),
                        if (hasUnreadMessages)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(username),
                    onTap: () {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({
                        'hasUnreadMessages': false,
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            currentUserId: widget.currentUserId,
                            chatUserId: userId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
