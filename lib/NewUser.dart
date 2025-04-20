import 'package:flutter/material.dart';
import 'main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Global.dart'; // Assuming AppColor is defined here

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _usernameController = TextEditingController();
  bool _isUsernameTaken = false;

  void _checkUsername() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a username.',
            style: TextStyle(color: Colors.green),
          ),
          backgroundColor: Colors.white,
        ),
      );
      return;
    }
    final response =
        await supabase
            .from('users')
            .select()
            .eq('user_name', _usernameController.text)
            .maybeSingle();

    setState(() {
      _isUsernameTaken = response != null;
    });

    if (_isUsernameTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Username already exists. Please choose another.',
            style: TextStyle(color: Colors.green),
          ),
          backgroundColor: Colors.white,
        ),
      );
    } else {
      await _createAccount();
    }
  }

  Future<void> _createAccount() async {
    final googleUser = supabase.auth.currentUser;
    await supabase.from('users').insert({
      'id': googleUser!.id,
      'email': googleUser.email,
      'name': googleUser.userMetadata?['name'] ?? 'Unknown',
      'created_at': DateTime.now().toIso8601String(),
      'user_name': _usernameController.text,
    });

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created successfully!',
          style: TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundcolor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColor.darkestcolor,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColor.lightercolor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColor.moredarkercolor),
                  ),
                  child: TextField(
                    controller: _usernameController,
                    // style: const TextStyle(color: AppColor.moredarkercolor),
                    decoration: const InputDecoration(
                      fillColor: AppColor.lightercolor,
                      border: InputBorder.none,
                      labelText: 'Username',
                      labelStyle: TextStyle(color: AppColor.moredarkercolor),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _checkUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.moredarkercolor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: AppColor.darkestcolor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
