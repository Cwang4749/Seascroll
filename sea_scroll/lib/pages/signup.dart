// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sea_scroll/pages/home.dart';
import '../auth.dart';

import '../components/snackbar-message.dart';

import 'login.dart';
import 'package:sea_scroll/pages/info.dart';

import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _secureText = true;

  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _bioTextController = TextEditingController();
  final TextEditingController _profilePicLinkTextController =
    TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();

  var urlPost = Uri.parse('https://postuser-rxfc6rk7la-uc.a.run.app/');

  Future<void> _postData(
      {required String userid,
      required String name,
      required String bio,
      String? pfp}) async {
    http.Response response;
    if (pfp != null) {
      response = await http.post(urlPost,
          body: {'userid': userid, 'name': name, 'bio': bio, 'pfp': pfp});
    } else {
      response = await http
          .post(urlPost, body: {'userid': userid, 'name': name, 'bio': bio});
    }
    if (response.statusCode == 200) {
      print('User was successfully added');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  void showLoginPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: ((context) => LoginPage())));
  }
  /* Creates a user w/ email and password and adds them to the user table in our Cloud database */
  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
          email: _emailTextController.text,
          password: _passwordTextController.text);
      print("Successfully created user with the following info");
      
      //Updating Firebase Auth info for user
      try {
        Auth().updateName(name: _nameTextController.text);
        print(Auth().currentUser?.displayName);
      } catch (e) {
        print("There's an error in updating name");
      }
      if (_profilePicLinkTextController.text != "") {
        try {
          Auth().updateProfilePic(photoURL: _profilePicLinkTextController.text);
          print(Auth().currentUser?.photoURL);
        } catch (e) {
          print("There's an error in updating profile picture");
        }
      }

      String? userID = Auth().currentUser?.uid;

      //Adding user to the user table in our database
      if (_profilePicLinkTextController.text =="") //if pfp empty, just add name/bio
      {
        _postData(
          userid: userID!,
          name: _nameTextController.text,
          bio: _bioTextController.text,
        );
      } else {
        _postData(
            userid: userID!,
            name: _nameTextController.text,
            bio: _bioTextController.text,
            pfp: _profilePicLinkTextController.text);
      }

      //If authentication was succesful, go to homepage
      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.push(context, MaterialPageRoute(builder: ((context) => Info())));
      });
      // Navigator.push(
      //     context, MaterialPageRoute(builder: ((context) => Home())));
    } on FirebaseAuthException catch (e) {
      //If there are errors, send a message to let the user know
      String errorMessage = "";
      if (e.code == 'weak-password') {
        errorMessage = "The password provided is too weak.";
        //print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "An account already exists for that email.";
        //print('An account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email provided is invalid.";
        //print('Please enter a valid email');
      } else {
        errorMessage = "Something is wrong.";
      }
      ScaffoldMessenger.of(context).showSnackBar(snackBarMessage(errorMessage,
          e.code == 'email-already-in-use' ? "Login" : "Try again", () {
        if (e.code == 'email-already-in-use') {
          showLoginPage();
        }
        //otherwise don't do anything
      }));
    }
  }

  /* Creates a user using google sign in and adds them to the user table in our Cloud database 
    if this is their first time log in
  */
  Future<void> signInWithGoogle() async {
    bool firstTime = false;
    try{
      print('SIGNING IN WITH GOOGLE');
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

      /*If it's the user's first time login in meaning the difference between sign up time 
      and last login is less than a minute, add user to the database w/ their Google info 
      if they left the fields empty to add name, bio, pfp, etc.
      */
      if(Auth().currentUser!=null && (difference!=null&&difference<1))
      {
        firstTime = true;
        String? userID = Auth().currentUser?.uid; 
        try{
          if(Auth().currentUser?.photoURL!=null) //If there's a photo in firebase
          {
            Auth().postUser( //post user w/ photo
              userid: userID!, 
              name: _nameTextController.text==""?'${Auth().currentUser!.displayName}':_nameTextController.text, 
              bio: _bioTextController.text==""?'SeaScroll User':_bioTextController.text,
              pfp: _profilePicLinkTextController.text==""?Auth().currentUser!.photoURL:_profilePicLinkTextController.text,
            );
          }
          else{
            Auth().postUser( //otherwise post w/o
              userid: Auth().currentUser!.uid, 
              name: _nameTextController.text==""?'${Auth().currentUser!.displayName}':_nameTextController.text, 
              bio: _bioTextController.text==""?'SeaScroll User':_bioTextController.text,
            );
          }
        } catch(e)
        {
          print("There's an error with posting new user w/ google sign in $e");
        }
      }
      //If first time signin AND user being added to table is successful, show info page 
      firstTime?
        Future.delayed(const Duration(milliseconds: 1000), () {
          firstTime = false;
          print('firsttime $firstTime');
          Navigator.push(context, MaterialPageRoute(builder: ((context) => Info())));
        })
      //otherwise, if not first time, go straight to homepage
      : Navigator.push(
          context, MaterialPageRoute(builder: ((context) => Home())));
    } on FirebaseAuthException catch(e){
      print("There's an error with google sign in${e.code}");
    }
  }

  /* This method checks if all the required fields are filled before calling FirebaseAuth method for signing up.
    The user will get an error message with the first field that's empty, until they are all filled, in 
    which they can actually submit.
  */
  void isReadyToSubmit(){
    //Required fields, pfp is not required
    bool nameIsEmpty = _nameTextController.text.trim() == "";
    bool bioIsEmpty = _bioTextController.text.trim() == "";
    bool emailIsEmpty = _emailTextController.text.trim() == "";
    bool passwordIsEmpty = _passwordTextController.text.trim() == "";

    String errorMessage = "Please make sure all fields are entered.";
    if(nameIsEmpty)
    {
      errorMessage = "Please enter a name.";
      ScaffoldMessenger.of(context).showSnackBar(snackBarMessage(errorMessage,
          "Try again", () {}));
    }
    else if(bioIsEmpty)
    {
      errorMessage = "Please enter a bio.";
      ScaffoldMessenger.of(context).showSnackBar(snackBarMessage(errorMessage,
          "Try again", () {}));
    }
    else if(emailIsEmpty)
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
      createUserWithEmailAndPassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
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
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Tell us a little bit about yourself.',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),

                //Name
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
                        controller: _nameTextController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Name',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),

                //BIO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _bioTextController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Describe Yourself',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),

                // Image
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
                        controller: _profilePicLinkTextController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Image Link for Pfp (optional)',
                        ),
                      ),
                    ),
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

                //Sign Up Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ElevatedButton(
                    onPressed: () {
                      /*Navigator.push(context,
                        MaterialPageRoute(builder: ((context) => Home())));*/
                      isReadyToSubmit();
                      //createUserWithEmailAndPassword();
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(25),
                        backgroundColor: const Color.fromARGB(255, 37, 156, 166),
                        minimumSize: const Size.fromHeight(75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                const Text('Or Sign Up With',
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
                //const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already a member?'),
                    const SizedBox(
                      width: 10,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => LoginPage())));
                      },
                      child: const Text(
                        'Login Here.',
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
