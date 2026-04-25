import 'package:bookcart/app.dart';
import 'package:bookcart/core/config/supabase_bootstrap.dart';
import 'package:bookcart/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  final timer = AppLogger.startTimer('Main', 'app startup');
  WidgetsFlutterBinding.ensureInitialized();
  Animate.restartOnHotReload = true;
  Animate.defaultCurve = Curves.easeOutCubic;
  await MobileAds.instance.initialize();
  final supabaseBootstrapResult = await SupabaseBootstrap.initialize();
  if (supabaseBootstrapResult.isReady) {
    timer.success('BookCart launched');
  } else {
    timer.warning(
      'App launched with setup screen',
      details: {'reason': supabaseBootstrapResult.errorMessage},
    );
  }
  runApp(BookCartApp(supabaseBootstrapResult: supabaseBootstrapResult));
}
