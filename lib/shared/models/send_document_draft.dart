/// What the user typed in the Send Estimate / Send Invoice sheet.
/// Mirrors `SendEstimateEmailRequest` / `SendInvoiceEmailRequest`.
class SendDocumentDraft {
  final String toEmail;
  final String subject;
  final String message;
  final bool sendMeACopy;

  const SendDocumentDraft({
    required this.toEmail,
    required this.subject,
    required this.message,
    required this.sendMeACopy,
  });

  Map<String, dynamic> toJson() => {
        'toEmail': toEmail,
        'subject': subject,
        'message': message,
        'sendMeACopy': sendMeACopy,
      };
}
