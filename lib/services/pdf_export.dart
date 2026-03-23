import 'package:flutter/material.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants.dart';
import '../models/compliance_result.dart';
import '../services/compliance_engine.dart';
import '../services/data_store.dart';

// ── Localisation ──────────────────────────────────────────────────────────────

class _L {
  final String langCode;
  final String title;
  final String subtitle;
  final String generatedPrefix;
  final String yearlySummary;
  final String daysLabel;
  final String metricWorkingDays;
  final String metricRemoteQuota;
  final String metricEffectiveRemote;
  final String metricRemoteRate;
  final String metricDaysRemaining;
  final String metricExchange2005;
  final List<String> months;
  final List<String> dayLetters;
  // Short labels -same order as `categories` list in constants.dart
  final List<String> catShortLabels;

  const _L({
    required this.langCode,
    required this.title,
    required this.subtitle,
    required this.generatedPrefix,
    required this.yearlySummary,
    required this.daysLabel,
    required this.metricWorkingDays,
    required this.metricRemoteQuota,
    required this.metricEffectiveRemote,
    required this.metricRemoteRate,
    required this.metricDaysRemaining,
    required this.metricExchange2005,
    required this.months,
    required this.dayLetters,
    required this.catShortLabels,
  });

  String formattedDate(DateTime d) {
    if (langCode == 'fr') {
      return '${d.day} ${months[d.month - 1].toLowerCase()} ${d.year}';
    }
    if (langCode == 'de') {
      return '${d.day}. ${months[d.month - 1]} ${d.year}';
    }
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// categories order: bureau, maison, en_france, hors_france, non_retour, conge

final _en = _L(
  langCode: 'en',
  title: 'Home Office Tracking',
  subtitle: 'Franco-Swiss frontier worker - telework & temporary mission day tracker',
  generatedPrefix: 'Generated',
  yearlySummary: 'YEARLY SUMMARY',
  daysLabel: 'days',
  metricWorkingDays: 'Working days',
  metricRemoteQuota: 'Remote quota (40%)',
  metricEffectiveRemote: 'Effective remote',
  metricRemoteRate: 'Remote rate',
  metricDaysRemaining: 'Days remaining',
  metricExchange2005: '2005 exch. (MXX+NRR)',
  months: ['January','February','March','April','May','June',
           'July','August','September','October','November','December'],
  dayLetters: ['M','T','W','T','F','S','S'],
  catShortLabels: ['Office','Home','Mission FR','Outside FR','Non-return','Vacation'],
);

final _fr = _L(
  langCode: 'fr',
  title: 'Suivi Télétravail',
  subtitle: 'Frontalier franco-suisse - suivi des jours de teletravail et missions temporaires',
  generatedPrefix: 'Généré le',
  yearlySummary: 'RÉSUMÉ ANNUEL',
  daysLabel: 'jours',
  metricWorkingDays: 'Jours travaillés',
  metricRemoteQuota: 'Quota TT (40%)',
  metricEffectiveRemote: 'TT effectif',
  metricRemoteRate: 'Taux TT',
  metricDaysRemaining: 'Jours restants',
  metricExchange2005: 'Échange 2005 (MXX+NRR)',
  months: ['Janvier','Février','Mars','Avril','Mai','Juin',
           'Juillet','Août','Septembre','Octobre','Novembre','Décembre'],
  dayLetters: ['L','M','M','J','V','S','D'],
  catShortLabels: ['Bureau','Domicile','Mission FR','Hors FR','Non-retour','Congé'],
);

final _de = _L(
  langCode: 'de',
  title: 'Homeoffice-Tracking',
  subtitle: 'Grenzganger Frankreich-Schweiz - Erfassung von Homeoffice- und Missionstagen',
  generatedPrefix: 'Erstellt am',
  yearlySummary: 'JAHRESÜBERSICHT',
  daysLabel: 'Tage',
  metricWorkingDays: 'Arbeitstage',
  metricRemoteQuota: 'HO-Quote (40%)',
  metricEffectiveRemote: 'Eff. Homeoffice',
  metricRemoteRate: 'HO-Rate',
  metricDaysRemaining: 'Verbl. Tage',
  metricExchange2005: 'Austausch 2005 (MXX+NRR)',
  months: ['Januar','Februar','März','April','Mai','Juni',
           'Juli','August','September','Oktober','November','Dezember'],
  dayLetters: ['M','D','M','D','F','S','S'],
  catShortLabels: ['Büro','Zuhause','Mission FR','Außerh. FR','Nichtrückkehr','Urlaub'],
);

// ── Entry point ───────────────────────────────────────────────────────────────

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
    theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
  );

  for (final l in [_en, _fr, _de]) {
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => _buildPage(store, year, username, counts, result, l),
    ));
  }

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

final _headerBg   = _hex('#EEF0FB');
final _monthHdrBg = _hex('#DDE0F5');
final _accent     = _hex('#2A5FA8');
final _fgDim      = _hex('#6C6F9C');
final _fgMain     = _hex('#1A1B2E');
final _bgMnth     = PdfColors.white;
final _border     = _hex('#DDDDEE');
final _wkFg       = _hex('#AAAABC');

