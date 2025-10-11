import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
    AuthService._();
    static final AuthService instance = AuthService._();

    final FirebaseAuth _auth = FirebaseAuth.instance;
    Stream<User?> get authStateChanges => _auth.authStateChanges();

    /// sign up with email and password
    Future<UserCredential> signUpWithEmail({
        required String email,
        required String password,
    }) async {
        return await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
        );
    }

    /// sign in with email and password
    Future<UserCredential> signInWithEmail({
        required String email,
        required String password,
    }) async {
        return await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
        );
    }

    /// sign in with Google
    Future<UserCredential> signInWithGoogle() async {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
            throw Exception('Google sign-in aborted by user');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);    
    }

    /// sign out from all accounts
    Future<void> signOut() async {
        await Future.wait([
            GoogleSignIn().signOut(),
            _auth.signOut(),
        ]);
    }
}