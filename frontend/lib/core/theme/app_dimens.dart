/// Centralised spacing, radius, size and duration tokens.
///
/// Compact premium density. Presentation only.
abstract final class AppSpacing {
  // Spacing scale — compact
  static const double xxs = 3;
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double xxxl = 48;

  // Screen padding
  static const double screenH = 20;
  static const double screenV = 14;

  // Corner radii — generous
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radiusRound = 30;
  static const double radiusFull = 100;

  // Common component sizes
  static const double logoMark = 80;
  static const double logoMarkSm = 44;
  static const double avatar = 48;
  static const double tileRadius = 56;
  static const double buttonHeight = 48;
  static const double productImage = 50;

  // Additional component sizes
  static const double iconBox = 44;
  static const double iconBoxLg = 56;
  static const double avatarRing = 108;
  static const double avatarOuter = 50;
  static const double avatarInner = 44;
  static const double heroHeight = 200;
  static const double balanceCardHeight = 160;
  static const double scanFrameSize = 260;
  static const double navBarHeight = 64;
}

/// Animation duration tokens.
abstract final class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Elevation tokens.
abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 2;
  static const double high = 4;
}
