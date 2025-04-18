import 'package:flutter/material.dart';
import 'package:hisab_kitab/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'transaction.dart';
import 'analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'group.dart';

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
      appBar: AppBar(
        title: const Text('ExpenseMap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      // Updated body using IndexedStack to navigate screens in place
      body: IndexedStack(
        index: _selectedIndex,
        children: [Transaction(), Analytics(), GroupPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 8,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Share'),
        ],
      ),
    );
  }
}
