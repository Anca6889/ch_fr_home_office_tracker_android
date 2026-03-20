import 'dart:io';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/data_store.dart';
import '../services/user_manager.dart';
import '../services/pdf_export.dart';
import 'calendar_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _users = UserManager();
  DataStore? _store;

  int  _tab     = 0;
  int  _year    = DateTime.now().year;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _users.load();
    await _switchUser(_users.current, save: false);
    setState(() => _loading = false);
  }

  Future<void> _switchUser(String name, {bool save = true}) async {
    final store = DataStore(name);
    await store.load();
    if (save) await _users.setCurrent(name);
    setState(() => _store = store);
  }

  void _refresh() => setState(() {});

  void _prevYear() => setState(() => _year--);
  void _nextYear() => setState(() => _year++);

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context).colors;

    if (_loading || _store == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(child: CircularProgressIndicator(color: c.accent)),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context, c),
      body: IndexedStack(
        index: _tab,
        children: [
          CalendarScreen(
            key:       ValueKey('cal_${_users.current}_$_year'),
            store:     _store!,
            year:      _year,
            onChanged: _refresh,
          ),
          SummaryScreen(
            key:   ValueKey('sum_${_users.current}_$_year'),
            store: _store!,
            year:  _year,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: c.bgPanel,
        selectedItemColor: c.accent,
        unselectedItemColor: c.fgDim,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart), label: 'Summary',
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppColors c) {
    final theme = AppTheme.of(context);
    return AppBar(
      backgroundColor: c.bgPanel,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Home Office Tracking',
            style: TextStyle(color: c.accent, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Text(
            _users.current,
            style: TextStyle(color: c.fgDim, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: c.fg),
          onPressed: _prevYear,
        ),
        GestureDetector(
          onTap: () => _pickYear(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '$_year',
              style: TextStyle(
                color: c.fg, fontSize: 15, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: c.fg),
          onPressed: _nextYear,
        ),
        IconButton(
          icon: Icon(
            theme.isDark ? Icons.light_mode : Icons.dark_mode,
            color: c.accent,
          ),
          tooltip: theme.isDark ? 'Light mode' : 'Dark mode',
          onPressed: theme.onToggle,
        ),
        IconButton(
          icon: Icon(Icons.person, color: c.accent),
          tooltip: 'Users',
          onPressed: () => _showUserDialog(context),
        ),
        IconButton(
          icon: Icon(Icons.picture_as_pdf, color: c.accent),
          tooltip: 'Export PDF',
          onPressed: () => exportPdf(context, _store!, _year, _users.current),
        ),
      ],
    );
  }

  Future<void> _pickYear(BuildContext context) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => _YearPickerDialog(current: _year),
    );
    if (picked != null) setState(() => _year = picked);
  }

  Future<void> _showUserDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => _UserDialog(
        users:    _users,
        onSwitch: (name) async {
          await _switchUser(name);
          if (context.mounted) Navigator.pop(context);
        },
        onAdd: (name) async {
          final ok = await _users.addUser(name);
          if (ok) await _switchUser(name);
          return ok;
        },
        onDelete: (name) async {
          final dataPath = await _users.userDataPath(name);
          final ok       = await _users.deleteUser(name);
          if (ok) {
            try {
              final f = File(dataPath);
              if (await f.exists()) await f.delete();
            } catch (_) {}
            await _switchUser(_users.current, save: false);
          }
          return ok;
        },
      ),
    );
    setState(() {});
  }
}

// ── Year picker dialog ────────────────────────────────────────────────────────

class _YearPickerDialog extends StatelessWidget {
  final int current;
  const _YearPickerDialog({required this.current});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context).colors;
    final years = List.generate(16, (i) => 2020 + i);
    return AlertDialog(
      backgroundColor: c.bgPanel,
      title: Text('Select year', style: TextStyle(color: c.fg)),
      content: SizedBox(
        width: 240,
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          childAspectRatio: 1.6,
          children: years.map((y) => TextButton(
            onPressed: () => Navigator.pop(context, y),
            style: TextButton.styleFrom(
              backgroundColor: y == current ? c.accent.withOpacity(0.2) : null,
              foregroundColor: y == current ? c.accent : c.fg,
            ),
            child: Text('$y'),
          )).toList(),
        ),
      ),
    );
  }
}

// ── User management dialog ────────────────────────────────────────────────────

class _UserDialog extends StatefulWidget {
  final UserManager                   users;
  final Future<void> Function(String) onSwitch;
  final Future<bool> Function(String) onAdd;
  final Future<bool> Function(String) onDelete;

  const _UserDialog({
    required this.users,
    required this.onSwitch,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context).colors;
    return AlertDialog(
      backgroundColor: c.bgPanel,
      title: Text('Users', style: TextStyle(color: c.accent)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.users.users.map((name) => ListTile(
              title: Text(name, style: TextStyle(color: c.fg)),
              leading: name == widget.users.current
                  ? Icon(Icons.person, color: c.accent)
                  : Icon(Icons.person_outline, color: c.fgDim),
              trailing: name == widget.users.current
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.login, color: c.ok, size: 20),
                          onPressed: () => widget.onSwitch(name),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: c.danger, size: 20),
                          onPressed: () => _confirmDelete(context, name),
                        ),
                      ],
                    ),
            )),
            Divider(color: c.separator),
            TextButton.icon(
              icon: Icon(Icons.add, color: c.ok),
              label: Text('Add user', style: TextStyle(color: c.ok)),
              onPressed: () => _promptAdd(context),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: c.accent)),
        ),
      ],
    );
  }

  Future<void> _promptAdd(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok   = await showDialog<bool>(
      context: context,
      builder: (_) => _AddUserDialog(ctrl: ctrl),
    );
    if (ok == true && ctrl.text.isNotEmpty) {
      final added = await widget.onAdd(ctrl.text.trim());
      if (!added && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User already exists')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteUserDialog(name: name),
    );
    if (ok == true) {
      await widget.onDelete(name);
      setState(() {});
    }
  }
}

// ── Add user dialog ───────────────────────────────────────────────────────────

class _AddUserDialog extends StatelessWidget {
  final TextEditingController ctrl;
  const _AddUserDialog({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context).colors;
    return AlertDialog(
      backgroundColor: c.bgPanel,
      title: Text('Add user', style: TextStyle(color: c.fg)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: TextStyle(color: c.fg),
        decoration: InputDecoration(
          hintText: 'Name',
          hintStyle: TextStyle(color: c.fgDim),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: c.separator),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: c.accent),
          ),
        ),
        onSubmitted: (_) => Navigator.pop(context, true),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: c.fgDim)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Add', style: TextStyle(color: c.ok)),
        ),
      ],
    );
  }
}

// ── Delete user confirmation dialog ──────────────────────────────────────────

class _DeleteUserDialog extends StatelessWidget {
  final String name;
  const _DeleteUserDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context).colors;
    return AlertDialog(
      backgroundColor: c.bgPanel,
      title: Text('Delete "$name"?', style: TextStyle(color: c.danger)),
      content: Text(
        'This will permanently delete the user and all their data.\n\nThis cannot be undone.',
        style: TextStyle(color: c.fg),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: c.fgDim)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete', style: TextStyle(color: c.danger)),
        ),
      ],
    );
  }
}
