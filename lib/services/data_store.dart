import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants.dart';

/// Per-user JSON persistence.
/// Schema: {"2025": {"3": {"15": "maison", ...}, ...}, ...}
/// Same file format as the desktop app.
class DataStore {
  final String username;
  Map<String, dynamic> _data = {};

  DataStore(this.username);

  String get _safeUsername =>
      username.replaceAll(RegExp(r'[^\w\-.]'), '_');

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/home_office_$_safeUsername.json');
  }

  Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        _data = json.decode(await f.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {
      _data = {};
    }
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(json.encode(_data));
  }

  String? get(int year, int month, int day) {
    final y = '$year', m = '$month', d = '$day';
    return (_data[y] as Map?)?[m]?[d] as String?;
  }

  Future<void> set(int year, int month, int day, String? category) async {
    final y = '$year', m = '$month', d = '$day';
    if (category == null) {
      ((_data[y] as Map?)?[m] as Map?)?.remove(d);
    } else {
      _data.putIfAbsent(y, () => <String, dynamic>{});
      (_data[y] as Map).putIfAbsent(m, () => <String, dynamic>{});
      (_data[y] as Map)[m][d] = category;
    }
    await _save();
  }

  Map<String, int> yearCounts(int year) {
    final counts = {for (final c in categories) c.code: 0};
    final yearData = _data['$year'] as Map? ?? {};
    for (final monthData in yearData.values) {
      for (final cat in (monthData as Map).values) {
        if (counts.containsKey(cat)) counts[cat as String] = counts[cat]! + 1;
      }
    }
    return counts;
  }

  Map<String, String> monthDays(int year, int month) {
    final raw = (_data['$year'] as Map?)?['$month'] as Map? ?? {};
    return raw.map((k, v) => MapEntry(k as String, v as String));
  }
}
