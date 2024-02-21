import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_clone/screens/EditProfile_Page.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({Key? key});

  @override
  State<Profilepage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<Profilepage> {
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPostCount();
  }

  Future<void> _fetchPostCount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userPosts = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: currentUser?.uid)
        .get();

    setState(() {
      _postCount = userPosts.docs.length; // Count only the posts uploaded by the current user
    });
  }

  Widget _buildPostGrid(List<DocumentSnapshot> posts) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        var post = posts[index].data() as Map<String, dynamic>;
        return GestureDetector(
          onTap: () {
            // Handle post tap
          },
          child: Image.network(
            post['imageUrl'], // Assuming 'imageUrl' is the key for the image in your Firestore document
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/saved_posts');
            },
            icon: const Icon(Icons.post_add, color: Colors.white),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 1.0),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: NetworkImage(userData['profilePicUrl']),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (userData['username'] ?? ''),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              userData['bio'] ?? 'No bio available',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                                );
                              },
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(_postCount.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Posts', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(userData['followers'] != null ? userData['followers'].length.toString() : '0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Followers', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(userData['following'] != null ? userData['following'].length.toString() : '0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Following', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Posts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    var posts = snapshot.data!.docs;

                    if (posts.isEmpty) {
                      return Center(child: Text('No posts yet.'));
                    }

                    return _buildPostGrid(posts);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
