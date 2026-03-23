import 'package:flutter/material.dart';

// ── Category codes ────────────────────────────────────────────────────────────

const String catBureau     = 'bureau';
const String catMaison     = 'maison';
const String catEnFrance   = 'en_france';
const String catHorsFrance = 'hors_france';
const String catNonRetour  = 'non_retour';
const String catConge      = 'conge';

class CategoryInfo {
  final String code;
  final String label;
  final Color color;
  const CategoryInfo(this.code, this.label, this.color);
}

const List<CategoryInfo> categories = [
  CategoryInfo(catBureau,     'Office (Switzerland)',   Color(0xFF4A90D9)),
  CategoryInfo(catMaison,     'Home (remote work)',     Color(0xFF27AE60)),
  CategoryInfo(catEnFrance,   'Mission in France',      Color(0xFFE74C3C)),
  CategoryInfo(catHorsFrance, 'Mission outside France', Color(0xFF9B59B6)),
  CategoryInfo(catNonRetour,  'Non-return day',         Color(0xFFE67E22)),
  CategoryInfo(catConge,      'Vacation / Sick leave',  Color(0xFF7F8C8D)),
];

Color categoryColor(String code) =>
    categories.firstWhere((c) => c.code == code, orElse: () => categories[0]).color;

String categoryLabel(String code) =>
    categories.firstWhere((c) => c.code == code, orElse: () => categories[0]).label;

// Short codes shown inside calendar cells
String categoryShort(String code) {
  switch (code) {
    case catBureau:     return 'OFF';
    case catMaison:     return 'HOM';
    case catEnFrance:   return 'MFR';
    case catHorsFrance: return 'MXX';
    case catNonRetour:  return 'NRR';
    case catConge:      return 'VAC';
    default:            return '';
  }
}

// ── Agreement thresholds ──────────────────────────────────────────────────────

const double teleworkRate       = 0.40;
const int    maxMissionImputed  = 10;
const int    maxHorsFrExchange  = 45;

// ── Calendar labels ───────────────────────────────────────────────────────────

const List<String> monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

