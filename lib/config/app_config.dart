import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Category {
  final String name;
  final String icon;
  final int? id;

  const Category({required this.name, this.icon = '', this.id});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      id: json['id'] as int?,
    );
  }
}

class AppConfig {
  AppConfig._({
    required this.appName,
    required this.packageName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.bgColor,
    required this.textColor,
    required this.primaryColorDark,
    this.logoAsset = '',
    this.appTagline = '',
    required this.siteUrl,
    required this.apiBaseUrl,
    this.wpBaseUrl = '',
    this.categories = const [],
    this.screens = const {},
    this.features = const {},
    this.enableGoogleLogin = true,
    this.enableFacebookLogin = true,
    this.showProfileTab = true,
    this.showSettingsTab = true,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw StateError('AppConfig not initialized. Call AppConfig.load() first.');
    }
    return _instance!;
  }

  static AppConfig of(BuildContext context) {
    try {
      return Provider.of<AppConfig>(context, listen: false);
    } catch (_) {
      return instance;
    }
  }

  static Future<void> load() async {
    _instance = AppConfig._fromDefaults();
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig._(
      appName: json['appName'] as String? ?? 'PagePilot',
      packageName: json['packageName'] as String? ?? 'com.pagepilot.app',
      primaryColor: _parseColor(json['primaryColor'] as String? ?? '#6C63FF'),
      secondaryColor: _parseColor(json['secondaryColor'] as String? ?? '#FF6584'),
      accentColor: _parseColor(json['accentColor'] as String? ?? '#00C9A7'),
      bgColor: _parseColor(json['bgColor'] as String? ?? '#FFFFFF'),
      textColor: _parseColor(json['textColor'] as String? ?? '#1E1E2D'),
      primaryColorDark: _parseColor(json['primaryColorDark'] as String? ?? '#4A42B0'),
      logoAsset: json['logoAsset'] as String? ?? '',
      appTagline: json['appTagline'] as String? ?? '',
      siteUrl: json['siteUrl'] as String? ?? 'https://pagepilot.com',
      apiBaseUrl: json['apiBaseUrl'] as String? ?? 'https://api.pagepilot.com/v1',
      wpBaseUrl: json['wpBaseUrl'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      screens: json['screens'] != null
          ? Map<String, bool>.from(json['screens'] as Map)
          : {},
      features: json['features'] != null
          ? Map<String, bool>.from(json['features'] as Map)
          : {},
      enableGoogleLogin: json['enableGoogleLogin'] as bool? ?? true,
      enableFacebookLogin: json['enableFacebookLogin'] as bool? ?? true,
      showProfileTab: json['showProfileTab'] as bool? ?? true,
      showSettingsTab: json['showSettingsTab'] as bool? ?? true,
    );
  }

  static AppConfig _fromDefaults() {
    return AppConfig._(
      appName: 'PagePilot',
      packageName: 'com.pagepilot.app',
      primaryColor: _parseColor('#6C63FF'),
      secondaryColor: _parseColor('#FF6584'),
      accentColor: _parseColor('#00C9A7'),
      bgColor: _parseColor('#FFFFFF'),
      textColor: _parseColor('#1E1E2D'),
      primaryColorDark: _parseColor('#4A42B0'),
      logoAsset: '',
      appTagline: 'Learn. Build. Grow.',
      siteUrl: 'https://pagepilot.com',
      apiBaseUrl: 'https://api.pagepilot.com/v1',
      wpBaseUrl: 'https://pagepilot.com',
      categories: const [],
      screens: const {
        'home': true,
        'courses': true,
        'courseDetail': true,
        'lesson': true,
        'quiz': true,
        'profile': true,
        'wishlist': true,
        'settings': true,
      },
      features: const {
        'pushNotifications': true,
        'darkMode': true,
        'offlineMode': false,
        'socialLogin': true,
        'inAppPurchase': false,
      },
      enableGoogleLogin: true,
      enableFacebookLogin: true,
      showProfileTab: true,
      showSettingsTab: true,
    );
  }

  final String appName;
  final String packageName;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color bgColor;
  final Color textColor;
  final Color primaryColorDark;
  final String logoAsset;
  final String appTagline;
  final String siteUrl;
  final String apiBaseUrl;
  final String wpBaseUrl;
  final List<Category> categories;
  final Map<String, bool> screens;
  final Map<String, bool> features;
  final bool enableGoogleLogin;
  final bool enableFacebookLogin;
  final bool showProfileTab;
  final bool showSettingsTab;

  bool isScreenEnabled(String screenName) {
    return screens[screenName] ?? false;
  }

  bool isFeatureEnabled(String featureName) {
    return features[featureName] ?? false;
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
