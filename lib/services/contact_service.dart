// lib/services/contact_service.dart
import 'dart:async';
import 'package:flutter_contacts/flutter_contacts.dart';

class CachedContact {
  final String displayName;
  final List<String> phones; // cleaned phone numbers
  final String normalized; // normalized displayName used for matching

  CachedContact({
    required this.displayName,
    required this.phones,
    required this.normalized,
  });

  @override
  String toString() => 'CachedContact(displayName: $displayName, phones: $phones)';
}

class ContactMatch {
  final CachedContact contact;
  final String phone; // selected phone number
  final double score; // 0..1, higher is better

  ContactMatch({
    required this.contact,
    required this.phone,
    required this.score,
  });
}

class ContactService {
  // In-memory cache: normalized name -> CachedContact
  final Map<String, CachedContact> _cache = {};
  bool _loaded = false;

  /// Load contacts into memory cache. Call this once at app start.
  /// Returns number of cached entries.
  Future<int> loadContacts() async {
    try {
      if (!await FlutterContacts.requestPermission()) return 0;
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      _cache.clear();
      for (final c in contacts) {
        final name = (c.displayName ?? '').trim();
        if (name.isEmpty) continue;

        // collect phone numbers (clean them)
        final phones = <String>[];
        for (final p in c.phones) {
          final num = (p.number ?? '').replaceAll(RegExp(r'[\s\-\(\)]'), '');
          if (num.isNotEmpty) phones.add(num);
        }
        if (phones.isEmpty) continue;

        final normalized = _normalize(name);
        final cached = CachedContact(displayName: name, phones: phones, normalized: normalized);

        // prefer exact normalized key; if collision, keep the first but also store alternate keys
        if (!_cache.containsKey(normalized)) _cache[normalized] = cached;

        // also store stripped-title variant (e.g., "Dr Shrija" -> "shrija")
        final noTitle = _normalize(_stripTitles(name));
        if (noTitle.isNotEmpty && !_cache.containsKey(noTitle)) {
          _cache[noTitle] = cached;
        }
      }

      _loaded = true;
      return _cache.length;
    } catch (e) {
      return 0;
    }
  }

  /// Return raw cached contacts (debug / UI)
  List<CachedContact> getCachedContacts() => _cache.values.toList();

  String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
  }

  String _stripTitles(String s) {
    return s.replaceAll(RegExp(r'\b(dr|doctor|mr|ms|mrs|miss|prof|sir)\.?\b', caseSensitive: false), '').trim();
  }

  /// Find the best contact match for a spoken name.
  /// Returns ContactMatch with score [0..1], or null if no sufficiently good match found.
  ///
  /// Matching strategy (scoring heuristic):
  /// - exact normalized match -> score 1.0
  /// - normalized contains target or target contains normalized -> 0.9
  /// - token overlap proportion (common tokens / tokens in target) -> 0.5..0.85
  /// - startsWith match -> 0.8
  /// - fallback: no match
  Future<ContactMatch?> findContactBySpokenName(String spoken, {double minScore = 0.45}) async {
    if (!_loaded) await loadContacts();
    final target = _normalize(spoken);
    if (target.isEmpty) return null;

    // 1) direct exact lookup
    if (_cache.containsKey(target)) {
      final c = _cache[target]!;
      return ContactMatch(contact: c, phone: c.phones.first, score: 1.0);
    }

    ContactMatch? best;
    for (final entry in _cache.entries) {
      final key = entry.key; // normalized stored key
      final c = entry.value;

      // quick exact contains checks
      if (key == target) {
        return ContactMatch(contact: c, phone: c.phones.first, score: 1.0);
      }

      if (key.contains(target) || target.contains(key)) {
        final score = 0.90;
        if (best == null || score > best.score) {
          best = ContactMatch(contact: c, phone: c.phones.first, score: score);
        }
        continue;
      }

      // token overlap scoring
      final keyTokens = key.split(' ').where((t) => t.isNotEmpty).toList();
      final targetTokens = target.split(' ').where((t) => t.isNotEmpty).toList();
      if (keyTokens.isEmpty || targetTokens.isEmpty) continue;

      int common = 0;
      for (final tk in targetTokens) {
        if (keyTokens.contains(tk)) common++;
      }
      final overlapRatio = common / targetTokens.length; // proportion of target tokens found in key
      double score = 0.0;
      if (overlapRatio > 0) {
        // scale: 1 token match -> 0.5, many tokens -> up to 0.85
        score = 0.5 + 0.35 * overlapRatio;
      }

      // startsWith / prefix matches are strong
      if (key.startsWith(target) || target.startsWith(key)) {
        score = max(score, 0.80);
      }

      if (score > 0) {
        if (best == null || score > best.score) {
          best = ContactMatch(contact: c, phone: c.phones.first, score: score);
        }
      }
    }

    if (best != null && best.score >= minScore) {
      return best;
    }

    return null;
  }
}

/// small helper since dart:math.max not imported locally
double max(double a, double b) => a > b ? a : b;
