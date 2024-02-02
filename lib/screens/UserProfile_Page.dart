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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers();
                  },
                ),
              ),
              onChanged: (value) => _searchUsers(),
            ),
          ),
          Expanded(
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
            onTap: () {
              // Navigate to the user profile page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(userId: doc.id),
                ),
              );
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
              return Text('Loading...');
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.data() == null || !snapshot.data!.exists) {
              return Text('User not found.');
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Followers: ${userProfileData['followers'] != null ? userProfileData['followers'].length : 0}',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                              SizedBox(width: 20),
                              Text(
                                'Following: ${userProfileData['following'] != null ? userProfileData['following'].length : 0}',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                        ],
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

        await currentUserDoc.update({'following': following});
        await userProfileDoc.update({'followers': followers});
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
        ? 'follow'  // Display 'Following' if viewing someone else's profile
        : 'Edit Profile', // Display 'Edit Profile' if viewing their own profile
  ),
),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
