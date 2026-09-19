import 'package:intl/intl.dart';

/// Display label <-> backend enum, identical to BLOOD_GROUP_TO_API in the
/// web client's common.js. The backend stores A_POSITIVE etc.
const Map<String, String> bloodGroupToApi = {
  'A+': 'A_POSITIVE',
  'A-': 'A_NEGATIVE',
  'B+': 'B_POSITIVE',
  'B-': 'B_NEGATIVE',
  'AB+': 'AB_POSITIVE',
  'AB-': 'AB_NEGATIVE',
  'O+': 'O_POSITIVE',
  'O-': 'O_NEGATIVE',
};

String toApiBloodGroup(String display) =>
    bloodGroupToApi[display] ?? display;

String fromApiBloodGroup(String? api) {
  if (api == null || api.isEmpty) return '';
  for (final entry in bloodGroupToApi.entries) {
    if (entry.value == api) return entry.key;
  }
  return api;
}

/// Standard whole-blood donation protocol (WHO / Red Cross guidance),
/// matching the values enforced in the web client.
const int donationEligibilityDays = 56;
const int minDonationAge = 18;
const int minDonationWeightKg = 50;

DateTime? computeNextEligibleDate(dynamic lastDonationDate) {
  final last = parseDate(lastDonationDate);
  if (last == null) return null;
  return last.add(const Duration(days: donationEligibilityDays));
}

bool isEligibleByInterval(dynamic lastDonationDate) {
  final next = computeNextEligibleDate(lastDonationDate);
  return next == null || !next.isAfter(DateTime.now());
}

/// Result of evaluating the full donation protocol.
class EligibilityResult {
  final bool eligible;
  final List<String> reasons;
  final DateTime? nextEligible;

  EligibilityResult(this.eligible, this.reasons, this.nextEligible);
}

/// Full donation eligibility protocol: minimum age, minimum weight, the
/// 56-day interval since the last donation, and any admin-set NOT_ELIGIBLE
/// status. Returns every failing reason so the UI can explain exactly why
/// the donor can't donate right now — same behaviour as the web app.
EligibilityResult getDonationEligibility(Map<String, dynamic> profile) {
  final reasons = <String>[];

  final status =
      (profile['donorStatus'] ?? profile['status'] ?? '').toString().toUpperCase();
  if (status == 'NOT_ELIGIBLE') {
    reasons.add('Your account is currently marked as not eligible to donate.');
  }

  final age = _asNum(profile['age']);
  if (age != null && age < minDonationAge) {
    reasons.add('Minimum donation age is $minDonationAge.');
  }

  final weight = _asNum(profile['weight']);
  if (weight != null && weight < minDonationWeightKg) {
    reasons.add('Minimum donation weight is $minDonationWeightKg kg.');
  }

  final next = computeNextEligibleDate(profile['lastDonationDate']);
  if (next != null && next.isAfter(DateTime.now())) {
    reasons.add('You can donate again on ${formatDate(next)}.');
  }

  return EligibilityResult(reasons.isEmpty, reasons, next);
}

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

/// True if two dates fall on the same calendar day (local time).
bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/* ---------- Date helpers ---------- */

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String formatDate(dynamic value) {
  final d = parseDate(value);
  if (d == null) return '—';
  return DateFormat('d MMM yyyy').format(d);
}

String formatDateTime(dynamic value) {
  final d = parseDate(value);
  if (d == null) return '—';
  return DateFormat('d MMM yyyy • h:mm a').format(d);
}
