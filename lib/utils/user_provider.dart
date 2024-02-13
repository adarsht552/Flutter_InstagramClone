import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _profileImageUrl;
  String? _bio;

  User? get user => _user;
  String? get profileImageUrl => _profileImageUrl;
  String? get bio => _bio;

  // Initialize the provider and fetch initial user data
  Future<void> initialize() async {
    await _fetchUserData();
  }

  // Fetch user data from Firestore and Storage
  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;

    if (_user != null) {
      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();

      // Set user data
      _profileImageUrl = userDoc.get('profilePicUrl');
      _bio = userDoc.get('bio');

      notifyListeners();
    }
  }

  // Update user data
  Future<void> updateUserData(String? bio, String? profileImageUrl) async {
    try {
      if (_user != null) {
        // Update user document in Firestore
        await _firestore.collection('users').doc(_user!.uid).update({
          'bio': bio,
          'profilePicUrl': profileImageUrl,
        });

        // Update local data
        _bio = bio;
        _profileImageUrl = profileImageUrl;

        notifyListeners();
      }
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  // Upload profile image to Storage
  Future<String?> uploadProfileImage(String filePath) async {
    try {
      Reference storageReference =
          _storage.ref().child('profile_images/${_user?.uid}.jpg');
      UploadTask uploadTask = storageReference.putFile(File(filePath));
      await uploadTask.whenComplete(() => null);
      String imageUrl = await storageReference.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }
}
