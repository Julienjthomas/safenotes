// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:local_session_timeout/local_session_timeout.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/models/app_theme.dart';
import 'package:safenotes/routes/route_generator.dart';
import 'authwall.dart';

class App extends StatelessWidget {
  final StreamController<SessionState> sessionStateStream;
  final GlobalKey<NavigatorState> navigatorKey;

  App({Key? key, required this.sessionStateStream, required this.navigatorKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      builder: (context, _) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          initialRoute: '/',
          onGenerateRoute: RouteGenerator.generateRoute,
          title: SafeNotesConfig.getAppName(),
          themeMode: themeProvider.themeMode,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          home: AuthWall(sessionStateStream: sessionStateStream),
        );
      },
    );
  }
}
