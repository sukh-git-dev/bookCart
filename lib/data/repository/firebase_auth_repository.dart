import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return null;
    }

    return _readUserProfile(currentUser);
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthRepositoryException('Login failed. Please try again.');
      }

      return _readUserProfile(firebaseUser);
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    String location = 'Kolkata, West Bengal',
    String? profileImageBase64,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthRepositoryException(
          'Could not create your account right now.',
        );
      }

      final createdUser = UserModel(
        id: firebaseUser.uid,
        name: _normalizedName(name),
        phone: phone.trim(),
        email: email.trim(),
        location: location.trim().isEmpty ? 'Kolkata, West Bengal' : location,
        profileImageBase64: profileImageBase64,
      );

      await firebaseUser.updateDisplayName(createdUser.name);
      await _usersCollection.doc(firebaseUser.uid).set(createdUser.toJson());

      return createdUser;
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthRepositoryException('Please log in again to continue.');
    }

    try {
      final nextEmail = user.email.trim();
      final nextName = _normalizedName(user.name);
      final currentEmail = currentUser.email?.trim() ?? '';

      if (nextEmail.isNotEmpty && nextEmail != currentEmail) {
        await currentUser.verifyBeforeUpdateEmail(nextEmail);
      }

      if (nextName != (currentUser.displayName ?? '').trim()) {
        await currentUser.updateDisplayName(nextName);
      }

      final updatedUser = user.copyWith(
        id: currentUser.uid,
        name: nextName,
        email: nextEmail,
        phone: user.phone.trim(),
        location: user.location.trim().isEmpty
            ? 'Kolkata, West Bengal'
            : user.location.trim(),
      );

      await _usersCollection
          .doc(currentUser.uid)
          .set(updatedUser.toJson(), SetOptions(merge: true));

      return updatedUser;
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthRepositoryException('Please log in again to continue.');
    }

    final email = currentUser.email?.trim() ?? '';
    if (email.isEmpty) {
      throw const AuthRepositoryException(
        'This account does not support password changes.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);
      await currentUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapPasswordChangeError(error));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    }
  }

  @override
  Future<void> deleteAccount() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthRepositoryException('No signed-in account found.');
    }

    try {
      await _usersCollection.doc(currentUser.uid).delete();
      await currentUser.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(_mapFirestoreError(error));
    }
  }

  Future<UserModel> _readUserProfile(User firebaseUser) async {
    final snapshot = await _usersCollection.doc(firebaseUser.uid).get();
    final data = snapshot.data();
    if (data == null) {
      return UserModel(
        id: firebaseUser.uid,
        name: (firebaseUser.displayName ?? '').trim().isEmpty
            ? 'Book Cart User'
            : firebaseUser.displayName!.trim(),
        phone: firebaseUser.phoneNumber ?? '',
        email: firebaseUser.email?.trim() ?? '',
      );
    }

    return UserModel.fromJson(
      data,
      fallbackId: firebaseUser.uid,
      fallbackEmail: firebaseUser.email?.trim(),
    );
  }

  String _normalizedName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Book Cart User' : trimmed;
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'requires-recent-login':
        return 'Please log in again before changing or deleting this account.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _mapPasswordChangeError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-mismatch':
        return 'Your current password is incorrect.';
      case 'weak-password':
        return 'New password should be at least 6 characters.';
      case 'requires-recent-login':
        return 'Please log in again before changing your password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      default:
        return error.message ?? 'Could not change your password right now.';
    }
  }

  String _mapFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied. Check your Firestore security rules.';
      case 'unavailable':
        return 'Firestore is currently unavailable. Please try again.';
      default:
        return error.message ?? 'Could not save account data right now.';
    }
  }
}
