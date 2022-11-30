import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class Auth{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => _firebaseAuth.currentUser;
  
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async{
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email, password: password);
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async{
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email, password: password);
  }

  Future<String> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    //If signin was canceled
    if(googleUser==null) {
      return "The Google sign in process was aborted.";
    }
    
    //print('THE GOOGLEUSERS ID IS ${googleUser?.id}');
    
    try{
      // Otherwise, obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      // And create a new credential w/ the auth details
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      try{
        //And sign in w/ the credential created
        await FirebaseAuth.instance.signInWithCredential(credential);
      } on FirebaseAuthException catch (e){ //Or return the error to display to the user.
        String error;
        if(e.code=='account-exists-with-different-credential') {
          error="An account already exists with this email address.";
        } else if(e.code=='invalid-credential') {
          error="The credential has expired.";
        } else if(e.code=='user-disabled') {
          error="Your account has been disabled.";
        } else if(e.code=='user-not-found') {
          error="There's no account with these Google credentials.";
        } else{
          error="There's a problem with your Google sign in.";
        }
        return error;
      }
    } on PlatformException catch(e){
      return "There's a problem with retrieving the googleAuth. ${e.code}";
    }
    
    //final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Once signed in, return the UserCredential

    //return await _firebaseAuth.signInWithCredential(credential);

     //await FirebaseAuth.instance.signInWithCredential(credential);
    
     /*print('THE FIREBASEID IS ${_firebaseAuth.currentUser?.uid}');
     print('THE FIREBASEID PHOTO ${_firebaseAuth.currentUser?.photoURL}');
     print('THE FIREBASEID IS ${_firebaseAuth.currentUser?.displayName}');*/
    return "";
  }

  Future<void> signOut() async{
    await _firebaseAuth.signOut();
  }

  Future<void> updateName({
    required String name
  }) async{
    await currentUser?.updateDisplayName(name);
  }

  Future<void> updateProfilePic({
    required String photoURL
  }) async{
    await currentUser?.updatePhotoURL(photoURL);
  }

  var urlPost = Uri.parse('https://postuser-rxfc6rk7la-uc.a.run.app/');

  Future<void> postUser(
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
}