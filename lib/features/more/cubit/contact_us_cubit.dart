import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/contact_us_repository.dart';

part 'contact_us_state.dart';

class ContactUsCubit extends Cubit<ContactUsState> {
  final ContactUsRepository _repository;

  ContactUsCubit({required ContactUsRepository repository})
      : _repository = repository,
        super(const ContactUsIdle());

  Future<void> submit({
    required String name,
    String? company,
    required String email,
    required String phone,
    required String subject,
    String? description,
    required String turnstileToken,
  }) async {
    emit(const ContactUsSubmitting());
    final result = await _repository.submit(
      name: name,
      company: company,
      email: email,
      phone: phone,
      subject: subject,
      description: description,
      turnstileToken: turnstileToken,
    );
    result.fold(
      (failure) => emit(ContactUsFailure(failure.message)),
      (_) => emit(const ContactUsSuccess()),
    );
  }
}
