import 'package:bookcart/app.dart';
import 'package:bookcart/core/config/supabase_bootstrap.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/data/models/chat_model.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/app_preferences_repository.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/data/repository/book_repository.dart';
import 'package:bookcart/data/repository/chat_repository.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/presentation/screens/home/home_shell_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  Stream<UserModel?> watchCurrentUser() =>
      Stream<UserModel?>.value(currentUser);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
  }) async {
    final user = currentUser!;
    if (location == null &&
        latitude == null &&
        longitude == null &&
        locationUpdatedAt == null) {
      return user;
    }

    currentUser = user.copyWith(
      location: location ?? user.location,
      latitude: latitude,
      longitude: longitude,
      locationUpdatedAt: locationUpdatedAt,
    );
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
    String location = UserModel.defaultLocation,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    String? profileImageBase64,
  }) async {
    currentUser = UserModel(
      id: 'test-user',
      name: name,
      phone: phone,
      email: email,
      location: location,
      latitude: latitude,
      longitude: longitude,
      locationUpdatedAt: locationUpdatedAt,
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
  Stream<List<BookModel>> watchBooks() => Stream<List<BookModel>>.value(_books);

  @override
  Future<List<BookModel>> fetchBooks() async {
    return _books;
  }

  static const _books = [
    BookModel(
      id: 'book-test-1',
      title: 'Test Book',
      author: 'Test Author',
      category: 'School',
      price: '120',
      description: 'A test listing.',
      sellerId: 'test-user',
      sellerName: 'Test User',
    ),
  ];
}

class FakeChatRepository extends ChatRepository {
  @override
  Stream<List<ChatThreadModel>> watchChatsForUser(String userId) =>
      const Stream<List<ChatThreadModel>>.empty();
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
        supabaseBootstrapResult: const SupabaseBootstrapResult.ready(),
        authRepository: FakeAuthRepository(
          currentUser: const UserModel(
            id: 'test-user',
            name: 'Test User',
            phone: '9999999999',
            email: 'test@bookcart.app',
          ),
        ),
        bookRepository: FakeBookRepository(),
        chatRepository: FakeChatRepository(),
        preferencesRepository: FakeAppPreferencesRepository(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final homeShellContext = tester.element(find.byType(HomeShellScreen));
    homeShellContext.read<BookCubit>().changeTab(2);
    await tester.pumpAndSettle();

    expect(find.text('Seller Studio'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My Books'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
