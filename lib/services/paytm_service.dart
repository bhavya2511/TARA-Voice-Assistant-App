// lib/services/paytm_service.dart
import 'package:url_launcher/url_launcher.dart';

class PaytmService {
  /// Launch Paytm or a generic UPI payment intent.
  /// recipientNumber is accepted for contact lookups — currently we use a placeholder VPA.
  Future<bool> payTo(String recipientNumber, String amount) async {
    final cleanedAmount = amount.trim();
    if (cleanedAmount.isEmpty) return false;

    // NOTE: Real payments require accurate VPA or UPI handle per contact.
    // Here we demonstrate launching an app with a placeholder VPA. Replace vpa per contact.
    final vpa = 'payee@upi';
    final payeeName = Uri.encodeComponent('Payee');

    // Try Paytm deep link
    try {
      final paytmUri = Uri.parse('paytmmp://pay?pa=$vpa&pn=$payeeName&am=$cleanedAmount&cu=INR');
      if (await canLaunchUrl(paytmUri)) {
        await launchUrl(paytmUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {}

    // Generic UPI
    try {
      final upiUri = Uri.parse('upi://pay?pa=$vpa&pn=$payeeName&am=$cleanedAmount&cu=INR&tn=${Uri.encodeComponent('Payment')}');
      if (await canLaunchUrl(upiUri)) {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {}

    // Play Store fallback: prompt user to install Paytm
    try {
      final playStore = Uri.parse('market://details?id=net.one97.paytm');
      if (await canLaunchUrl(playStore)) {
        await launchUrl(playStore, mode: LaunchMode.externalApplication);
        return true;
      }
      final webPlay = Uri.parse('https://play.google.com/store/apps/details?id=net.one97.paytm');
      if (await canLaunchUrl(webPlay)) {
        await launchUrl(webPlay, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {}

    return false;
  }
}
