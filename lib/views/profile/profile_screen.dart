import 'package:flutter/material.dart' hide Page;

import '../../repositories/destination_repository.dart';
import '../../repositories/favorites_store.dart';
import 'widgets/settings_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.favorites,
    required this.repository,
    required this.themeMode,
    super.key,
  });

  final FavoritesStore favorites;
  final DestinationRepository repository;

  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickTheme() async {
    final chosen = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => _ThemeDialog(current: widget.themeMode.value),
    );
    if (chosen != null) widget.themeMode.value = chosen;
  }

  Future<void> _clearSaved() async {
    final confirmed = await _confirm(
      title: 'Clear saved places?',
      message: 'All ${widget.favorites.count} saved places will be removed.',
      action: 'Clear',
    );
    if (!confirmed) return;

    widget.favorites.clear();
    _tell('Saved places cleared.');
  }

  void _clearCache() {
    widget.repository.clearCache();
    _tell('Cached places cleared. The next load will hit the API.');
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[
            widget.favorites,
            widget.themeMode,
          ]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: <Widget>[
              const _ProfileHeader(),
              const SizedBox(height: 22),
              _Stats(favorites: widget.favorites),
              const SizedBox(height: 28),
              const SettingsSection(label: 'PREFERENCES'),
              SettingsTile(
                icon: Icons.contrast_rounded,
                title: 'Appearance',
                value: _themeLabel(widget.themeMode.value),
                onTap: _pickTheme,
              ),
              SettingsTile(
                icon: Icons.favorite_border_rounded,
                title: 'Clear saved places',
                value: '${widget.favorites.count}',
                onTap: widget.favorites.isEmpty ? null : _clearSaved,
              ),
              SettingsTile(
                icon: Icons.refresh_rounded,
                title: 'Clear cached places',
                onTap: _clearCache,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _themeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            'SR',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Guest traveller',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                'Saved places live on this device',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.favorites});

  final FavoritesStore favorites;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _StatTile(value: favorites.count, label: 'SAVED'),
        const SizedBox(width: 12),
        _StatTile(value: favorites.categories.length, label: 'CATEGORIES'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: <Widget>[
            Text(
              '$value',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ThemeDialog extends StatelessWidget {
  const _ThemeDialog({required this.current});

  final ThemeMode current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SimpleDialog(
      title: const Text('Appearance'),
      children: <Widget>[
        for (final mode in ThemeMode.values)
          ListTile(
            title: Text(_themeLabel(mode)),
            trailing: mode == current
                ? Icon(Icons.check_rounded, color: colors.primary)
                : null,
            onTap: () => Navigator.of(context).pop(mode),
          ),
      ],
    );
  }
}
