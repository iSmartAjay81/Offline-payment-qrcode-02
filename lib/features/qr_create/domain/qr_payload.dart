import 'package:flutter/material.dart';

enum QrExpiry {
  none,
  fiveMinutes,
  oneHour,
  oneDay,
}

extension QrExpiryExt on QrExpiry {
  Duration? get duration {
    switch (this) {
      case QrExpiry.fiveMinutes:
        return const Duration(minutes: 5);
      case QrExpiry.oneHour:
        return const Duration(hours: 1);
      case QrExpiry.oneDay:
        return const Duration(days: 1);
      case QrExpiry.none:
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case QrExpiry.fiveMinutes:
        return '5 Minutes';
      case QrExpiry.oneHour:
        return '1 Hour';
      case QrExpiry.oneDay:
        return '1 Day';
      case QrExpiry.none:
      default:
        return 'No Expiry';
    }
  }
}

class QrCustomization {
  final Color foregroundColor;
  final Color backgroundColor;
  final bool isRounded;
  final String? centerBadgeText;

  const QrCustomization({
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
    this.isRounded = true,
    this.centerBadgeText,
  });

  QrCustomization copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
    bool? isRounded,
    String? centerBadgeText,
  }) {
    return QrCustomization(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isRounded: isRounded ?? this.isRounded,
      centerBadgeText: centerBadgeText ?? this.centerBadgeText,
    );
  }
}

class SplitParticipant {
  final int index;
  final String name;
  final double amount;
  final String note;

  SplitParticipant({
    required this.index,
    required this.name,
    required this.amount,
    required this.note,
  });
}
