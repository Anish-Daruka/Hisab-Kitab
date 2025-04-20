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
      title: 'Hisab-Kitab',
      theme: ThemeData(
        fontFamily: 'Helvetica',
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
              borderRadius: BorderRadius.circular(10),
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
    return Container(
      color: AppColor.backgroundcolor,
      child: Scaffold(
        backgroundColor: AppColor.backgroundcolor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Logo
                  SizedBox(height: 225, child: Image.asset('assets/logo.png')),

                  const SizedBox(height: 24),

                  // App Name (Optional, you may want to add it)

                  // Tagline
                  const Text(
                    'Track your expenses, visualize your spending and split your money evenly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          AppColor.moredarkercolor, // Slightly themed gray-blue
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Google Sign-in Button
                  _isLoading
                      ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 8, 79, 246), // Blue spinner
                        ),
                      )
                      : ElevatedButton(
                        onPressed: _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.lightercolor,
                          foregroundColor: Color.fromARGB(255, 41, 101, 242),
                          elevation: 2,
                          shadowColor: Colors.blue.shade100,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            // side: BorderSide(
                            //   color: Color.fromARGB(255, 8, 79, 246),
                            //   width: 1.2,
                            // ),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                  const SizedBox(height: 30),
                ],
              ),
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
        clientId: Secret.GOOGLE_WEB_CLIENT_ID,

        scopes: ['email'],
      );

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (res.user != null) {
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', res.user!.id);

        if (response.isEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => CreateAccount()),
          );
        } else {
          Global.userId = Supabase.instance.client.auth.currentUser?.id;
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (context) => Home()));
        }
      }
    } catch (error) {
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
