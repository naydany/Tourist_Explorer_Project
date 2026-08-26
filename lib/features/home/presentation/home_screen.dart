import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Placeholder landing screen. Replace the body as features land.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.travel_explore,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppConstants.spacing * 2),
            Text(
              'Discover places worth the trip',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              'Project scaffolding is ready. Features go under lib/features/.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
