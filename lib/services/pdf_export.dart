import 'dart:math';
import 'package:flutter/material.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants.dart';
import '../models/compliance_result.dart';
import '../services/compliance_engine.dart';
import '../services/data_store.dart';

/// Generates and shares a yearly PDF report.
Future<void> exportPdf(
  BuildContext context,
  DataStore store,
  int year,
  String username,
) async {
  final counts = store.yearCounts(year);
  final result = computeStatus(counts);

  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold    = await PdfGoogleFonts.notoSansBold();

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    ),
  );
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    build: (ctx) => _buildPage(store, year, username, counts, result),
  ));

  await Printing.layoutPdf(
    onLayout: (_) async => pdf.save(),
    name: 'home_office_${_safe(username)}_$year.pdf',
  );
}

String _safe(String s) => s.replaceAll(RegExp(r'[^\w\-.]'), '_');

// ── PdfColor helpers ──────────────────────────────────────────────────────────

PdfColor _hex(String h) {
  final v = int.parse(h.replaceFirst('#', ''), radix: 16);
  return PdfColor.fromInt(v | 0xFF000000);
}

final _dark   = _hex('#1A1B2E');
final _panel  = _hex('#252640');
final _accent = _hex('#7EB8F0');
final _fgDim  = _hex('#6C6F9C');
final _fgMain = _hex('#D0D3F0');
final _bgPage = _hex('#F7F8FC');
final _bgMnth = PdfColors.white;
final _border = _hex('#DDDDEE');
final _wkend  = _hex('#F0F0F4');
final _wkFg   = _hex('#AAAABC');

// ── Page root ─────────────────────────────────────────────────────────────────

pw.Widget _buildPage(
  DataStore store,
  int year,
  String username,
  Map<String, int> counts,
  ComplianceResult result,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _buildHeader(year, username),
      pw.SizedBox(height: 8),
      pw.Expanded(child: _buildMonthGrid(store, year)),
      pw.SizedBox(height: 8),
      _buildSummary(year, username, counts, result),
    ],
  );
}

// ── Header ────────────────────────────────────────────────────────────────────

