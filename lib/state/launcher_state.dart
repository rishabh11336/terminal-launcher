import 'package:flutter/foundation.dart';
import 'package:terminal_launcher/models/app_info.dart';

@immutable
class LauncherState {
  final bool isSearchActive;
  final String searchQuery;
  final List<AppInfo> searchResults; // filtered, max 6 items displayed
  final bool isDrawerOpen;
  final AppInfo? autoLaunchCandidate; // set when exactly 1 result remains

  const LauncherState({
    this.isSearchActive = false,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isDrawerOpen = false,
    this.autoLaunchCandidate,
  });

  // True when search has exactly one result — triggers 300ms auto-launch timer
  bool get hasUniqueMatch =>
      searchResults.length == 1 && searchQuery.isNotEmpty;

  LauncherState copyWith({
    bool? isSearchActive,
    String? searchQuery,
    List<AppInfo>? searchResults,
    bool? isDrawerOpen,
    AppInfo? autoLaunchCandidate,
    bool clearAutoLaunch = false,
  }) =>
      LauncherState(
        isSearchActive: isSearchActive ?? this.isSearchActive,
        searchQuery: searchQuery ?? this.searchQuery,
        searchResults: searchResults ?? this.searchResults,
        isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
        autoLaunchCandidate:
            clearAutoLaunch ? null : (autoLaunchCandidate ?? this.autoLaunchCandidate),
      );
}
