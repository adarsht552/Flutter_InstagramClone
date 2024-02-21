// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:instagram_clone/screens/post_screen.dart';
// import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/globalItems.dart';
import 'package:line_icons/line_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _page = 0;

  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
         physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: homescreenItem,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
            Colors.black, // Set the background color of BottomNavigationBar
        selectedItemColor: Colors.blue, // Customize the selected item color
        unselectedItemColor: Colors.grey, // Customize the unselected item color
        currentIndex: _page,
        onTap: navigationTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(LineIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LineIcons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(LineIcons.podcast), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(LineIcons.stackExchange), label: 'Story'),
          BottomNavigationBarItem(icon: Icon(LineIcons.user), label: 'Profile'),
        ],
      ),

      
    );
  }
}
