import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserManager {
  List<String> _users   = [];
  String       _current = '';

  List<String> get users   => List.unmodifiable(_users);
  String       get current => _current;

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/home_office_users.json');
  }

  Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = json.decode(await f.readAsString()) as Map;
        _users   = List<String>.from(data['users'] ?? []);
        _current = data['current'] as String? ?? '';
      }
    } catch (_) {}

    if (_users.isEmpty) {
      _users   = ['Default'];
      _current = 'Default';
      await _save();
    }
    if (!_users.contains(_current)) _current = _users.first;
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(
      json.encode({'users': _users, 'current': _current}),
    );
  }

  Future<void> setCurrent(String name) async {
    if (_users.contains(name)) {
      _current = name;
      await _save();
    }
  }

  Future<bool> addUser(String name) async {
    name = name.trim();
    if (name.isNotEmpty && !_users.contains(name)) {
      _users.add(name);
      await _save();
      return true;
    }
    return false;
  }

  Future<bool> deleteUser(String name) async {
    if (_users.contains(name) && _users.length > 1) {
      _users.remove(name);
      if (_current == name) _current = _users.first;
      await _save();
      return true;
    }
    return false;
  }

  /// Full path to a user's data file (for deletion).
  Future<String> userDataPath(String username) async {
    final safe = username.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final dir  = await getApplicationDocumentsDirectory();
    return '${dir.path}/home_office_$safe.json';
  }
}
