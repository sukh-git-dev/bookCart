import 'package:bookcart/app.dart';
import 'package:bookcart/core/config/firebase_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  final firebaseBootstrapResult = await FirebaseBootstrap.initialize();
  runApp(BookCartApp(firebaseBootstrapResult: firebaseBootstrapResult));
}
