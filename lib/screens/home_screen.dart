import 'dart:io';
import 'package:flutter/material.dart';
import '../constants.dart';
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
    if (_loading || _store == null) {
      return const Scaffold(
        backgroundColor: clrBg,
        body: Center(child: CircularProgressIndicator(color: clrAccent)),
      );
    }

    return Scaffold(
      backgroundColor: clrBg,
      appBar: _buildAppBar(),
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
        backgroundColor: clrBgPanel,
        selectedItemColor: clrAccent,
        unselectedItemColor: clrFgDim,
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: clrBgPanel,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Home Office Tracking',
            style: TextStyle(color: clrAccent, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Text(
            _users.current,
            style: const TextStyle(color: clrFgDim, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: clrFg),
          onPressed: _prevYear,
        ),
        GestureDetector(
          onTap: () => _pickYear(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '$_year',
              style: const TextStyle(
                color: clrFg, fontSize: 15, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: clrFg),
          onPressed: _nextYear,
        ),
        IconButton(
          icon: const Icon(Icons.person, color: clrAccent),
          tooltip: 'Users',
          onPressed: () => _showUserDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: clrAccent),
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
    final years = List.generate(16, (i) => 2020 + i);
    return AlertDialog(
      backgroundColor: clrBgPanel,
      title: const Text('Select year', style: TextStyle(color: clrFg)),
      content: SizedBox(
        width: 240,
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          childAspectRatio: 1.6,
          children: years.map((y) => TextButton(
            onPressed: () => Navigator.pop(context, y),
            style: TextButton.styleFrom(
              backgroundColor: y == current ? clrAccent.withOpacity(0.2) : null,
              foregroundColor: y == current ? clrAccent : clrFg,
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
    return AlertDialog(
      backgroundColor: clrBgPanel,
      title: const Text('Users', style: TextStyle(color: clrAccent)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.users.users.map((name) => ListTile(
              title: Text(name, style: const TextStyle(color: clrFg)),
              leading: name == widget.users.current
                  ? const Icon(Icons.person, color: clrAccent)
                  : const Icon(Icons.person_outline, color: clrFgDim),
              trailing: name == widget.users.current
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.login, color: clrOk, size: 20),
                          onPressed: () => widget.onSwitch(name),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: clrDanger, size: 20),
                          onPressed: () => _confirmDelete(context, name),
                        ),
                      ],
                    ),
            )),
            const Divider(color: clrSeparator),
            TextButton.icon(
              icon: const Icon(Icons.add, color: clrOk),
              label: const Text('Add user', style: TextStyle(color: clrOk)),
              onPressed: () => _promptAdd(context),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: clrAccent)),
        ),
      ],
    );
  }

  Future<void> _promptAdd(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok   = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: clrBgPanel,
        title: const Text('Add user', style: TextStyle(color: clrFg)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: clrFg),
          decoration: const InputDecoration(
            hintText: 'Name',
            hintStyle: TextStyle(color: clrFgDim),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: clrSeparator),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: clrAccent),
            ),
          ),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: clrFgDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add', style: TextStyle(color: clrOk)),
          ),
        ],
      ),
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
      builder: (_) => AlertDialog(
        backgroundColor: clrBgPanel,
        title: Text('Delete "$name"?', style: const TextStyle(color: clrDanger)),
        content: const Text(
          'This will permanently delete the user and all their data.\n\nThis cannot be undone.',
          style: TextStyle(color: clrFg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: clrFgDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: clrDanger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.onDelete(name);
      setState(() {});
    }
  }
}
