import 'package:flutter/material.dart';
import 'main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            style: TextStyle(color: Colors.red),
          ),
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created successfully!',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _checkUsername,
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }
}
