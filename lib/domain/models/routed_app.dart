import 'package:flutter/foundation.dart';

@immutable
class RoutedApp {
  const RoutedApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.category,
    this.alwaysDirect = false,
  });

  final String id;
  final String name;
  final String packageName;
  final String category;
  final bool alwaysDirect;
}