pw.Widget _buildHeader(int year, String username) {
  final now = DateTime.now();
  final generated = '${monthsEn[now.month - 1]} ${now.day}, ${now.year}';

  return pw.Container(
    height: 60,
    decoration: pw.BoxDecoration(
      color: _dark,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Stack(
      children: [
        pw.Positioned(
          left: 14, top: 10,
          child: pw.Text(
            'Home Office Tracking',
            style: pw.TextStyle(color: _accent, fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Positioned(
          left: 14, top: 28,
          child: pw.Text(
            'Franco-Swiss Agreement - April 11, 1983  |  Remote Work Tracking',
            style: pw.TextStyle(color: _fgDim, fontSize: 7.5),
          ),
        ),
        pw.Positioned(
          left: 14, bottom: 8,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: pw.BoxDecoration(
              color: _panel,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              username,
              style: pw.TextStyle(color: _fgMain, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        pw.Positioned(
          right: 14, top: 10,
          child: pw.Text(
            '$year',
            style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Positioned(
          right: 14, bottom: 8,
          child: pw.Text(
            'Generated $generated',
            style: pw.TextStyle(color: _fgDim, fontSize: 7),
          ),
        ),
      ],
    ),
  );
}

// ── 3×4 month calendar grid ───────────────────────────────────────────────────

pw.Widget _buildMonthGrid(DataStore store, int year) {
  const ncols = 3;
  const nrows = 4;
  final months = List.generate(12, (i) => i + 1);

  return pw.Column(
    children: List.generate(nrows, (row) => pw.Expanded(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: List.generate(ncols, (col) {
          final monthNum = row * ncols + col + 1;
          return pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.only(
                right: col < ncols - 1 ? 5 : 0,
                bottom: row < nrows - 1 ? 5 : 0,
              ),
              child: _buildMonth(store, year, monthNum),
            ),
          );
        }),
      ),
    )),
  );
}

pw.Widget _buildMonth(DataStore store, int year, int month) {
  final dayData    = store.monthDays(year, month);
  final firstDow   = DateTime(year, month, 1).weekday - 1;
  final daysInMon  = DateTime(year, month + 1, 0).day;
  final weeks      = List.generate(6, (_) => List.filled(7, 0));
  for (int d = 1; d <= daysInMon; d++) {
    final slot = firstDow + d - 1;
    weeks[slot ~/ 7][slot % 7] = d;
  }

  final dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _border, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
    ),
    child: pw.Column(
      children: [
        // Month name header
        pw.Container(
          color: _panel,
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Center(
            child: pw.Text(
              monthsEn[month - 1].toUpperCase(),
              style: pw.TextStyle(color: _accent, fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        // Day headers
        pw.Row(
          children: dayHeaders.asMap().entries.map((e) => pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                e.value,
                style: pw.TextStyle(
                  color: e.key >= 5 ? _wkFg : _fgDim,
                  fontSize: 5.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )).toList(),
        ),
        // Weeks
        ...weeks.map((week) => pw.Expanded(
          child: pw.Row(
            children: week.asMap().entries.map((e) {
              final dow    = e.key;
              final dayNum = e.value;
              final cat    = dayNum > 0 ? dayData['$dayNum'] : null;
              final isWknd = dow >= 5;

              PdfColor bg;
              PdfColor fg;
              if (cat != null) {
                final c = categories.firstWhere((c) => c.code == cat);
                bg = PdfColor.fromInt(c.color.value);
                fg = PdfColors.white;
              } else if (isWknd) {
                bg = _hex('#F0F0F4');
                fg = _wkFg;
              } else {
                bg = _bgMnth;
                fg = _hex('#1A1B2E');
              }

              return pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(0.5),
                  color: dayNum > 0 ? bg : _hex('#FAFAFA'),
                  child: dayNum > 0
                      ? pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 1.5, top: 1),
                              child: pw.Text(
                                '$dayNum',
                                style: pw.TextStyle(
                                  color: fg,
                                  fontSize: 5.5,
                                  fontWeight: cat != null
                                      ? pw.FontWeight.bold
                                      : pw.FontWeight.normal,
                                ),
                              ),
                            ),
                            if (cat != null)
                              pw.Expanded(
                                child: pw.Center(
                                  child: pw.Text(
                                    categoryShort(cat),
                                    style: const pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 4,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : pw.SizedBox(),
                ),
              );
            }).toList(),
          ),
        )),
      ],
    ),
  );
}

// ── Summary section ───────────────────────────────────────────────────────────

pw.Widget _buildSummary(
  int year,
  String username,
  Map<String, int> counts,
  ComplianceResult r,
) {
  final isOk     = r.isOk;
  final statusBg = isOk ? _hex('#1B4332') : _hex('#4A0A14');
  final statusFg = isOk ? _hex('#5CBF8A') : _hex('#E85C6A');
  final reason   = r.statusReason.replaceAll('\n', '  ');

  return pw.Container(
    height: 148,
    decoration: pw.BoxDecoration(
      color: _dark,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── Band C: title + status ────────────────────────────────────────
        pw.SizedBox(height: 6),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'YEARLY SUMMARY - $year  |  $username',
                style: pw.TextStyle(color: _accent, fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: statusBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  reason.length > 68 ? '${reason.substring(0, 65)}…' : reason,
                  style: pw.TextStyle(color: statusFg, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _fgDim, thickness: 0.5, indent: 12, endIndent: 12),
        // ── Band B: 6 key metrics ────────────────────────────────────────
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _metric('Working days',       '${r.actualDays}'),
                _metric('Remote quota (40%)', '${r.maxTeleworkDays}'),
                _metric('Effective remote',   '${r.effectiveTelework}'),
                _metric('Remote rate',        '${r.teleworkPct.toStringAsFixed(1)}%'),
                _metric('Days remaining',     '${r.remainingTeleworkDays}'),
                _metric('2005 exchange',      '${r.hfrExchangeUsed} / 45'),
              ],
            ),
          ),
        ),
        pw.Divider(color: _fgDim, thickness: 0.5, indent: 12, endIndent: 12),
        // ── Band A: category counters ────────────────────────────────────
        pw.Expanded(
          flex: 2,
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: categories.map((cat) {
                final catColor = PdfColor.fromInt(cat.color.value);
                final count    = counts[cat.code] ?? 0;
                final label    = cat.label
                    .replaceAll(' (Switzerland)', '')
                    .replaceAll(' (remote work)', '');
                return pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 10, height: 10,
                      decoration: pw.BoxDecoration(
                        color: catColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '$count',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'days',
                      style: pw.TextStyle(color: _fgDim, fontSize: 6),
                    ),
                    pw.Text(
                      label,
                      style: pw.TextStyle(color: _fgMain, fontSize: 5.5),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    ),
  );
}

pw.Widget _metric(String label, String value) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: [
      pw.Text(
        value,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.Text(
        label,
        style: pw.TextStyle(color: _fgDim, fontSize: 5.5),
      ),
    ],
  );
}
