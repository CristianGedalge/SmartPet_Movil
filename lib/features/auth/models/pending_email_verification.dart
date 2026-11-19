import '../../../shared/models/json_values.dart';

class PendingEmailVerification {
  const PendingEmailVerification({
    required this.email,
    required this.maskedEmail,
    required this.emailSent,
  });

  final String email;
  final String maskedEmail;
  final bool emailSent;

  factory PendingEmailVerification.fromJson(Map<String, dynamic> json) =>
      PendingEmailVerification(
        email: requiredString(json, 'email'),
        maskedEmail: requiredString(json, 'emailEnmascarado'),
        emailSent: json['correoEnviado'] == true,
      );
}
