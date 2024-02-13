import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UserSearchPage extends StatefulWidget {
  const UserSearchPage({Key? key}) : super(key: key);

  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  late TextEditingController _searchController;
  List<String> visitedUserIds = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadVisitedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: TextStyle(color: Colors.white),
          onChanged: (value) => _searchUsers(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _searchUsers();
            },
          )
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Visited Profiles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: visitedUserIds.length,
              itemBuilder: (context, index) {
                final userId = visitedUserIds[index];
               return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text('Loading...'),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return ListTile(
                        title: Text('Error loading user data'),
                      );
                    }
                    var userData = snapshot.data!.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(userData['profilePicUrl']),
                      ),
                   
                      
                      title: Text(userData['username']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(userId: userId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Divider(),
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: _searchController.text.trim())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found.'));
                }
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(doc['profilePicUrl']),
                      ),
                      
                      title: Text(doc['username']),
                      subtitle: Text(doc['bio'] ?? ''),
                      
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(userId: doc.id),
                          ),
                        );
                        _addVisitedUser(doc.id);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _searchUsers() {
    // Refresh the stream to trigger a new search based on the entered username
    setState(() {});
  }

  void _addVisitedUser(String userId) {
    // Add visited user to the top of the list
    setState(() {
      if (!visitedUserIds.contains(userId)) {
        visitedUserIds.insert(0, userId);
        // Limit the list to 10 recent visited profiles
        if (visitedUserIds.length > 10) {
          visitedUserIds.removeLast();
        }
      }
    });
  }

  void _removeVisitedUser(String userId) {
    // Remove visited user from the list
    setState(() {
      visitedUserIds.remove(userId);
    });
  }

  void _loadVisitedUsers() {
    // Load visited user IDs from Firestore
    FirebaseFirestore.instance
        .collection('visited_users')
        .orderBy('timestamp', descending: true)
        .limit(10) // Limit to last 10 visited users
        .get()
        .then((querySnapshot) {
      setState(() {
        visitedUserIds = querySnapshot.docs.map((doc) => doc['user_id']).cast<String>().toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserUid = currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.data() == null || !snapshot.data!.exists) {
              return const Text('User not found.');
            }
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            return Text(userData['username']);
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.data() == null || !snapshot.data!.exists) {
            return Center(child: Text('User not found.'));
          }
          var userProfileData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(userProfileData['profilePicUrl']),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildCountLabel('Followers', userProfileData['followers'] != null ? userProfileData['followers'].length : 0),
                                SizedBox(width: 20),
                                _buildCountLabel('Following', userProfileData['following'] != null ? userProfileData['following'].length : 0),
                                SizedBox(width: 20),
                                _buildCountLabel('Posts', userProfileData['postCount'] ?? 0),
                              ],
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${userProfileData['bio']}',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (currentUser != null) {
                        final currentUserDoc = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
                        final userProfileDoc = FirebaseFirestore.instance.collection('users').doc(userId);

                        final currentUserSnapshot = await currentUserDoc.get();
                        final userProfileSnapshot = await userProfileDoc.get();

                        if (currentUserSnapshot.exists && userProfileSnapshot.exists) {
                          final currentUserData = currentUserSnapshot.data() as Map<String, dynamic>;
                          final userProfileData = userProfileSnapshot.data() as Map<String, dynamic>;

                          List<dynamic> following = List.from(currentUserData['following'] ?? []);
                          List<dynamic> followers = List.from(userProfileData['followers'] ?? []);

                          if (following.contains(userId)) {
                            following.remove(userId);
                            followers.remove(currentUserUid);
                          } else {
                            following.add(userId);
                            followers.add(currentUserUid);
                          }

                          // Update the post count
                          int postCount = await FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: userId).get().then((value) => value.docs.length);

                          await currentUserDoc.update({'following': following});
                          await userProfileDoc.update({'followers': followers, 'postCount': postCount}); // Update post count here
                        } else {
                          print('User document does not exist');
                        }
                      } else {
                        print('Current user is null');
                      }
                    },
                    child: Text(
                      (userProfileData['followers'] != null && (userProfileData['followers'] as List).contains(currentUserUid))
                          ? 'Following'
                          : (currentUserUid != userId) // Check if the current user is viewing their own profile
                              ? 'follow' // Display 'Following' if viewing someone else's profile
                              : 'Edit Profile', // Display 'Edit Profile' if viewing their own profile
                    ),
                  ),
                  SizedBox(height: 16),
                  const Text(
                    'Posts',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('userId', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, postSnapshot) {
                      if (postSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (postSnapshot.hasError) {
                        return Center(child: Text('Error: ${postSnapshot.error}'));
                      }
                      var userPosts = postSnapshot.data!.docs;

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: userPosts.length,
                        itemBuilder: (context, index) {
                          var post = userPosts[index].data() as Map<String, dynamic>;
                          return Image.network(post['imageUrl']);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountLabel(String label, int count) {
    return Row(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16.0,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}