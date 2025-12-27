import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';

/// Login ekranının iş mantığını yöneten BLoC.
///
/// SORUMLULUK:
///  - UI'dan gelen LoginSubmitted event'ini dinler
///  - AuthRepository üzerinden login akışını tetikler
///  - LoginState üretir (submitting / success / failure)
///
/// DİKKAT:
///  - Firebase + backend detayları BLoC içinde yok.
///    Tüm IO işleri AuthRepository'de.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const LoginState()) {
    // Sadece LoginSubmitted event'ini handle ediyoruz.
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  /// LoginSubmitted geldiğinde çalışacak handler.
  ///
  /// 1) State'i submitting'e çek
  /// 2) AuthRepository.loginWithEmailAndPassword çağır
  /// 3) Başarılıysa success, hata varsa failure emit et
  Future<void> _onLoginSubmitted(
      LoginSubmitted event,
      Emitter<LoginState> emit,
      ) async {
    // 1) Loading state
    emit(
      state.copyWith(
        status: LoginStatus.submitting,
        errorMessage: null,
      ),
    );

    try {
      // 2) Auth katmanına login isteğini ilet
      await _authRepository.loginWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // 3) Her şey yolundaysa success state
      emit(
        state.copyWith(
          status: LoginStatus.success,
          errorMessage: null,
        ),
      );
    } on AuthFailure catch (e) {
      // Beklediğimiz (kontrollü) AuthFailure tipindeki hatalar:
      //  - Firebase user-not-found, wrong-password vs.
      //  - Backend 401/403 vs.
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      // Beklenmeyen bir exception olursa generic mesaj dön.
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Giriş sırasında beklenmeyen bir hata oluştu.',
        ),
      );
    }
  }
}