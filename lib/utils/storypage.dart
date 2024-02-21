import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class StoryPage extends StatefulWidget {
  @override
  _StoryPageState createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  late User? _user; // Firebase User
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Stories'),
      ),
      body: _user == null ? _buildLoginScreen() : _buildGroupedStoryScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Add Story',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Navigate to login/signup screen
        },
        child: const Text('Login to view stories'),
      ),
    );
  }

  Widget _buildGroupedStoryScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('stories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoading(); // Show skeleton loading
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stories = snapshot.data?.docs ?? [];

        // Delete stories older than 24 hours
        stories.forEach((story) async {
          final storyData = story.data() as Map<String, dynamic>;
          final storyTimestamp = storyData['timestamp'] as Timestamp;
          final storyAge = DateTime.now().difference(storyTimestamp.toDate()).inHours;
          if (storyAge > 24) {
            await story.reference.delete();
          }
        });

        // Group stories by user ID
        Map<String, List<QueryDocumentSnapshot>> groupedStories = {};
        stories.forEach((story) {
          final data = story.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('user_id')) {
            final userId = data['user_id'] as String?;
            if (userId != null) {
              groupedStories.putIfAbsent(userId, () => []);
              groupedStories[userId]!.add(story);
            }
          }
        });

        return ListView(
          children: groupedStories.keys.map((userId) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserStoriesPage(
                      userId: userId, // Pass the userId here
                      userStories: groupedStories[userId]!,
                    ),
                  ),
                );
              },
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildUserLoading(); // Show user skeleton loading
                  }
                  if (userSnapshot.hasError) {
                    return ListTile(
                      title: Text('Error: ${userSnapshot.error}'),
                    );
                  }
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const ListTile(
                      title: Text('User not found'),
                    );
                  }
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(userData['profilePicUrl'] ?? ''),
                          ),
                          title: Text(userData['username'] ?? 'Username'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 5, // Adjust the number of skeleton loading items as needed
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
          ),
          title: Container(
            width: 100,
            height: 12,
            color: Colors.grey[300],
          ),
        );
      },
    );
  }

  Widget _buildUserLoading() {
    return ListTile(
      leading: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey[300],
      ),
      title: Container(
        width: 150,
        height: 12,
        color: Colors.grey[300],
      ),
    );
  }

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        addStory();
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> addStory() async {
    if (_image == null) {
      return; // Don't upload empty stories
    }

    Reference ref =
        FirebaseStorage.instance.ref().child('story_images').child(DateTime.now().toString());
    UploadTask uploadTask = ref.putFile(_image!);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    // Add story data to Firestore with timestamp
    await FirebaseFirestore.instance.collection('stories').add({
      'image_url': imageUrl,
      'timestamp': FieldValue.serverTimestamp(), // Add timestamp field
      'user_id': _user?.uid, // Associate the story with the user
    });

    // Clear fields after adding the story
    setState(() {
      _image = null;
    });
  }
}

class UserStoriesPage extends StatelessWidget {
  final String userId;
  final List<QueryDocumentSnapshot> userStories;

  const UserStoriesPage({
    Key? key,
    required this.userId,
    required this.userStories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('User not found');
            }
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            var userName = userData['username'] as String;
            return Text(userName);
          },
        ),
      ),
      body: Stack(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: MediaQuery.of(context).size.height,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: true,
              enableInfiniteScroll: false,
            ),
            items: userStories.map((story) {
              final data = story.data() as Map<String, dynamic>;
              final String? imageUrl = data['image_url'] as String?;
              return Container(
                padding: const EdgeInsets.all(8.0),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              );
            }).toList(),
          ),
          Positioned(
            top: 20.0,
            left: 20.0,
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('User not found');
                }
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                var profilePicUrl = userData['profilePicUrl'] as String?;
                return CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profilePicUrl ?? ''),
                );
              },
            ),
          ),
          Positioned(
            top: 20.0,
            left: 60.0,
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('User not found');
                }
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                var userName = userData['username'] as String;
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  userStories.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
