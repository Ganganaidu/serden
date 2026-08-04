import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Initials circle for clients. The color is hash-picked from the name,
/// matching the design's avatar palette.
class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 42,
    this.backgroundColor,
  });

  /// Same hash as the design mockups so colors stay stable per client.
  static Color colorFor(String name) {
    var h = 0;
    for (final code in name.codeUnits) {
      h = (h * 31 + code) & 0xFFFFFFFF;
    }
    return AppColors.avatarColors[h % AppColors.avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? colorFor(name),
      child: Text(
        Formatters.initials(name),
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: size / 3,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Green circle with an icon (used for add buttons and icon chips).
class PrimaryCircleAvatar extends StatelessWidget {
  final double size;
  final IconData? icon;

  const PrimaryCircleAvatar({super.key, this.size = 40, this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.greenDeep,
      child: Icon(icon ?? Icons.add, color: Colors.white, size: size * 0.5),
    );
  }
}
