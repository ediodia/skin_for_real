import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<void> initAuth() async {
    await _auth.setPersistence(Persistence.LOCAL);
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      final UserCredential credential = await _auth.signInWithPopup(googleProvider);
      final User? user = credential.user;
      if (user != null) await getOrCreateUserDocument(user);
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') return null;
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  static Future<void> getOrCreateUserDocument(User user) async {
    await _db.collection('users').doc(user.uid).set(
      {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'streak': 0,
        'lastCheckIn': null,
        'skinProfile': null,
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> saveSkinProfile({
    required String uid,
    required Map<String, dynamic> skinProfile,
  }) async {
    await _db.collection('users').doc(uid).update({'skinProfile': skinProfile});
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        await getOrCreateUserDocument(credential.user!);
      }
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
      if (credential.user != null) {
        await getOrCreateUserDocument(credential.user!);
      }
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static Future<User?> signInWithMicrosoft() async {
    try {
      final OAuthProvider provider = OAuthProvider('microsoft.com');
      provider.addScope('email');
      provider.addScope('profile');
      final UserCredential credential = await _auth.signInWithPopup(provider);
      if (credential.user != null) {
        await getOrCreateUserDocument(credential.user!);
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') return null;
      rethrow;
    }
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
