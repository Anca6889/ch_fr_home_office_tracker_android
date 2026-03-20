import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/compliance_result.dart';
import '../services/compliance_engine.dart';
import '../services/data_store.dart';
import '../widgets/calendar_grid.dart';

class CalendarScreen extends StatefulWidget {
  final DataStore    store;
  final int          year;
  final VoidCallback onChanged;

  const CalendarScreen({
    super.key,
    required this.store,
    required this.year,
    required this.onChanged,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _month;
  late int _year;
  int    _slideDir   = 1;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _month = today.month;
    _year  = widget.year;
  }

  @override
  void didUpdateWidget(CalendarScreen old) {
    super.didUpdateWidget(old);
    if (old.year != widget.year) _year = widget.year;
  }

  void _prevMonth() => setState(() {
        _slideDir = -1;
        if (_month == 1) { _month = 12; _year--; }
        else               _month--;
      });

  void _nextMonth() => setState(() {
        _slideDir = 1;
        if (_month == 12) { _month = 1; _year++; }
        else                _month++;
      });

  void _goToday() => setState(() {
        final t = DateTime.now();
        _slideDir = DateTime(_year, _month).isBefore(t) ? 1 : -1;
        _month  = t.month;
        _year   = t.year;
      });

  @override
  Widget build(BuildContext context) {
    final counts = widget.store.yearCounts(widget.year);
    final result = computeStatus(counts);

    return Column(
      children: [
        // ── Month navigation bar ──────────────────────────────────────────
        Container(
          color: clrBgPanel,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: clrFg),
                onPressed: _prevMonth,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickMonth(context),
                  child: Text(
                    '${monthsEn[_month - 1]}  $_year',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: clrFg,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _goToday,
                child: const Text('Today', style: TextStyle(color: clrAccent)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: clrFg),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
        // ── Calendar grid (swipeable) ─────────────────────────────────────
        Expanded(
          child: Listener(
            onPointerDown: (e) => _dragStartX = e.position.dx,
            onPointerUp: (e) {
              final dx = e.position.dx - _dragStartX;
              if (dx < -60)      _nextMonth();
              else if (dx > 60)  _prevMonth();
            },
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final isNew = child.key == ValueKey('$_year-$_month');
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(isNew ? _slideDir.toDouble() : -_slideDir.toDouble(), 0),
                      end:   Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                    child: child,
                  );
                },
                child: Padding(
                  key: ValueKey('$_year-$_month'),
                  padding: const EdgeInsets.all(8),
                  child: CalendarGrid(
                    store:     widget.store,
                    year:      _year,
                    month:     _month,
                    onChanged: () {
                      widget.onChanged();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Status chip ───────────────────────────────────────────────────
        _StatusChip(result: result),
        // ── Category legend ───────────────────────────────────────────────
        _Legend(),
      ],
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => _MonthPickerDialog(current: _month),
    );
    if (picked != null) setState(() => _month = picked);
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final ComplianceResult result;
  const _StatusChip({required this.result});

  @override
  Widget build(BuildContext context) {
    final bg    = result.isOk ? const Color(0xFF1B4332) : const Color(0xFF4A0A14);
    final fg    = result.isOk ? clrOk : clrDanger;
    final lines = result.statusReason.split('\n');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        lines.first,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Category legend ───────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: clrBgPanel,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: cat.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 5),
                Text(cat.label, style: const TextStyle(color: clrFgDim, fontSize: 11)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

// ── Month picker dialog ───────────────────────────────────────────────────────

class _MonthPickerDialog extends StatelessWidget {
  final int current;
  const _MonthPickerDialog({required this.current});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: clrBgPanel,
      title: const Text('Select month', style: TextStyle(color: clrFg)),
      content: SizedBox(
        width: 280,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          childAspectRatio: 2.4,
          children: List.generate(12, (i) {
            final m = i + 1;
            return TextButton(
              onPressed: () => Navigator.pop(context, m),
              style: TextButton.styleFrom(
                backgroundColor: m == current ? clrAccent.withOpacity(0.2) : null,
                foregroundColor: m == current ? clrAccent : clrFg,
              ),
              child: Text(monthsEn[i].substring(0, 3)),
            );
          }),
        ),
      ),
    );
  }
}
