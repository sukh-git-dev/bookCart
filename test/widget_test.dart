import 'package:bookcart/app.dart';
import 'package:bookcart/core/config/firebase_bootstrap.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser});

  UserModel? currentUser;

  @override
  Future<void> deleteAccount() async {
    currentUser = null;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return currentUser!;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
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
    currentUser = UserModel(
      id: 'test-user',
      name: name,
      phone: phone,
      email: email,
      location: location,
      profileImageBase64: profileImageBase64,
    );
    return currentUser!;
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    currentUser = user;
    return user;
  }
}

void main() {
  testWidgets('sell book screen renders inside five-tab shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      BookCartApp(
        firebaseBootstrapResult: const FirebaseBootstrapResult.ready(),
        authRepository: FakeAuthRepository(
          currentUser: const UserModel(
            id: 'test-user',
            name: 'Test User',
            phone: '9999999999',
            email: 'test@bookcart.app',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('List a Book for Sale'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My Books'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
