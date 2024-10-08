import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager extends CacheManager {
  static final Map<String, CustomCacheManager> _instances = {};

  // Private constructor to accept parameters
  CustomCacheManager._({required Duration stalePeriod, required int maxNrOfCacheObjects})
      : super(
    Config(
      'gb-cache', // Custom cache key
      stalePeriod: stalePeriod ?? const Duration(days: 30),
      maxNrOfCacheObjects: maxNrOfCacheObjects ?? 100,
    ),
  );

  // Factory method to return an instance based on parameters
  factory CustomCacheManager({required Duration stalePeriod, required int maxNrOfCacheObjects}) {
    // Generate a unique key based on the stale period and max cache objects
    String key = '${stalePeriod.inDays}_$maxNrOfCacheObjects';

    // Check if an instance already exists for the key
    if (_instances.containsKey(key)) {
      return _instances[key]!;
    } else {
      // Create a new instance if it doesn't exist
      final instance = CustomCacheManager._(
        stalePeriod: stalePeriod,
        maxNrOfCacheObjects: maxNrOfCacheObjects,
      );
      _instances[key] = instance;
      return instance;
    }
  }
}
