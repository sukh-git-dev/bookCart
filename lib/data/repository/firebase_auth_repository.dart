import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/data/repository/location_label_repository.dart';
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

  CollectionReference<Map<String, dynamic>> get _booksCollection =>
      _firestore.collection('books');

  @override
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return null;
    }

    return _readUserProfile(currentUser);
  }

  @override
  Stream<UserModel?> watchCurrentUser() {
    return _firebaseAuth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream<UserModel?>.value(null);
      }

      return _usersCollection.doc(firebaseUser.uid).snapshots().asyncMap((
        snapshot,
      ) async {
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

        final user = UserModel.fromJson(
          data,
          fallbackId: firebaseUser.uid,
          fallbackEmail: firebaseUser.email?.trim(),
        );
        return LocationLabelRepository.enrichUser(user);
      });
    });
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
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

      var user = await _readUserProfile(firebaseUser);
      final shouldUpdateLocation =
          (location != null && location.trim().isNotEmpty) ||
          latitude != null ||
          longitude != null ||
          locationUpdatedAt != null;
      if (!shouldUpdateLocation) {
        return user;
      }

      user = user.copyWith(
        location: location?.trim().isNotEmpty == true
            ? location!.trim()
            : user.location,
        latitude: latitude,
        longitude: longitude,
        locationUpdatedAt: locationUpdatedAt,
      );

      await _usersCollection
          .doc(firebaseUser.uid)
          .set(user.toJson(), SetOptions(merge: true));
      await _syncSellerBooks(user);

      return user;
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
    String location = UserModel.defaultLocation,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
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
        location: location.trim().isEmpty
            ? UserModel.defaultLocation
            : location,
        latitude: latitude,
        longitude: longitude,
        locationUpdatedAt: locationUpdatedAt,
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
            ? UserModel.defaultLocation
            : user.location.trim(),
        latitude: user.latitude,
        longitude: user.longitude,
        locationUpdatedAt: user.locationUpdatedAt,
      );

      await _usersCollection
          .doc(currentUser.uid)
          .set(updatedUser.toJson(), SetOptions(merge: true));
      await _syncSellerBooks(updatedUser);

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

    final user = UserModel.fromJson(
      data,
      fallbackId: firebaseUser.uid,
      fallbackEmail: firebaseUser.email?.trim(),
    );
    return LocationLabelRepository.enrichUser(user);
  }

  Future<void> _syncSellerBooks(UserModel user) async {
    final snapshot = await _booksCollection
        .where('sellerId', isEqualTo: user.id)
        .get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.set(document.reference, {
        'sellerName': user.name,
        'sellerEmail': user.email,
        'sellerPhone': user.phone,
        'sellerLocation': user.location,
        'sellerLatitude': user.latitude,
        'sellerLongitude': user.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
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
