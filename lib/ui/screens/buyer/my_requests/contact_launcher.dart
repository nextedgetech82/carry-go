import 'package:url_launcher/url_launcher.dart';

class ContactLauncher {
  /// 📞 CALL
  static Future<void> call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch call';
    }
  }

  /// 💬 WHATSAPP
  static Future<void> whatsapp(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$phone?text=$encoded');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'WhatsApp not installed';
    }
  }
}
