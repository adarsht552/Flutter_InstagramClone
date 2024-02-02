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

      // Generate a unique post ID using Firestore's doc() method
      final postRef = _firestore.collection('posts').doc();

      // Upload image to Firebase Storage
      final Reference storageRef = _storage.ref().child('posts/${user?.uid}/${postRef.id}.jpg');
      final UploadTask uploadTask = storageRef.putFile(File(_pickedFile!.path));
      await uploadTask.whenComplete(() {});

      // Get the download URL of the uploaded image
      final String imageUrl = await storageRef.getDownloadURL();

      // Store post data in Firestore using the generated post ID
      await postRef.set({
        'userId': user?.uid,
        'caption': captionController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [], // Initialize likedBy as an empty list
      });
      

      // Clear the selected image and caption after posting
      setState(() {
        _pickedFile = null;
        captionController.clear();
        _isUploading = false;
      });
       Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );


      // Optionally, you can navigate to a different screen after posting
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => YourNextScreen()));
    } catch (e) {
      print('Error uploading post: $e');
      // Handle the error as needed
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _pickedFile == null
        ? Center(
            child: IconButton(
              onPressed: () => _selectImage(context),
              icon: const Icon(Icons.upload),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                  // Handle back button
                },
              ),
              title: const Text('Post to'),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          height: 45,
                          width: 45,
                          child: FutureBuilder<String?>(
                            future: getProfileImageUrl(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                final imageUrl = snapshot.data;
                                return CircleAvatar(
                                  radius: 20,
                                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: TextField(
                        controller: captionController,
                        decoration: const InputDecoration(
                          hintText: 'Write your caption here',
                          border: InputBorder.none,
                        ),
                        maxLines: 8,
                      ),
                    ),
                    SizedBox(
                      height: 45,
                      width: 45,
                      child: AspectRatio(
                        aspectRatio: 487 / 452,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(File(_pickedFile!.path)),
                              fit: BoxFit.fill,
                              alignment: FractionalOffset.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ],
            ),
          );
  }
}
