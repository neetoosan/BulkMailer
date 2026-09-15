class AppConstants {
  static const String appName = 'BulkMailer';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String listsCollection = 'lists';
  static const String subscribersCollection = 'subscribers';
  static const String campaignsCollection = 'campaigns';
  static const String templatesCollection = 'templates';
  static const String emailJobsCollection = 'email_jobs';

  // Gmail API
  static const String gmailSendScope = 'https://www.googleapis.com/auth/gmail.send';
  static const String gmailReadScope = 'https://www.googleapis.com/auth/gmail.readonly';

  // Sending limits
  static const int maxEmailsPerMinute = 10;
  static const int maxEmailsPerDay = 500;

  // Merge tags
  static const List<String> mergeTags = [
    '{{first_name}}',
    '{{last_name}}',
    '{{email}}',
    '{{full_name}}',
  ];

  // Unsubscribe
  static const String unsubscribeFunctionUrl =
      'https://us-central1-flix-mailer.cloudfunctions.net/handleUnsubscribe';
}
