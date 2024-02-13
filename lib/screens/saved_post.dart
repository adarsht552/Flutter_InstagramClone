import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'UserProfile_Page.dart'; // Import your user profile page
class SavedPostsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Saved Posts',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('saved_posts')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'No saved posts yet.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          List<dynamic> savedPostIds = snapshot.data!['posts'];

          if (savedPostIds.isEmpty) {
            return const Center(
              child: Text(
                'No saved posts yet.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: savedPostIds.length,
            itemBuilder: (context, index) {
              final postId = savedPostIds[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .get(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                    // Handle if the post doesn't exist
                    return const SizedBox.shrink();
                  }

                  final post = postSnapshot.data!;
                  return SavedPostCard(post: post);
                },
              );
            },
          );
        },
      ),
    );
  }
}


class SavedPostCard extends StatelessWidget {
  final DocumentSnapshot post;

  const SavedPostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.all(8.0),
      elevation: 3.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display Post Image
          if (post['imageUrl'] != null)
            Image.network(
              post['imageUrl'],
              width: double.infinity,
              height: 200.0, // Adjust the height as needed
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              post['caption'] ?? 'No caption',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
