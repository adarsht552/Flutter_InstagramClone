import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_clone/screens/comment_screen.dart';
import 'package:like_button/like_button.dart';

class PostShow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instagram Clone'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box),
            onPressed: () {
              // Handle adding a new post
            },
          ),
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              Navigator.pushNamed(context, '/user_list');
              // Handle navigating to messages or notifications
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final posts = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              return PostCard(
                post: post,
              );
            },
          );
        },
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final DocumentSnapshot post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with AutomaticKeepAliveClientMixin {
  int likeCount = 0; // Initial like count
  bool isLiked = false; // Initial liked state
  Map<String, dynamic>? userData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchUserData().then((_) {
      final currentUserID = FirebaseAuth.instance.currentUser?.uid;
      final likedByList = widget.post['likedBy'] as List<dynamic>?;

      // Initialize isLiked based on whether the current user has liked the post
      setState(() {
        isLiked = likedByList?.contains(currentUserID) ?? false;
      });

      likeCount = widget.post['likes'] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure that the parent's build method is called.

    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 3.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(8.0),
            leading: CircleAvatar(
              radius: 25.0,
              backgroundImage: NetworkImage(userData?['profilePicUrl'] ?? ''),
            ),
            title: Text(userData?['username'] ?? ''),
            trailing: Icon(Icons.more_vert),
          ),
          Image.network(
            widget.post['imageUrl'] ?? '',
            width: double.infinity,
            height: 300.0,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    LikeButton(
                      size: 30,
                      isLiked: isLiked,
                      likeCount: likeCount,
                      onTap: (isLiked) async {
                        // Handle like button tap
                        if (isLiked) {
                          // User unliked the post
                          await unlikePost();
                        } else {
                          // User liked the post
                          await likePost();
                        }
                        // No need to toggle isLiked here, the state will be updated in likePost and unlikePost
                        return !isLiked;
                      },
                    ),
                    SizedBox(width: 8.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CommentsPage(postId: widget.post.id),
                          ),
                        );
                      },
                      child: Icon(Icons.comment),
                    ),
                    SizedBox(width: 8.0),
                    Icon(Icons.send),
                  ],
                ),
                Icon(Icons.bookmark_border),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: userData?['username'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' ${widget.post['caption'] ?? ''}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '',
            ),
          ),
          SizedBox(height: 8.0),
        ],
      ),
    );
  }

  Future<void> fetchUserData() async {
    if (userData == null) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post['userId'])
          .get();

      if (userSnapshot.exists) {
        userData = userSnapshot.data() as Map<String, dynamic>;
      }
    }
  }

  Future<void> likePost() async {
    // Update the like count locally
    setState(() {
      likeCount++;
      isLiked = true;
    });

    // Update the like count and likedBy in Firestore
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    await postRef.update({
      'likes': FieldValue.increment(1),
      'likedBy':
          FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid]),
    });
  }

  Future<void> unlikePost() async {
    // Update the like count locally
    setState(() {
      likeCount--;
      isLiked = false;
    });

    // Update the like count and likedBy in Firestore
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    await postRef.update({
      'likes': FieldValue.increment(-1),
      'likedBy':
          FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid]),
    });
  }
}
