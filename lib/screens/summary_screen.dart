import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/compliance_result.dart';
import '../services/compliance_engine.dart';
import '../services/data_store.dart';

class SummaryScreen extends StatelessWidget {
  final DataStore store;
  final int       year;

  const SummaryScreen({super.key, required this.store, required this.year});

  @override
  Widget build(BuildContext context) {
    final counts = store.yearCounts(year);
    final result = computeStatus(counts);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusBanner(result: result),
        const SizedBox(height: 12),
        _QuotaCard(result: result),
        const SizedBox(height: 12),
        _CategoryCard(counts: counts),
        const SizedBox(height: 12),
        _ImputationCard(result: result),
      ],
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final ComplianceResult result;
  const _StatusBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final bg = result.isOk ? const Color(0xFF1B4332) : const Color(0xFF4A0A14);
    final fg = result.isOk ? clrOk : clrDanger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        result.statusReason,
        style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Quota card ────────────────────────────────────────────────────────────────

class _QuotaCard extends StatelessWidget {
  final ComplianceResult result;
  const _QuotaCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct   = result.teleworkPct;
    final color = result.isOk ? clrOk : clrDanger;

    return _Card(
      title: 'Remote Work Quota',
      child: Column(
        children: [
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontSize: 44, fontWeight: FontWeight.bold),
          ),
          Text(
            'limit: 40% of ${result.actualDays} working days = ${result.maxTeleworkDays} days',
            style: const TextStyle(color: clrFgDim, fontSize: 12),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 18,
              child: Stack(
                children: [
                  Container(color: clrBgCell),
                  FractionallySizedBox(
                    widthFactor: (pct / 100).clamp(0.0, 1.0),
                    child: Container(color: color),
                  ),
                  // 40% marker
                  FractionallySizedBox(
                    widthFactor: 0.40,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(width: 2, color: clrDanger),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${result.maxTeleworkDays - result.remainingTeleworkDays.clamp(0, result.maxTeleworkDays)} '
                      '/ ${result.maxTeleworkDays} days',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.remainingTeleworkDays >= 0
                ? '${result.remainingTeleworkDays} days remaining before limit'
                : '${result.remainingTeleworkDays.abs()} days OVER the limit',
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Category breakdown ────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final Map<String, int> counts;
  const _CategoryCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Day Breakdown',
      child: Column(
        children: categories.map((cat) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: cat.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(cat.label, style: const TextStyle(color: clrFg, fontSize: 13)),
              ),
              Text(
                '${counts[cat.code] ?? 0} days',
                style: const TextStyle(
                  color: clrFg, fontSize: 13, fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ── Imputation details ────────────────────────────────────────────────────────

class _ImputationCard extends StatelessWidget {
  final ComplianceResult result;
  const _ImputationCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Imputation Details',
      child: Column(
        children: [
          _MetricRow(
            label: 'FR missions imputed (max 10, within 40%):',
            value: '${result.missionsFranceImputed} / 10 days',
            valueColor: clrFg,
          ),
          _MetricRow(
            label: 'Outside-FR imputed within 40% quota:',
            value: '${result.missionsHorsFranceImputed} days',
          ),
          _MetricRow(
            label: 'Outside-FR total → 2005 exchange:',
            value: '${result.hfrExchangeUsed} / 45 days',
            valueColor: result.hfrExchangeUsed > maxHorsFrExchange ? clrDanger : clrFg,
          ),
          _MetricRow(
            label: '2005 exchange remaining:',
            value: '${result.remainingHorsFrance} days',
          ),
          _MetricRow(
            label: 'Recorded working days:',
            value: '${result.actualDays} days → quota ${result.maxTeleworkDays} days (40%)',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor = clrFgDim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: clrFgDim, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Shared card container ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: clrBgPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: clrAccent, fontSize: 13, fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: clrSeparator),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
