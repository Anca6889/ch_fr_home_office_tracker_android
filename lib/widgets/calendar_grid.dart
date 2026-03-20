import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/data_store.dart';
import 'category_picker_sheet.dart';

class CalendarGrid extends StatelessWidget {
  final DataStore store;
  final int       year;
  final int       month;
  final VoidCallback onChanged;

  const CalendarGrid({
    super.key,
    required this.store,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final weeks    = _buildWeeks(year, month);
    final dayData  = store.monthDays(year, month);
    final today    = DateTime.now();

    return Column(
      children: [
        // Day-of-week header
        Row(
          children: daysEn.asMap().entries.map((e) {
            final isWknd = e.key >= 5;
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: isWknd ? clrFgDim : clrAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(color: clrSeparator, height: 1),
        // Weeks
        ...weeks.map((week) => Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: week.asMap().entries.map((e) {
                  final dow    = e.key;
                  final dayNum = e.value;
                  return Expanded(
                    child: _DayCell(
                      dayNum:    dayNum,
                      dow:       dow,
                      year:      year,
                      month:     month,
                      category:  dayNum > 0 ? dayData['$dayNum'] : null,
                      isToday:   dayNum > 0 &&
                                 today.year  == year  &&
                                 today.month == month &&
                                 today.day   == dayNum,
                      onTap: dayNum > 0 && dow < 5
                          ? () => _handleTap(context, dayNum, dayData['$dayNum'])
                          : null,
                    ),
                  );
                }).toList(),
              ),
            )),
      ],
    );
  }

  Future<void> _handleTap(
      BuildContext context, int dayNum, String? current) async {
    final result = await showCategoryPicker(
      context,
      day: dayNum, month: month, year: year,
      current: current,
    );
    if (result == null) return; // dismissed
    await store.set(year, month, dayNum, result.isEmpty ? null : result);
    onChanged();
  }

  /// Returns 6 weeks × 7 days (0 = empty cell).
  static List<List<int>> _buildWeeks(int year, int month) {
    final firstDow   = DateTime(year, month, 1).weekday - 1; // 0=Mon
    final daysInMon  = DateTime(year, month + 1, 0).day;
    final weeks      = List.generate(6, (_) => List.filled(7, 0));

    for (int day = 1; day <= daysInMon; day++) {
      final slot = firstDow + day - 1;
      weeks[slot ~/ 7][slot % 7] = day;
    }
    return weeks;
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int     dayNum;
  final int     dow;
  final int     year, month;
  final String? category;
  final bool    isToday;
  final VoidCallback? onTap;

  const _DayCell({
    required this.dayNum,
    required this.dow,
    required this.year,
    required this.month,
    required this.isToday,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (dayNum == 0) {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: const BoxDecoration(color: clrBg),
      );
    }

    final isWknd = dow >= 5;
    final Color bg;
    final Color numFg;

    if (category != null) {
      bg    = categoryColor(category!);
      numFg = Colors.white;
    } else if (isToday) {
      bg    = clrBgToday;
      numFg = clrAccent;
    } else if (isWknd) {
      bg    = clrBgCellWk;
      numFg = clrFgDim;
    } else {
      bg    = clrBgCell;
      numFg = clrFg;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg,
          border: isToday
              ? Border.all(color: clrAccent, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 3),
              child: Text(
                '$dayNum',
                style: TextStyle(
                  color: numFg,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (category != null)
              Expanded(
                child: Center(
                  child: Text(
                    categoryShort(category!),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
