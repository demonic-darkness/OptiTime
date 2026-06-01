import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget {
  final Color backgroundColor;
  final Color primaryColor;
  final Color mutedColor;

  const AppTopBar({
    super.key,
    required this.backgroundColor,
    required this.primaryColor,
    required this.mutedColor,
  });

  static const String _font = '.SF Pro Text';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final dateStr =
        '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'OptiTime',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: primaryColor,
              letterSpacing: 0,
            ),
          ),
          Text(
            dateStr,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
