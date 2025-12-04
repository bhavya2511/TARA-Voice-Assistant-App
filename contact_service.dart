import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

Future<String?> getPhoneNumberFromContact(String name) async {
  if (!await Permission.contacts.request().isGranted) {
    debugPrint("Contact permission NOT granted!");
    return null;
  }

  final contacts = await FlutterContacts.getContacts(withProperties: true);
  debugPrint("Found ${contacts.length} contacts");

  List<String> contactNames = contacts.map((c) => c.displayName).toList();

  String? bestMatch;
  int highestScore = 0;

  for (var contactName in contactNames) {
    int score = ratio(contactName.toLowerCase(), name.toLowerCase());
    debugPrint('Comparing "$name" with "$contactName", score: $score');
    if (score > highestScore) {
      highestScore = score;
      bestMatch = contactName;
    }
  }

  debugPrint('Best match: $bestMatch with score $highestScore');
  if (bestMatch == null || highestScore < 70) {
    debugPrint('No suitable match found for "$name"');
    return null;
  }

  final matchedContact = contacts.firstWhere((c) => c.displayName == bestMatch);
  if (matchedContact.phones.isNotEmpty) {
    final number = matchedContact.phones.first.number;
    debugPrint('Returning phone: $number');
    return number;
  } else {
    debugPrint('Matched contact has no phone number');
    return null;
  }
}
