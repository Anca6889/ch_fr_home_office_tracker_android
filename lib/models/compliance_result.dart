class ComplianceResult {
  final Map<String, int> counts;
  final int    actualDays;
  final int    maxTeleworkDays;
  final int    domicileDays;
  final int    missionsFrance;
  final int    missionsHorsFrance;
  final int    quotaRemaining;
  final int    missionsFranceImputed;
  final int    missionsHorsFranceImputed;
  final int    effectiveTelework;
  final double teleworkPct;
  final int    remainingTeleworkDays;
  final int    hfrExchangeUsed;
  final int    remainingHorsFrance;
  final bool   isOk;
  final String statusReason;

  const ComplianceResult({
    required this.counts,
    required this.actualDays,
    required this.maxTeleworkDays,
    required this.domicileDays,
    required this.missionsFrance,
    required this.missionsHorsFrance,
    required this.quotaRemaining,
    required this.missionsFranceImputed,
    required this.missionsHorsFranceImputed,
    required this.effectiveTelework,
    required this.teleworkPct,
    required this.remainingTeleworkDays,
    required this.hfrExchangeUsed,
    required this.remainingHorsFrance,
    required this.isOk,
    required this.statusReason,
  });
}
