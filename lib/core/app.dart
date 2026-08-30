import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget: owns theming and routing only. Feature logic lives under
/// `lib/features/`.
class TouristExplorerApp extends StatelessWidget {
  const TouristExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      routes: AppRouter.routes,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
