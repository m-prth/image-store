import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home_screen.dart';

final GoogleSignIn googleSignIn = new GoogleSignIn();

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool userSignedIn = false;

  Future<User> _signIn() async {
    final GoogleSignInAccount account = await googleSignIn.signIn();
    final GoogleSignInAuthentication authentication =
        await account.authentication;

    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      idToken: authentication.idToken,
      accessToken: authentication.accessToken,
    );
    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User user = authResult.user;
    print("SignIn Complele");
    userSignedIn = true;
    movePage();
    return user;
  }

  void movePage() => Navigator.push(
      context, MaterialPageRoute(builder: (context) => HomeScreen()));
  void _signOut() {
    googleSignIn.signOut();
    print("Sign Out");
    SystemNavigator.pop();
  }

  myWidget() {
    if (!userSignedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _signIn().then((User user) {}),
              child: Text('Login using Google'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.red),
              onPressed: () => _signOut(),
              child: Text('Logout'),
            ),
          ],
        ),
      );
    } else {
      return Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to ImageStore'),
        centerTitle: true,
      ),
      body: myWidget(),
    );
  }
}
