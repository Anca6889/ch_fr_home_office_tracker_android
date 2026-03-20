import 'package:flutter/material.dart';
import '../constants.dart';

/// Bottom sheet for assigning or clearing a day's category.
Future<String?> showCategoryPicker(
  BuildContext context, {
  required int day,
  required int month,
  required int year,
  String? current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: clrBgPanel,
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
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: clrSeparator,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '${monthsEn[month - 1]} $day, $year',
              style: const TextStyle(
                color: clrAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: clrSeparator, height: 1),
          ...categories.map((cat) => _CategoryTile(
                cat: cat,
                selected: cat.code == current,
                onTap: () => Navigator.pop(context, cat.code),
              )),
          const Divider(color: clrSeparator, height: 1),
          ListTile(
            leading: const Icon(Icons.clear, color: clrFgDim),
            title: const Text('Clear', style: TextStyle(color: clrFgDim)),
            onTap: () => Navigator.pop(context, ''),  // empty string = clear
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
    return ListTile(
      leading: Container(
        width: 16, height: 16,
        decoration: BoxDecoration(
          color: cat.color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      title: Text(cat.label, style: TextStyle(color: selected ? clrAccent : clrFg)),
      trailing: selected
          ? const Icon(Icons.check, color: clrAccent, size: 18)
          : null,
      onTap: onTap,
    );
  }
}
