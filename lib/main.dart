import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'transaction.dart';
import 'NewUser.dart';
import 'global.dart';
import 'secret.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseUrl = Secret.SUPABASE_URL;
  final supabaseKey = Secret.SUPABASE_ANON_KEY;

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
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
      title: 'Expense Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.blue,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      home: const SignInPage(),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                const Icon(
                  Icons.map_outlined,
                  size: 100,
                  color: Color(0xFF4285F4),
                ),

                const SizedBox(height: 20),

                // App Name
                const Text(
                  'Expense Map',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // App Tagline
                const Text(
                  'Track your expenses, visualize your spending',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 50),

                // Sign in Button
                _isLoading
                    ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4285F4),
                      ),
                    )
                    : ElevatedButton.icon(
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
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

                // Terms and Privacy
                const Text(
                  'By signing in, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
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
        print("successfully authenticated");
        // Check if user exists in the user table
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', res.user!.id);
        print("response: $response");

        if (response.isEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => CreateAccount()),
          );

          print("why reached here...");
        } else {
          Global.userId = Supabase.instance.client.auth.currentUser?.id;
          // Successfully signed in
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (context) => Home()));
        }
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
