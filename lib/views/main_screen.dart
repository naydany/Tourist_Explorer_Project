import 'package:flutter/material.dart';

import '../repositories/destination_repository.dart';
import '../stores/favorites_store.dart';
import 'explore/explore_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';
import 'saved/saved_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    required this.destinations,
    required this.favorites,
    required this.themeMode,
    super.key,
  });

  final DestinationRepository destinations;
  final FavoritesStore favorites;
  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final Set<int> _visited = <int>{0};

  Widget _tab(int index) {
    if (!_visited.contains(index)) return const SizedBox.shrink();

    return switch (index) {
      0 => ExploreScreen(
        repository: widget.destinations,
        favorites: widget.favorites,
      ),
      1 => MapScreen(
        repository: widget.destinations,
        favorites: widget.favorites,
      ),
      2 => SavedScreen(
        favorites: widget.favorites,
        repository: widget.destinations,
        onBrowse: () => _select(0),
      ),
      _ => ProfileScreen(
        favorites: widget.favorites,
        repository: widget.destinations,
        themeMode: widget.themeMode,
      ),
    };
  }

  void _select(int index) {
    setState(() {
      _currentIndex = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[for (var i = 0; i < 4; i++) _tab(i)],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _select,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
