import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'An account with this email already exists.';
      } else if (e.code == 'invalid-email') {
        throw 'Invalid email format.';
      } else if (e.code == 'weak-password') {
        throw 'Password should be at least 6 characters.';
      } else {
        throw 'Registration failed. Try again.';
      }
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        throw 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        throw 'Invalid email format.';
      } else if (e.code == 'too-many-requests') {
        throw 'Too many failed attempts. Try again later.';
      } else {
        throw 'Sign-in failed. Please try again.';
      }
    }
  }

  Future<Map<String, String?>> getUserDetails() async {
    User? user = _auth.currentUser;

    if (user != null && user.photoURL == null) {
      await user.updateProfile(photoURL: user.providerData[0].photoURL);
      await user.reload();
      user = _auth.currentUser;
    }

    return {};
  }

  Future<void> clearAuthState() async {
    await _auth.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  /// 📧 Forgot Password feature
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success — no error
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "This email is not registered.";
      } else if (e.code == 'invalid-email') {
        return "Invalid email format.";
      } else {
        return "Something went wrong. Please try again.";
      }
    }
  }
}
