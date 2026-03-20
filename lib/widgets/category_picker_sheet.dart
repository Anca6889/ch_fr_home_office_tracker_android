import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../constants.dart';

/// Bottom sheet for assigning or clearing a day's category.
Future<String?> showCategoryPicker(
  BuildContext context, {
  required int day,
  required int month,
  required int year,
  String? current,
}) {
  final c = AppTheme.of(context).colors;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: c.bgPanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CategoryPickerSheet(
      day: day, month: month, year: year, current: current,
    ),
  );
}

class _CategoryPickerSheet extends StatelessWidget {
  final int     day, month, year;
  final String? current;

  const _CategoryPickerSheet({
    required this.day,
    required this.month,
    required this.year,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context).colors;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: c.separator,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '${monthsEn[month - 1]} $day, $year',
              style: TextStyle(
                color: c.accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: c.separator, height: 1),
          ...categories.map((cat) => _CategoryTile(
                cat: cat,
                selected: cat.code == current,
                onTap: () => Navigator.pop(context, cat.code),
              )),
          Divider(color: c.separator, height: 1),
          ListTile(
            leading: Icon(Icons.clear, color: c.fgDim),
            title: Text('Clear', style: TextStyle(color: c.fgDim)),
            onTap: () => Navigator.pop(context, ''),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryInfo cat;
  final bool         selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.cat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context).colors;
    return ListTile(
      leading: Container(
        width: 16, height: 16,
        decoration: BoxDecoration(
          color: cat.color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      title: Text(cat.label, style: TextStyle(color: selected ? c.accent : c.fg)),
      trailing: selected
          ? Icon(Icons.check, color: c.accent, size: 18)
          : null,
      onTap: onTap,
    );
  }
}
