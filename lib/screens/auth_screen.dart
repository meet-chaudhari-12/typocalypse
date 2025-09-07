import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:typocalypse/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController emailOrUsernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  void submitAuthForm() async {
    final String loginInput = emailOrUsernameController.text.trim();
    final String password = passwordController.text.trim();

    if (loginInput.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      UserCredential userCredential;

      if (isLogin) {
        // --- LOGIN LOGIC ---
        String emailToLogin;
        if (loginInput.contains('@')) {
          emailToLogin = loginInput;
        } else {
          final userQuery = await _firestore.collection('users').where('username', isEqualTo: loginInput).limit(1).get();
          if (userQuery.docs.isNotEmpty) {
            emailToLogin = userQuery.docs.first.data()['email'];
          } else {
            throw FirebaseAuthException(code: 'user-not-found');
          }
        }
        userCredential = await _auth.signInWithEmailAndPassword(email: emailToLogin, password: password);

        // --- MIGRATION LOGIC FOR OLD USERS ---
        final userDocRef = _firestore.collection('users').doc(userCredential.user!.uid);
        final userDoc = await userDocRef.get();
        if (!userDoc.exists) {
          final String defaultUsername = userCredential.user!.email!.split('@')[0];
          await userDocRef.set({
            'username': defaultUsername,
            'email': userCredential.user!.email,
            'profileImageUrl': null,
            'createdAt': FieldValue.serverTimestamp(),
            // Add initial timestamp for cache-busting
            'profileLastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // --- SIGNUP LOGIC ---
        if (!loginInput.contains('@')) {
          throw FirebaseAuthException(code: 'invalid-email');
        }
        userCredential = await _auth.createUserWithEmailAndPassword(email: loginInput, password: password);
        final String defaultUsername = loginInput.split('@')[0];
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': defaultUsername,
          'email': loginInput,
          'profileImageUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          // Add initial timestamp for cache-busting
          'profileLastUpdated': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      }

    } on FirebaseAuthException catch (e) {
      String message = "Authentication failed. Please try again.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password') message = "Incorrect email/username or password.";
      else if (e.code == 'invalid-email') message = "Please enter a valid email address to sign up.";
      else if (e.code == 'email-already-in-use') message = "An account already exists for that email.";
      else if (e.code == 'weak-password') message = "Password must be at least 6 characters long.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An unexpected error occurred."), backgroundColor: Theme.of(context).colorScheme.error));
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void continueAsGuest() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isLogin ? "Welcome Back!" : "Create an Account", style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                TextField(
                  controller: emailOrUsernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: isLogin ? "Email or Username" : "Email"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: submitAuthForm,
                  child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? "Login" : "Sign Up"),
                ),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login"),
                ),
                const Divider(height: 32),
                OutlinedButton(
                  onPressed: continueAsGuest,
                  child: const Text("Continue as Guest"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

