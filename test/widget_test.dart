import 'package:bookcart/app.dart';
import 'package:bookcart/core/config/firebase_bootstrap.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/app_preferences_repository.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/data/repository/book_repository.dart';
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

class FakeBookRepository extends BookRepository {
  @override
  Future<List<BookModel>> fetchBooks() async {
    return const [
      BookModel(
        id: 'book-test-1',
        title: 'Test Book',
        author: 'Test Author',
        category: 'School',
        price: '120',
        description: 'A test listing.',
      ),
    ];
  }
}

class FakeAppPreferencesRepository extends AppPreferencesRepository {
  bool onboardingCompleted = true;
  String? themePaletteId;

  @override
  Future<bool> readOnboardingCompleted() async => onboardingCompleted;

  @override
  Future<void> writeOnboardingCompleted(bool value) async {
    onboardingCompleted = value;
  }

  @override
  Future<String?> readThemePaletteId() async => themePaletteId;

  @override
  Future<void> writeThemePaletteId(String paletteId) async {
    themePaletteId = paletteId;
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
        bookRepository: FakeBookRepository(),
        preferencesRepository: FakeAppPreferencesRepository(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Seller Studio'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My Books'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
