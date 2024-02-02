import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late String _userId;
  late Stream<QuerySnapshot> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .doc(_userId)
        .collection('userNotifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications'));
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String type = data['type'];
              String message = data['message'];

              return ListTile(
                title: Text(message),
                subtitle: Text('Type: $type'),
                // You can add more information or actions here
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> followUser(String userIdToFollow) async {
    try {
      // Logic to follow the user
      // For example, add userIdToFollow to the current user's following list

      // Trigger notification for the user being followed
      await _sendFollowNotification(userIdToFollow);
    } catch (e) {
      print('Error following user: $e');
    }
  }

  Future<void> likePost(String postId) async {
    try {
      // Logic to like the post
      // For example, add postId to the user's liked posts list

      // Trigger notification for the post owner
      await _sendLikeNotification(postId);
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  Future<void> _sendFollowNotification(String userIdToNotify) async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Send a notification document to the user's notification subcollection
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userIdToNotify)
          .collection('userNotifications')
          .add({
        'type': 'follow',
        'message': 'You have been followed by $currentUserId',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending follow notification: $e');
    }
  }

  Future<void> _sendLikeNotification(String postId) async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String postOwnerId = await _getPostOwnerId(postId);

      // Send a notification document to the post owner's notification subcollection
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(postOwnerId)
          .collection('userNotifications')
          .add({
        'type': 'like',
        'message': '$currentUserId liked your post',
        'postId': postId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending like notification: $e');
    }
  }

  Future<String> _getPostOwnerId(String postId) async {
    DocumentSnapshot postSnapshot =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    return postSnapshot['userId'];
  }
}
