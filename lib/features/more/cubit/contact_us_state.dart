part of 'contact_us_cubit.dart';

sealed class ContactUsState {
  const ContactUsState();
}

final class ContactUsIdle extends ContactUsState {
  const ContactUsIdle();
}

final class ContactUsSubmitting extends ContactUsState {
  const ContactUsSubmitting();
}

final class ContactUsSuccess extends ContactUsState {
  const ContactUsSuccess();
}

final class ContactUsFailure extends ContactUsState {
  final String message;
  const ContactUsFailure(this.message);
}
