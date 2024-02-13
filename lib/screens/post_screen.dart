import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_clone/screens/home_page.dart';

class AddscreenpagState extends StatefulWidget {
  const AddscreenpagState({Key? key}) : super(key: key);

  @override
  State<AddscreenpagState> createState() => AddscreenpagStateState();
}

XFile? _pickedFile;
bool _isUploading = false;

class AddscreenpagStateState extends State<AddscreenpagState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController captionController = TextEditingController();

  _selectImage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Create post'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Take a photo'),
              onPressed: () async {
                Navigator.of(context).pop();
                final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                setState(() {
                  _pickedFile = pickedFile as XFile?;
                });
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Take a photo from gallery'),
              onPressed: () async {
                Navigator.of(context).pop();
                final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                setState(() {
                  _pickedFile = pickedFile as XFile?;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> getProfileImageUrl() async {
    final User? user = _auth.currentUser;

    try {
      final ref = _storage.ref().child('profile_images/${user?.uid}.jpg');
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error getting profile image URL: $e');
      return null;
    }
  }

  Future<void> uploadPost() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final User? user = _auth.currentUser;

      final postRef = _firestore.collection('posts').doc();

      final Reference storageRef = _storage.ref().child('posts/${user?.uid}/${postRef.id}.jpg');
      final UploadTask uploadTask = storageRef.putFile(File(_pickedFile!.path));
      await uploadTask.whenComplete(() {});

      final String imageUrl = await storageRef.getDownloadURL();

      await postRef.set({
        'userId': user?.uid,
        'caption': captionController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      setState(() {
        _pickedFile = null;
        captionController.clear();
        _isUploading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      print('Error uploading post: $e');
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: _isUploading
                ? null
                : () async {
                    await uploadPost();
                  },
            child: _isUploading
                ? const CircularProgressIndicator()
                : const Text(
                    'Post',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _pickedFile == null
                ? Center(
                    child: IconButton(
                      onPressed: () => _selectImage(context),
                      icon: const Icon(Icons.add_a_photo),
                    ),
                  )
                : Stack(
                    children: [
                      Image.file(
                        File(_pickedFile!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: captionController,
                            decoration: const InputDecoration(
                              hintText: 'Write your caption here...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
