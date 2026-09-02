import 'package:flutter/material.dart';

import '../repositories/destination_repository.dart';
import 'constants/app_constants.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class TouristExplorerApp extends StatelessWidget {
  const TouristExplorerApp({required this.destinations, super.key});

  final DestinationRepository destinations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.explore,
      routes: AppRouter.routes(destinations),
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
