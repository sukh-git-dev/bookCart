import 'package:bookcart/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sell book screen renders inside five-tab shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'auth_user':
          '{"name":"Test User","phone":"9999999999","email":"test@bookcart.app","password":"1234","location":"Kolkata, West Bengal"}',
      'auth_logged_in': true,
    });

    await tester.pumpWidget(const BookCartApp());
    await tester.pumpAndSettle();

    expect(find.text('List a Book for Sale'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My Books'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
