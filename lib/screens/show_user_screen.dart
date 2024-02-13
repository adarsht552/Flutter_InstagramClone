import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart'; // Import your chat screen

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

                // Don't show current user in the list
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
                      // Update the hasUnreadMessages field to false when opening the chat
                      FirebaseFirestore.instance.collection('users').doc(userId).update({
                        'hasUnreadMessages': false,
                      });

                      // Navigate to the ChatScreen with the selected user
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            currentUserId: widget.currentUserId,
                            chatUserId: userId, // Pass the selected user's userId
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
