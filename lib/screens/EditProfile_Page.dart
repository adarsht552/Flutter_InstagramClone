import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool _isUpdating = false; // Track whether the profile is currently being updated

  @override
  void initState() {
    super.initState();
    // Fetch the current user's data and set it to the controllers
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get();
    setState(() {
      _usernameController.text = userData['username'];
      _bioController.text = userData['bio'];
    });
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isUpdating = true; // Set the flag to true when profile update begins
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    // Update profile picture if new image selected
    if (_image != null) {
      String imageUrl = await _uploadImage(userId!);
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profilePicUrl': imageUrl,
      });
    }

    // Update username and bio
    await FirebaseFirestore.instance.collection('users').doc(userId!).update({
      'username': _usernameController.text,
      'bio': _bioController.text,
    });

    setState(() {
      _isUpdating = false; // Set the flag back to false when profile update completes
    });

    // Navigate back to profile page after updating
    Navigator.pop(context);
  }

  Future<String> _uploadImage(String userId) async {
    Reference storageReference =
        FirebaseStorage.instance.ref().child('profile_pics/$userId.jpg');
    UploadTask uploadTask = storageReference.putFile(_image!);
    await uploadTask.whenComplete(() => null);
    String imageUrl = await storageReference.getDownloadURL();
    return imageUrl;
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            onPressed: _updateProfile,
            icon: Icon(Icons.check),
          )
        ],
      ),
      body: _isUpdating ? _buildProgressIndicator() : _buildEditProfileForm(),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEditProfileForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 64,
                backgroundImage: _image != null ? FileImage(_image!) as ImageProvider<Object> : NetworkImage('current_profile_url') as ImageProvider<Object>,

              ),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bio',
            ),
          ),
        ],
      ),
    );
  }
}
