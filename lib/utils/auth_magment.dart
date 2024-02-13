import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/home_page.dart';
import 'package:instagram_clone/screens/login_page.dart';

class Auth extends StatelessWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Check if authentication state is available and not null
          if (snapshot.hasData && snapshot.data != null) {
            // User is authenticated, navigate to HomePage
            return  const HomePage(
             
            );
          } else {
            // User is not authenticated, show LoginPage
            return  Login();
          }
        },
      ),
    );
  }
}
