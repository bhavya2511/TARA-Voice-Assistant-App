import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

Future<void> openPaytm() async {
  const String paytmApp = "paytm://";
  const String playStore = "https://play.google.com/store/apps/details?id=net.one97.paytm";
  if (!await launchUrl(Uri.parse(paytmApp), mode: LaunchMode.externalApplication)) {
    debugPrint('Paytm app not found, opening Play Store.');
    await launchUrl(Uri.parse(playStore), mode: LaunchMode.externalApplication);
  } else {
    debugPrint('Paytm opened successfully.');
  }
}
