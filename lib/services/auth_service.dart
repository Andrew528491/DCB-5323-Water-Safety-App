import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? get currentUser => _auth.currentUser;

 // Sign up with email and password
Future<UserCredential> signUpWithEmail({
  required String email,
  required String password,
}) async {
  try {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await _createUserDoc(user);
    }
    return credential;
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'email-already-in-use':
        throw Exception('This email is already registered to another user.');
      case 'invalid-email':
        throw Exception('Please enter a valid email address.');
      case 'weak-password':
        throw Exception('Your password is too weak. Try something stronger.');
      default:
        throw Exception('Sign up failed. Please try again.');
    }
  } catch (e) {
    throw Exception('Something went wrong. Please try again later.');
  }
}

// Sign in
Future<UserCredential> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'user-not-found':
        throw Exception('No account found for this email.');
      case 'wrong-password':
        throw Exception('Incorrect password. Please try again.');
      case 'invalid-email':
        throw Exception('Please enter a valid email address.');
      default:
        throw Exception('Login failed. Please try again.');
    }
  } catch (e) {
    throw Exception('Something went wrong. Please try again later.');
  }
}

  // Google sign-in
  Future<UserCredential> signInWithGoogle() async {
    // Trigger Google Sign-In flow
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in aborted');
    }

    // Obtain auth details from the request
    final googleAuth = await googleUser.authentication;

    // Create a new credential for Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final userCredential = await _auth.signInWithCredential(credential);

    // Ensure Firestore document exists
    final user = userCredential.user;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _createUserDoc(user);
      }
    }

    return userCredential;
  }

  Future<void> signOut() async {
    try {
      // Sign out of Firebase and Google (if applicable)
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Create Firestore doc for new user
  Future<void> _createUserDoc(User user) async {
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'username': user.displayName ?? '', // empty string if none set
      'dailyStreak': 0,
      'lessonTracker': {}, // empty map
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}