// ── Flag widget ───────────────────────────────────────────────────────────────
//
// Flags are drawn entirely with PDF drawing primitives -no external assets.
// The Union Jack uses CustomPaint to draw diagonal and straight stripes.

pw.Widget _buildFlag(String langCode) {
  const w = 30.0, h = 20.0;
  final frameBorder = pw.BoxDecoration(
    border: pw.Border.all(color: _hex('#BBBBCC'), width: 0.4),
  );

  switch (langCode) {
    // ── French tricolour (vertical blue / white / red) ────────────────────
    case 'fr':
      return pw.Container(
        width: w, height: h,
        decoration: frameBorder,
        child: pw.Row(children: [
          pw.Expanded(child: pw.Container(color: _hex('#002395'))),
          pw.Expanded(child: pw.Container(color: PdfColors.white)),
          pw.Expanded(child: pw.Container(color: _hex('#ED2939'))),
        ]),
      );

    // ── German tricolour (horizontal black / red / gold) ──────────────────
    case 'de':
      return pw.Container(
        width: w, height: h,
        decoration: frameBorder,
        child: pw.Column(children: [
          pw.Expanded(child: pw.Container(color: PdfColors.black)),
          pw.Expanded(child: pw.Container(color: _hex('#DD0000'))),
          pw.Expanded(child: pw.Container(color: _hex('#FFCE00'))),
        ]),
      );

    // ── Union Jack ────────────────────────────────────────────────────────
    // Layers (bottom to top):
    //   1. Blue background
    //   2. White X saltire (St Andrew's cross)
    //   3. Red X saltire (St Patrick's cross, thinner)
    //   4. White + cross (wide)
    //   5. Red + cross (narrow)
    // A clip path is set first so thick diagonal strokes don't overflow.
    default:
      return pw.Container(
        width: w, height: h,
        decoration: frameBorder,
        child: pw.CustomPaint(
          size: PdfPoint(w, h),
          painter: (canvas, size) {
            final W = size.x;
            final H = size.y;

            // Clip all drawing to flag bounds
            canvas.saveContext();
            canvas.moveTo(0, 0);
            canvas.lineTo(W, 0);
            canvas.lineTo(W, H);
            canvas.lineTo(0, H);
            canvas.closePath();
            canvas.clipPath();

            // 1. Blue background
            canvas
              ..setFillColor(_hex('#012169'))
              ..drawRect(0, 0, W, H)
              ..fillPath();

            // 2. White X diagonals -PDF y: 0=bottom, H=top
            canvas.setStrokeColor(PdfColors.white);
            canvas.setLineWidth(H * 0.22);
            canvas.moveTo(0, 0); canvas.lineTo(W, H); canvas.strokePath();
            canvas.moveTo(0, H); canvas.lineTo(W, 0); canvas.strokePath();

            // 3. Red X diagonals (thinner, centred -simplified St Patrick's)
            canvas.setStrokeColor(_hex('#C8102E'));
            canvas.setLineWidth(H * 0.11);
            canvas.moveTo(0, 0); canvas.lineTo(W, H); canvas.strokePath();
            canvas.moveTo(0, H); canvas.lineTo(W, 0); canvas.strokePath();

            // 4. White + cross (wide)
            canvas.setStrokeColor(PdfColors.white);
            canvas.setLineWidth(H * 0.38);
            canvas.moveTo(0, H / 2); canvas.lineTo(W, H / 2); canvas.strokePath();
            canvas.moveTo(W / 2, 0); canvas.lineTo(W / 2, H); canvas.strokePath();

            // 5. Red + cross (narrow)
            canvas.setStrokeColor(_hex('#C8102E'));
            canvas.setLineWidth(H * 0.22);
            canvas.moveTo(0, H / 2); canvas.lineTo(W, H / 2); canvas.strokePath();
            canvas.moveTo(W / 2, 0); canvas.lineTo(W / 2, H); canvas.strokePath();

            canvas.restoreContext();
          },
        ),
      );
  }
}

// ── Page root ─────────────────────────────────────────────────────────────────

pw.Widget _buildPage(
  DataStore store,
  int year,
  String username,
  Map<String, int> counts,
  ComplianceResult result,
  _L l,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _buildHeader(year, username, l),
      pw.SizedBox(height: 8),
      pw.Expanded(child: _buildMonthGrid(store, year, l)),
      pw.SizedBox(height: 8),
      _buildSummary(year, username, counts, result, l),
    ],
  );
}

// ── Header ────────────────────────────────────────────────────────────────────

