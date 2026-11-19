import 'package:firebase_core/firebase_core.dart';

class FirebasePublicConfig {
  const FirebasePublicConfig._({this.options});

  factory FirebasePublicConfig.fromEnvironment() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

    if ([apiKey, appId, senderId, projectId].any((value) => value.isEmpty)) {
      return const FirebasePublicConfig._();
    }
    return FirebasePublicConfig._(
      options: const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
      ),
    );
  }

  final FirebaseOptions? options;
  bool get enabled => options != null;
}
