import '../constants.dart';
import '../models/compliance_result.dart';

/// Franco-Swiss Agreement of April 11, 1983 + interpretive agreements (2022/2023).
///
/// 40% rule:
///   Home days count fully toward the quota.
///   Missions (France + outside-France combined) can be imputed up to BOTH:
///     (a) max 10 days/year combined, AND
///     (b) remaining capacity in the 40% quota after home days.
///   Priority: home days first, then France missions, then outside-France.
///   If ALL France missions cannot be imputed → agreement inapplicable.
///
/// 2005 exchange (45-day rule):
///   Annual TOTAL cap on outside-France days (art. 1d + bilateral exchange
///   of letters Feb. 2005). Any total > 45 → agreement inapplicable.
ComplianceResult computeStatus(Map<String, int> counts) {
  final domicile    = counts[catMaison]     ?? 0;
  final missionsFr  = counts[catEnFrance]   ?? 0;
  final missionsHfr = counts[catHorsFrance] ?? 0;
  final bureau      = counts[catBureau]     ?? 0;

  final actualDays      = bureau + domicile + missionsFr + missionsHfr;
  final maxTeleworkDays = (actualDays * teleworkRate).floor();

  final quotaRemaining = (maxTeleworkDays - domicile).clamp(0, maxTeleworkDays);
  final maxImputable   = maxMissionImputed < quotaRemaining
      ? maxMissionImputed
      : quotaRemaining;

  // ── Rule 1: all France missions must be imputable ─────────────────────────
  if (missionsFr > maxImputable) {
    final twPct = actualDays > 0 ? domicile / actualDays * 100 : 0.0;
    return _makeResult(
      counts, domicile, missionsFr, missionsHfr,
      actualDays, maxTeleworkDays, quotaRemaining,
      mfrImp: 0, mhfrImp: 0,
      effTw: domicile, twPct: twPct, remTw: quotaRemaining,
      isOk: false,
      reason: '⚠ France missions cannot be fully imputed\n'
              '$missionsFr days > $maxImputable max imputable\n'
              '(agreement inapplicable)',
    );
  }

  final mfrImp  = missionsFr;
  final capHfr  = maxImputable - mfrImp;
  final mhfrImp = missionsHfr < capHfr ? missionsHfr : capHfr;

  final effTw = domicile + mfrImp + mhfrImp;
  final twPct = actualDays > 0 ? effTw / actualDays * 100 : 0.0;
  final remTw = maxTeleworkDays - effTw;

  // ── Rule 2: TOTAL outside-France days ≤ 45 (2005 exchange) ───────────────
  if (missionsHfr > maxHorsFrExchange) {
    return _makeResult(
      counts, domicile, missionsFr, missionsHfr,
      actualDays, maxTeleworkDays, quotaRemaining,
      mfrImp: mfrImp, mhfrImp: mhfrImp,
      effTw: effTw, twPct: twPct, remTw: remTw,
      isOk: false,
      reason: '⚠ 2005 exchange limit exceeded\n'
              'Total outside-France: $missionsHfr days > 45\n'
              '→ Agreement inapplicable',
    );
  }

  // ── Rule 3: effective telework ≤ 40% (safety check) ──────────────────────
  if (twPct > 40.0) {
    return _makeResult(
      counts, domicile, missionsFr, missionsHfr,
      actualDays, maxTeleworkDays, quotaRemaining,
      mfrImp: mfrImp, mhfrImp: mhfrImp,
      effTw: effTw, twPct: twPct, remTw: remTw,
      isOk: false,
      reason: '⚠ Remote work quota exceeded '
              '(${twPct.toStringAsFixed(1)}% > 40%)\n→ Agreement inapplicable',
    );
  }

  // ── All good ──────────────────────────────────────────────────────────────
  final String reason;
  if (remTw == 0) {
    reason = 'Remote work quota reached (${twPct.toStringAsFixed(1)}%) - stay in the office';
  } else if (remTw <= 3) {
    reason = 'Status OK - only $remTw remote day(s) remaining';
  } else {
    reason = 'Frontalier status compliant - $remTw days remaining';
  }

  return _makeResult(
    counts, domicile, missionsFr, missionsHfr,
    actualDays, maxTeleworkDays, quotaRemaining,
    mfrImp: mfrImp, mhfrImp: mhfrImp,
    effTw: effTw, twPct: twPct, remTw: remTw,
    isOk: true, reason: reason,
  );
}

ComplianceResult _makeResult(
  Map<String, int> counts,
  int domicile, int mfr, int mhfr,
  int actualDays, int maxTeleworkDays, int quotaRem, {
  required int    mfrImp,
  required int    mhfrImp,
  required int    effTw,
  required double twPct,
  required int    remTw,
  required bool   isOk,
  required String reason,
}) {
  return ComplianceResult(
    counts:                       counts,
    actualDays:                   actualDays,
    maxTeleworkDays:              maxTeleworkDays,
    domicileDays:                 domicile,
    missionsFrance:               mfr,
    missionsHorsFrance:           mhfr,
    quotaRemaining:               quotaRem,
    missionsFranceImputed:        mfrImp,
    missionsHorsFranceImputed:    mhfrImp,
    effectiveTelework:            effTw,
    teleworkPct:                  twPct,
    remainingTeleworkDays:        remTw,
    hfrExchangeUsed:              mhfr,
    remainingHorsFrance:          maxHorsFrExchange - mhfr,
    isOk:                         isOk,
    statusReason:                 reason,
  );
}