pw.Widget _buildHeader(int year, String username, _L l) {
  final now       = DateTime.now();
  final generated = '${l.generatedPrefix} ${l.formattedDate(now)}';

  return pw.Container(
    height: 60,
    decoration: pw.BoxDecoration(
      color: _headerBg,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      border: pw.Border.all(color: _border, width: 0.5),
    ),
    child: pw.Stack(
      children: [
        pw.Positioned(
          left: 14, top: 10,
          child: pw.Text(
            l.title,
            style: pw.TextStyle(color: _accent, fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Positioned(
          left: 14, top: 28,
          child: pw.Text(
            l.subtitle,
            style: pw.TextStyle(color: _fgDim, fontSize: 7.5),
          ),
        ),
        pw.Positioned(
          left: 14, bottom: 8,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: pw.BoxDecoration(
              color: _monthHdrBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              username,
              style: pw.TextStyle(color: _fgMain, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        // Flag + year -top right
        pw.Positioned(
          right: 14, top: 9,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildFlag(l.langCode),
              pw.SizedBox(width: 8),
              pw.Text(
                '$year',
                style: pw.TextStyle(color: _fgMain, fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.Positioned(
          right: 14, bottom: 8,
          child: pw.Text(
            generated,
            style: pw.TextStyle(color: _fgDim, fontSize: 7),
          ),
        ),
      ],
    ),
  );
}

// ── 3×4 month calendar grid ───────────────────────────────────────────────────

pw.Widget _buildMonthGrid(DataStore store, int year, _L l) {
  const ncols = 3;
  const nrows = 4;

  return pw.Column(
    children: List.generate(nrows, (row) => pw.Expanded(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: List.generate(ncols, (col) {
          final monthNum = row * ncols + col + 1;
          return pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.only(
                right:  col < ncols - 1 ? 5 : 0,
                bottom: row < nrows - 1 ? 5 : 0,
              ),
              child: _buildMonth(store, year, monthNum, l),
            ),
          );
        }),
      ),
    )),
  );
}

pw.Widget _buildMonth(DataStore store, int year, int month, _L l) {
  final dayData   = store.monthDays(year, month);
  final firstDow  = DateTime(year, month, 1).weekday - 1;
  final daysInMon = DateTime(year, month + 1, 0).day;
  final weeks     = List.generate(6, (_) => List.filled(7, 0));
  for (int d = 1; d <= daysInMon; d++) {
    final slot = firstDow + d - 1;
    weeks[slot ~/ 7][slot % 7] = d;
  }

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _border, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
    ),
    child: pw.Column(
      children: [
        // Month name header
        pw.Container(
          color: _monthHdrBg,
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Center(
            child: pw.Text(
              l.months[month - 1].toUpperCase(),
              style: pw.TextStyle(color: _accent, fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        // Day-of-week headers
        pw.Row(
          children: l.dayLetters.asMap().entries.map((e) => pw.Expanded(
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
  _L l,
) {
  final isOk     = r.isOk;
  final statusBg = isOk ? _hex('#D5F5E3') : _hex('#FAD7DA');
  final statusFg = isOk ? _hex('#1B6B3A') : _hex('#8B2030');
  // Language-neutral status: percentage + used/allowed
  final statusLine =
      '${r.teleworkPct.toStringAsFixed(1)}%  - '
      '${r.effectiveTelework} / ${r.maxTeleworkDays} ${l.daysLabel}';

  return pw.Container(
    height: 162,
    decoration: pw.BoxDecoration(
      color: _headerBg,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      border: pw.Border.all(color: _border, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── Title + status ──────────────────────────────────────────────────
        pw.SizedBox(height: 6),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${l.yearlySummary} - $year  |  $username',
                style: pw.TextStyle(color: _accent, fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: statusBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  statusLine,
                  style: pw.TextStyle(color: statusFg, fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _fgDim, thickness: 0.5, indent: 12, endIndent: 12),
        // ── 6 key metrics ───────────────────────────────────────────────────
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _metric(l.metricWorkingDays,     '${r.actualDays}'),
                _metric(l.metricRemoteQuota,     '${r.maxTeleworkDays}'),
                _metric(l.metricEffectiveRemote, '${r.effectiveTelework}'),
                _metric(l.metricRemoteRate,      '${r.teleworkPct.toStringAsFixed(1)}%'),
                _metric(l.metricDaysRemaining,   '${r.remainingTeleworkDays}'),
                _metric(l.metricExchange2005,    '${r.hfrExchangeUsed} / 45'),
              ],
            ),
          ),
        ),
        pw.Divider(color: _fgDim, thickness: 0.5, indent: 12, endIndent: 12),
        // ── Category counters ────────────────────────────────────────────────
        pw.Expanded(
          flex: 2,
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: categories.asMap().entries.map((e) {
                final cat      = e.value;
                final catColor = PdfColor.fromInt(cat.color.value);
                final count    = counts[cat.code] ?? 0;
                final label    = l.catShortLabels[e.key];
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
                        color: _fgMain, fontSize: 16, fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(l.daysLabel, style: pw.TextStyle(color: _fgDim, fontSize: 6)),
                    pw.Text(label,       style: pw.TextStyle(color: _fgDim, fontSize: 5.5)),
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
        style: pw.TextStyle(color: _fgMain, fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(label, style: pw.TextStyle(color: _fgDim, fontSize: 5.5)),
    ],
  );
}
