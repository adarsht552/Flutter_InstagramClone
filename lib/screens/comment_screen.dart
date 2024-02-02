import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsPage extends StatefulWidget {
  final String postId;

  const CommentsPage({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final comments = snapshot.data?.docs ?? [];

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentTile(
                      comment: comment,
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
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    addComment();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addComment() async {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;
    final user = FirebaseAuth.instance.currentUser;

    if (currentUserID != null && user != null) {
      // Get the current user's username and profilePicUrl
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .get();
      final username = userData.data()?['username'];
      final profilePicUrl = userData.data()?['profilePicUrl'];

      // Add the comment with the username and profilePicUrl
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'content': commentController.text,
        'userId': currentUserID,
        'username': username, // Store the username with the comment
        'profilePicUrl': profilePicUrl, // Store the profilePicUrl with the comment
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear the comment text field after adding the comment
      commentController.clear();
    }
  }
}

class CommentTile extends StatelessWidget {
  final QueryDocumentSnapshot comment;

  const CommentTile({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = comment.data() as Map<String, dynamic>?;

    // Extract the username, defaulting to 'Unknown' if not present
    final username = data?['username'] ?? 'Unknown';
    final profilePicUrl = data?['profilePicUrl'] ?? ''; // Assuming profilePicUrl exists

    return ListTile(
      title: Text(data?['content'] ?? 'No content'),
      subtitle: Text('Commented by: $username'),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profilePicUrl),
      ),
    );
  }
}
