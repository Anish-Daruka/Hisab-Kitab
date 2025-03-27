import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'transaction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://etvsmzocqgxctjtpzjlu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0dnNtem9jcWd4Y3RqdHB6amx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE0Mzk5MDEsImV4cCI6MjA1NzAxNTkwMX0.kqVYtMpJxmbfZEk6FQnd9Wv2TUWmU8b4nMHWsmxkPYU',
  );
  print(Supabase.instance.client.auth); // added print statement
  runApp(
    ChangeNotifierProvider(
      create: (context) => TransactionsNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign In Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Home(),
      // home: const SignInPage(),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isLoading = false;
  final _googleSignIn = GoogleSignIn();

  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 100),
              const SizedBox(height: 40),
              const Text(
                'Welcome',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _signInWithGoogle,
                  ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Navigate to your registration page
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final GoogleSignIn _googleSignIn = GoogleSignIn(
        clientId:
            "784636982557-of7hktstodckistnt9irqa643vub4rdn.apps.googleusercontent.com", // Set explicitly
        scopes: ['email'],
      );
      // Disconnect any previous session to allow selection of a different account

      // try {
      //   await _googleSignIn.disconnect();
      // } catch (e) {
      //   print("Error disconnecting: $e");
      // }
      print("Signing in with Google");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print("hello1");

      if (googleUser == null) {
        // User canceled the sign-in flow
        setState(() {
          _isLoading = false;
        });
        return;
      }
      // Get auth details from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print("hello"); //
      // Sign in to Supabase with Google OAuth
      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      if (res.user != null) {
        // Check if user exists in the user table
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', res.user!.id);

        if (response.isEmpty) {
          // User does not exist, insert into user table
          await _supabase.from('users').insert({
            'id': res.user!.id,
            'email': googleUser.email,
            'name': googleUser.displayName,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        // Successfully signed in
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => Home()));
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SignInPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the app!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Text('Signed in as: ${user?.email}'),
          ],
        ),
      ),
    );
  }
}
