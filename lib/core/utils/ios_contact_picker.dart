import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Wraps the native iOS `CNContactPickerViewController` via a method channel.
/// Avoids the "not in window hierarchy" error that affects flutter_contacts
/// 1.1.9 on iOS 15+ (caused by use of the deprecated `keyWindow` API).
///
/// Only used on iOS; returns null on other platforms.
class IosContactPicker {
  static const _channel = MethodChannel('com.serden/contact_picker');

  static Future<PickedContact?> pick() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('pickContact');
      if (raw == null) return null;
      return PickedContact.fromMap(raw);
    } on PlatformException {
      return null;
    }
  }
}

class PickedContact {
  final String displayName;
  final String? email;
  final List<PickedPhone> phones;
  final String street;
  final String subLocality;
  final String city;
  final String state;
  final String postalCode;

  const PickedContact({
    required this.displayName,
    this.email,
    required this.phones,
    required this.street,
    required this.subLocality,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  factory PickedContact.fromMap(Map<String, dynamic> m) {
    final rawPhones = (m['phones'] as List?)?.cast<Map>() ?? [];
    return PickedContact(
      displayName: (m['displayName'] as String?) ?? '',
      email: m['email'] as String?,
      phones: rawPhones
          .map((p) => PickedPhone(label: p['label'] as String, number: p['number'] as String))
          .toList(),
      street: (m['street'] as String?) ?? '',
      subLocality: (m['subLocality'] as String?) ?? '',
      city: (m['city'] as String?) ?? '',
      state: (m['state'] as String?) ?? '',
      postalCode: (m['postalCode'] as String?) ?? '',
    );
  }
}

class PickedPhone {
  final String label;
  final String number;
  const PickedPhone({required this.label, required this.number});

  bool get isMobile =>
      label == '_\$!<Mobile>!\$_' || label.toLowerCase() == 'iphone';
}
