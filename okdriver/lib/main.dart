import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:okdriver/bottom_navigation_bar/bottom_navigation_bar.dart';
import 'package:okdriver/driver_auth_screen/driver_registration_screen.dart';
import 'package:okdriver/home_screen/homescreen.dart';
import 'package:okdriver/onboarding_screen/onboardind.dart';
import 'package:okdriver/splashscreen/splashscreen.dart';
import 'package:okdriver/theme/theme_provider.dart';
import 'package:okdriver/language/language_provider.dart';
import 'package:okdriver/language/app_localizations.dart';
import 'package:okdriver/service/usersession_service.dart';
import 'package:provider/provider.dart';
import 'package:okdriver/bottom_navigation_bar/bottom_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize session service
  await UserSessionService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'OkDriver',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      locale: languageProvider.currentLocale,
      supportedLocales: LanguageProvider.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _getInitialScreen(),
    );
  }

  // Determine initial screen based on login status
  Widget _getInitialScreen() {
    final sessionService = UserSessionService.instance;
    if (sessionService.isLoggedIn) {
      return BottomNavScreen();
    } else {
      return const SplashScreen();
    }
  }
}
