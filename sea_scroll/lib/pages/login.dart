// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sea_scroll/pages/home.dart';
import 'package:sea_scroll/pages/info.dart';
import '../auth.dart';

import '../components/snackbar-message.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _secureText = true;

  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();

  void showSignUpPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: ((context) => RegisterPage())));
  }

  Future<void> signInWithGoogle() async {
    bool firstTime = false;
    try{
      //print('SIGNING IN WITH GOOGLE');
      String trySignIn = await Auth().signInWithGoogle();

      //If not empty, Google sign in was unsuccessful, so show the user the message and don't continue on to add to user table
      if(trySignIn!="") {
        ScaffoldMessenger.of(context).showSnackBar(snackBarMessage(
          trySignIn, "Try again",
          () {}
        ));
        return;
      }
      //Google sign in was successful, so go on to see if we need to add them to the user table.

      print('Creation timeeee: ${Auth().currentUser?.metadata.creationTime}');
      print('Last sign in timeeee: ${Auth().currentUser?.metadata.lastSignInTime}');

      //Comparing diff between signup and last log in to see if this is the first time login in
      DateTime? signUpTime = Auth().currentUser?.metadata.creationTime;
      DateTime? lastSignInTime = Auth().currentUser?.metadata.lastSignInTime;
      final difference = lastSignInTime?.difference(signUpTime!).inMinutes;

      print('DIFFERENCE IS: ${difference}');
      /*If it's the user's first time login in meaning the difference between sign up time and 
      last login is less than a minute, add user to the database.
      */
      if(Auth().currentUser!=null && 
      (difference!=null&&difference<1))
      {
        firstTime = true;
        try{
          if(Auth().currentUser?.photoURL!=null) //If there's a photo in firebase
          {
            Auth().postUser( //post user w/ photo
              userid: Auth().currentUser!.uid, 
              name: '${Auth().currentUser!.displayName}', 
              bio: 'SeaScroll User',
              pfp: Auth().currentUser!.photoURL,
            );
          }
          else{
            Auth().postUser( //otherwise post w/o
              userid: Auth().currentUser!.uid, 
              name: '${Auth().currentUser!.displayName}', 
              bio: 'SeaScroll User',
            );
          }
          
        } catch(e)
        {
          print("There's an error with posting new user w/ google sign in $e");
        }
        
      }

      /*Navigator.push(
          context, MaterialPageRoute(builder: ((context) => Home())));*/
      //print('firsttime $firstTime');
      //If first time signin AND user being added to table is successful, show info page 
      firstTime?
        Future.delayed(const Duration(milliseconds: 1000), () {
          firstTime = false;
          print('firsttime $firstTime');
          Navigator.push(context, MaterialPageRoute(builder: ((context) => Info())));
        })
      //otherwise, go straight to homepage
      : Navigator.push(
          context, MaterialPageRoute(builder: ((context) => Home())));
    } on FirebaseAuthException catch(e){
      print("There's an error with google sign in${e.code}");
    }
  }
  /* Signs in user w/ email and password*/
  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
          email: _emailTextController.text,
          password: _passwordTextController.text);
      print("Successfully signed in, curr user info: ");
      print("Email: ${Auth().currentUser?.email}");
      print("Name${Auth().currentUser?.displayName}");
      print("PFP${Auth().currentUser?.photoURL}");

      //if successful
      Navigator.push(
          context, MaterialPageRoute(builder: ((context) => Home())));
    } on FirebaseAuthException catch (e) {
      print(e.code);
      //If there are errors, send a message to let the user know
      String errorMessage = "";
      if (e.code == 'invalid-email') {
        errorMessage = "The email entered is invalid.";
        print('Email invalid');
      } else if (e.code == 'user-disabled') {
        errorMessage = "Your account has been disabled.";
        print('User disabled');
      } else if (e.code == 'user-not-found') {
        errorMessage = "No account has been found with this email.";
        print('User not found');
      } else if (e.code == 'wrong-password') {
        errorMessage = "You entered the wrong password.";
        print('Wrong Password');
      } else {
        errorMessage = "Something is wrong.";
      }
      ScaffoldMessenger.of(context).showSnackBar(snackBarMessage(
          errorMessage, e.code == 'user-not-found' ? "Sign Up" : "Try again",
          () {
        if (e.code == 'user-not-found') {
          showSignUpPage();
        }
        //otherwise don't do anything
      }));
    }
  }

   /* This method checks if all the required fields are filled before calling FirebaseAuth method for signing in.
    The user will get an error message with the first field that's empty, until they are both filled, in 
    which they can actually submit.
  */
  
  void isReadyToSubmit(){
    //Required fields
    bool emailIsEmpty = _emailTextController.text.trim() == "";
    bool passwordIsEmpty = _passwordTextController.text.trim() == "";

    String errorMessage = "Please make sure all fields are entered.";
    if(emailIsEmpty)
    {
      errorMessage = "Please enter an email.";
      ScaffoldMessenger.of(context).showSnackBar(snackBarMessage(errorMessage,
          "Try again", () {}));
    }
    else if(passwordIsEmpty)
    {
      errorMessage = "Please enter a password.";
      ScaffoldMessenger.of(context).showSnackBar(snackBarMessage(errorMessage,
          "Try again", () {}));
    }
    else {
      signInWithEmailAndPassword();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[350],
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/sand-bg.png'),
              fit: BoxFit.fitHeight,
            ),
          ),
          child: Center(
              child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // ignore: prefer_const_literals_to_create_immutables
              children: [
                Container(
                  height: 150,
                  child: Image.asset('assets/ss-logo.png'),
                ),
                // Icon(
                //   Icons.android,
                //   size: 100,
                // ),
                //Intro

                const Text(
                  'Hello Again!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Welcome back, you\'ve been missed!',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),

                //Email textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _emailTextController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Email',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),

                //Password textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _passwordTextController,
                        obscureText: _secureText,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _secureText = !_secureText;
                                });
                              },
                              icon: Icon(_secureText
                                  ? Icons.remove_red_eye
                                  : Icons.remove_red_eye_outlined),
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                //Sign in Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ElevatedButton(
                    onPressed: () {
                      isReadyToSubmit();
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(25),
                        backgroundColor: Color.fromARGB(255, 37, 156, 166),
                        minimumSize: const Size.fromHeight(75),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 10),
                const Text('Or Sign In With',
                  style: TextStyle(
                    color: Color.fromARGB(255, 37, 156, 166),
                    fontWeight: FontWeight.bold)
                ),

                SizedBox(height: 10),

                //Google Sign In
                ElevatedButton(
                  onPressed: (){
                    signInWithGoogle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white

                  ),
                  child: Image.asset(
                    'assets/google-logo.png',
                    scale: 50
                  ), 
                ),
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    const Text('Not a member?'),
                    const SizedBox(
                      width: 10,
                    ),
                    TextButton(
                      onPressed: () {
                        showSignUpPage();
                      },
                      child: const Text(
                        'Register Here.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 37, 156, 166)
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )),
        ));
  }
}
