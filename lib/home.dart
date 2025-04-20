import 'package:flutter/material.dart';
import 'package:hisab_kitab/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'transaction.dart';
import 'analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'group.dart';
import 'global.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Initialize GoogleSignIn
  int _selectedIndex = 0; // state for bottom navigation

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColor.backgroundcolor,
            pinned: false,
            floating: true,
            snap: true,
            title: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hisab Kitab',
                style: TextStyle(
                  color: AppColor.darkestcolor,
                  fontSize: 26, // Increased font size
                  fontWeight: FontWeight.bold, // Made text bold
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: AppColor.darkestcolor,
                  size: 28, // Increased icon size
                ),
                onPressed: () async {
                  try {
                    await _googleSignIn.disconnect();
                  } catch (e) {
                    print("Error disconnecting: $e");
                  }
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  );
                },
              ),
            ],
          ),
          SliverFillRemaining(
            child: IndexedStack(
              index: _selectedIndex,
              children: [Transaction(), Analytics(), GroupPage()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 8,
        backgroundColor: AppColor.backgroundcolor,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
        ],
      ),
    );
  }
}
