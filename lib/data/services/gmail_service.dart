import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class GmailService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      AppConstants.gmailSendScope,
    ],
  );

  static GoogleSignInAccount? _currentUser;

  static GoogleSignInAccount? get currentUser => _currentUser;
  static bool get isConnected => _currentUser != null;

  static Future<GoogleSignInAccount?> signInWithGmail() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  static Future<bool> sendEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String htmlBody,
    required String plainText,
    required String fromName,
    String? replyTo,
    String? listId,
    String? contactId,
  }) async {
    if (_currentUser == null) return false;

    try {
      final auth = await _currentUser!.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) return false;

      // Build unsubscribe URL
      final unsubscribeUrl =
          '${AppConstants.unsubscribeFunctionUrl}?uid=${_currentUser!.id}&listId=$listId&contactId=$contactId';

      // Build the raw email with proper headers
      final fromEmail = _currentUser!.email;
      final rawEmail = _buildRawEmail(
        from: '"$fromName" <$fromEmail>',
        to: '"$toName" <$toEmail>',
        subject: subject,
        htmlBody: htmlBody,
        plainText: plainText,
        replyTo: replyTo,
        unsubscribeUrl: unsubscribeUrl,
      );

      final encodedEmail = base64Url
          .encode(utf8.encode(rawEmail))
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll('=', '');

      final response = await http.post(
        Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages/send'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'raw': encodedEmail}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static String _buildRawEmail({
    required String from,
    required String to,
    required String subject,
    required String htmlBody,
    required String plainText,
    String? replyTo,
    String? unsubscribeUrl,
  }) {
    final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';
    final buffer = StringBuffer();

    buffer.writeln('From: $from');
    buffer.writeln('To: $to');
    buffer.writeln('Subject: $subject');
    buffer.writeln('MIME-Version: 1.0');
    buffer.writeln('Content-Type: multipart/alternative; boundary="$boundary"');
    if (replyTo != null) buffer.writeln('Reply-To: $replyTo');
    if (unsubscribeUrl != null) {
      buffer.writeln('List-Unsubscribe: <$unsubscribeUrl>');
      buffer.writeln('List-Unsubscribe-Post: List-Unsubscribe=One-Click');
    }
    buffer.writeln('');
    buffer.writeln('--$boundary');
    buffer.writeln('Content-Type: text/plain; charset="UTF-8"');
    buffer.writeln('');
    buffer.writeln(plainText);
    buffer.writeln('');
    buffer.writeln('--$boundary');
    buffer.writeln('Content-Type: text/html; charset="UTF-8"');
    buffer.writeln('');
    buffer.writeln(htmlBody);
    buffer.writeln('');
    buffer.writeln('--$boundary--');

    return buffer.toString();
  }

  // Personalize email body by replacing merge tags
  static String personalize(
    String template,
    Map<String, String> fields,
  ) {
    String result = template;
    fields.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }
}
