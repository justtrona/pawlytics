import 'package:flutter/material.dart';
import 'need_check.dart';

class NeedsGrid extends StatelessWidget {
  final Map<String, bool> items;
  final void Function(String, bool) onToggle;

  const NeedsGrid({super.key, required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final keys = items.keys.toList();

    List<TableRow> rows = [];
    for (int i = 0; i < keys.length; i += 2) {
      final k1 = keys[i];
      final k2 = (i + 1 < keys.length) ? keys[i + 1] : null;

      rows.add(
        TableRow(
          children: [
            NeedCheck(
              label: k1,
              value: items[k1]!,
              onChanged: (v) => onToggle(k1, v),
            ),
            if (k2 != null)
              NeedCheck(
                label: k2,
                value: items[k2]!,
                onChanged: (v) => onToggle(k2, v),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }
}
