import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_clone/screens/comment_screen.dart';
import 'package:like_button/like_button.dart';
import 'package:line_icons/line_icons.dart';
import 'package:instagram_clone/screens/user_profile_page.dart';

import 'UserProfile_Page.dart'; // Import your user profile page

class PostShow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Instagram ',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(LineIcons.facebookMessenger, color: Colors.white,size: 27,),
            onPressed: () {
              Navigator.pushNamed(context, '/user_list');
              // Handle navigating to messages or notifications
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
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
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.white),
              ),
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

class _PostCardState extends State<PostCard> with AutomaticKeepAliveClientMixin {
  int likeCount = 0; // Initial like count
  bool isLiked = false; // Initial liked state
  bool isPostSaved = false; // Initial saved state
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

      // Check if the post is saved by the current user
      checkIfPostSaved().then((isSaved) {
        setState(() {
          isPostSaved = isSaved;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure that the parent's build method is called.

    return Card(
      color: Colors.black,
      margin: const EdgeInsets.all(8.0),
      elevation: 3.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: GestureDetector(
              onTap: () {
                navigateToUserProfile();
              },
              child: CircleAvatar(
                radius: 25.0,
                backgroundImage: NetworkImage(userData?['profilePicUrl'] ?? ''),
              ),
            ),
            title: GestureDetector(
              onTap: () {
                navigateToUserProfile();
              },
              child: Text(
                userData?['username'] ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            trailing: const Icon(Icons.more_vert, color: Colors.white),
          ),
          Image.network(
            widget.post['imageUrl'] ?? '',
            width: double.infinity,
            height: 300.0,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    LikeButton(
                      size: 30,
                      isLiked: isLiked,
                      likeCount: likeCount,
                      circleColor:
                          const CircleColor(start: Colors.red, end: Colors.green),
                      bubblesColor: const BubblesColor(
                        dotPrimaryColor: Colors.red,
                        dotSecondaryColor: Colors.green,
                      ),
                      likeBuilder: (bool isLiked) {
                        return Icon(
                          Icons.favorite,
                          color: isLiked ? Colors.red : Colors.white,
                        );
                      },
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
                    const SizedBox(width: 8.0),
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
                      child: const Icon(Icons.comment, color: Colors.white),
                    ),
                   const  SizedBox(width: 8.0),
                   GestureDetector(child: const Icon(Icons.send, color: Colors.white)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                        savePost();
                        setState(() {
                          isPostSaved = !isPostSaved;
                        });
                      },
                  child: Icon(
                    Icons.bookmark_border,
                    color: isPostSaved ? Colors.blue : Colors.white,
                  ),
                ),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextSpan(
                    text: ' ${widget.post['caption'] ?? ''}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '',
            ),
          ),
          const SizedBox(height: 8.0),
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

  void navigateToUserProfile() {
    // Navigate to the profile page of the post owner
    final userId = widget.post['userId'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(userId: userId),
      ),
    );
  }

  Future<void> savePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final postId = widget.post.id;

    await FirebaseFirestore.instance
        .collection('saved_posts')
        .doc(currentUser?.uid)
        .set({
      'posts': FieldValue.arrayUnion([postId])
    }, SetOptions(merge: true));
  }

  Future<bool> checkIfPostSaved() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('saved_posts')
        .doc(currentUser?.uid)
        .get();

    if (snapshot.exists) {
      final savedPosts = snapshot.data()?['posts'] as List<dynamic>?;

      // Check if the current post is in the list of saved posts
      return savedPosts?.contains(widget.post.id) ?? false;
    }

    return false;
  }
}
