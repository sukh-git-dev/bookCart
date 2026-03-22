import 'package:bookcart/core/theme/app_theme.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/data/repository/book_repository.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/presentation/screens/auth/login_screen.dart';
import 'package:bookcart/presentation/screens/auth/signup_screen.dart';
import 'package:bookcart/presentation/screens/home/home_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookCartApp extends StatelessWidget {
  const BookCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => BookRepository()),
      ],
      child: BlocProvider(
        create: (context) => BookCubit(context.read<BookRepository>()),
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) {
            return Builder(
              builder: (context) {
                return FutureBuilder<bool>(
                  future: context.read<AuthRepository>().getCurrentUser().then(
                    (user) => user != null,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const MaterialApp(
                        debugShowCheckedModeBanner: false,
                        home: Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      title: 'Book Cart',
                      theme: AppTheme.light(),
                      routes: {
                        LoginScreen.routeName: (_) => const LoginScreen(),
                        SignUpScreen.routeName: (_) => const SignUpScreen(),
                        HomeShellScreen.routeName: (_) => const HomeShellScreen(),
                      },
                      home: snapshot.data!
                          ? const HomeShellScreen()
                          : const LoginScreen(),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
