import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/screens/home_page.dart';
import 'package:instagram_clone/screens/login_page.dart';
import 'dart:io';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _username = TextEditingController();
  File? _image;
  XFile? _pickedFile;
  bool _registering = false;

  Future<void> _registerUser() async {
    if (_email.text.isEmpty ||
        _pass.text.isEmpty ||
        _bio.text.isEmpty ||
        _username.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Missing Information'),
            content: const Text('Please fill in all fields.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _registering = false; // Reset registering state
                  });
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() {
      _registering = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _email.text, password: _pass.text);

      String userId = userCredential.user?.uid ?? '';

      if (_image == null) {
        String defaultImageUrl =
            'https://i.stack.imgur.com/l60Hf.png'; // Set a default image URL
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'bio': _bio.text,
          'profilePicUrl': defaultImageUrl,
          'username': _username.text,
          'following': [],
          'followers': [],
        });
      } else {
        await _uploadImage(userId);
      }

      await _sendWelcomeMessage(userId);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } catch (e) {
      print('Error during registration: $e');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Authentication Failed'),
            content: Text('email already exist.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _registering = false; // Reset registering state
                  });
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _registering = false; // Reset registering state
      });
    }
  }

  Future<void> _uploadImage(String userId) async {
    if (_image != null) {
      Reference storageReference =
          FirebaseStorage.instance.ref().child('profile_pics/$userId.jpg');
      UploadTask uploadTask = storageReference.putFile(_image!);
      await uploadTask.whenComplete(() => null);
      String imageUrl = await storageReference.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'bio': _bio.text,
        'profilePicUrl': imageUrl,
        'username': _username.text,
        'following': [],
        'followers': [],
      });

      await _sendNotification(userId);
    }
  }

  Future<void> _sendNotification(String userId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .add({
      'type': 'profile_creation',
      'message':
          'Welcome to the app! Your profile has been successfully created.',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendWelcomeMessage(String userId) async {
    String receiverId = "adminUserId";

    await FirebaseFirestore.instance.collection('chats').add({
      'senderId': userId,
      'receiverId': receiverId,
      'content': 'Welcome to the app!',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _pickedFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(flex: 2, child: Container()),
              const SizedBox(height: 64),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundImage: _image != null
                        ? FileImage(_image!) as ImageProvider<Object>
                        : const NetworkImage(
                            'https://i.stack.imgur.com/l60Hf.png'),
                  ),
                  Positioned(
                    bottom: -10,
                    left: 80,
                    child: IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'email',
                ),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'password',
                ),
                controller: _pass,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'bio',
                ),
                controller: _bio,
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'username',
                ),
                controller: _username,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 24),
              Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _registering
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : TextButton(
                      
                        child: const Text('SignIn',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                        onPressed: () {
                          _registerUser();
                        },
                      ),
              ),
              const SizedBox(height: 64),
              Padding(
                padding: const EdgeInsets.only(left: 110),
                child: Row(
                  children: [
                    const Text('have account'),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      child: const Text(
                        'LogIn',
                        style: TextStyle(color: Colors.blue, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 2,
                child: Container(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
