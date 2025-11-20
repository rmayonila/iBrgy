import 'package:flutter/foundation.dart';

/// A lightweight in-memory store for emergency hotlines.
/// Use `EmergencyStore.instance.notifier` to listen for changes.
class EmergencyStore {
  EmergencyStore._privateConstructor();
  static final EmergencyStore instance = EmergencyStore._privateConstructor();

  /// ValueNotifier holding a list of maps with keys: 'title' and 'number'.
  final ValueNotifier<List<Map<String, String>>> notifier =
      ValueNotifier<List<Map<String, String>>>([
        {
          'title': 'Barangay Emergency Response Team (BERT) / Brgy Hall',
          'number': '',
        },
        {'title': 'Local Police Station', 'number': ''},
        {'title': 'Local Fire Department (BFP)', 'number': ''},
        {'title': 'Local Hospital / Ambulance Service', 'number': ''},
      ]);

  List<Map<String, String>> get value => notifier.value;

  void setAll(List<Map<String, String>> list) {
    notifier.value = list
        .map((e) => Map<String, String>.from(e))
        .toList(growable: false);
  }

  void updateNumber(int index, String number) {
    final current = List<Map<String, String>>.from(
      notifier.value.map((e) => Map<String, String>.from(e)),
    );
    if (index >= 0 && index < current.length) {
      current[index]['number'] = number;
      notifier.value = current;
    }
  }
}
