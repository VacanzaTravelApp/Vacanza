import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_event.dart';
import 'register_state.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';

/// Register ekranının iş mantığını yöneten BLoC.
/// - Event alır (RegisterSubmitted)
/// - AuthRepository ile konuşur (Firebase + ileride backend)
/// - State üretir (loading, success, failure)
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const RegisterState()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  /// Kullanıcı "Sign Up" butonuna bastığında gelen event'i işler.
  Future<void> _onRegisterSubmitted(
      RegisterSubmitted event,
      Emitter<RegisterState> emit,
      ) async {
    // 1) Önce UI'ya "loading" gösterelim
    emit(
      state.copyWith(
        status: RegisterStatus.submitting,
        errorMessage: null,
      ),
    );

    try {
      // 2) AuthRepository üzerinden Firebase register işlemini çağır.
      //    Backend call şu an repository içinde comment'li durumda.
      // ŞU AN: Sadece email + password ile Firebase'e kayıt.
      // İLERİDE: event.firstName, event.middleName, event.lastName,
      //          event.preferredNames backend'e gönderilecek.
      await _authRepository.registerWithEmailAndPassword(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        middleName: event.middleName.isEmpty ? null : event.middleName,
        lastName: event.lastName,
        preferredNames: event.preferredNames,
      );

      // 3) İşlem başarılı → success state'e geç
      //    VACANZA-82'de bu state'i dinleyip snackbar + navigation yapacağız.
      emit(
        state.copyWith(
          status: RegisterStatus.success,
          errorMessage: null,
        ),
      );
    } on AuthFailure catch (e) {
      // AuthRepository içinden gelen bilinen hatalar (Firebase / backend).
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      // Beklenmeyen bir şey olursa kullanıcıya genel bir mesaj göster.
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Kayıt sırasında beklenmeyen bir hata oluştu.',
        ),
      );
    }
  }
}