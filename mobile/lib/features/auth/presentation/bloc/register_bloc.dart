import 'package:flutter_bloc/flutter_bloc.dart';

import 'register_event.dart';
import 'register_state.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';

/// Register ekranının iş mantığını yöneten BLoC.
///
/// Sorumlulukları:
///  - UI'dan gelen RegisterSubmitted event'ini dinler
///  - AuthRepository üzerinden Firebase + (ileride) backend register çağrısı yapar
///  - Progress/hata/basarili durumlarına göre RegisterState üretir
///
/// VACANZA-81:
///  - Firebase createUserWithEmailAndPassword entegrasyonu
/// VACANZA-82:
///  - Success state'in UI tarafından dinlenip,
///    snackbar + navigation yapılmasını sağlamak.
///  - RegisterReset event'i ile state'in tekrar initial'e alınması.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const RegisterState()) {
    // Kullanıcı "Sign Up" butonuna bastığında gelen event.
    on<RegisterSubmitted>(_onRegisterSubmitted);

    // UI'dan success/failure sonrası state'i sıfırlamak için gelen event.
    on<RegisterReset>(_onRegisterReset);
  }

  /// RegisterSubmitted event handler:
  ///
  /// Akış:
  ///  1) state → submitting
  ///  2) AuthRepository.registerWithEmailAndPassword çağrılır
  ///  3) Başarılı olursa state → success
  ///  4) AuthFailure (Firebase/backend) gelirse state → failure + errorMessage
  ///  5) Diğer beklenmeyen hatalarda generic failure mesajı verilir
  Future<void> _onRegisterSubmitted(
      RegisterSubmitted event,
      Emitter<RegisterState> emit,
      ) async {
    // 1) Önce UI'ya "loading" gösterelim.
    emit(
      state.copyWith(
        status: RegisterStatus.submitting,
        errorMessage: null,
      ),
    );

    try {
      // 2) AuthRepository üzerinden Firebase register işlemini çağır.
      //
      //    Şu an:
      //      - Firebase createUserWithEmailAndPassword
      //      - UID + idToken alma
      //      - Backend çağrısı (Dio) şimdilik comment'li
      //
      //    İleride:
      //      - backend /auth/register endpoint'i aktif olunca
      //        aynı method içinde token ile backend'e de gidecek.
      await _authRepository.registerWithEmailAndPassword(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        middleName: event.middleName.isEmpty ? null : event.middleName,
        lastName: event.lastName,

        // ✅ Backend: preferredName tek string bekliyor
        preferredName: event.preferredNames.isEmpty ? null : event.preferredNames.first,
      );

      // 3) İşlem başarılı → success state'e geç.
      //
      // VACANZA-82:
      //   Bu success state UI'da BlocListener tarafından dinlenecek:
      //     - snackbar gösterilecek
      //     - MapScreen'e navigasyon yapılacak
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

  /// RegisterReset event handler:
  ///
  /// Amaç:
  ///  - VACANZA-82'deki "success state sadece bir kere consume edilmeli"
  ///    gereksinimini karşılamak.
  ///
  /// Kullanım:
  ///  - UI, success durumunu yakalayıp snackbar + navigation yaptıktan hemen sonra
  ///    RegisterReset event'ini dispatch eder.
  ///  - Bu handler da state'i tekrar initial'e çeker.
  ///
  /// Sonuç:
  ///  - Listener success → initial geçişini bir kez görür.
  ///  - Aynı success state tekrar tetiklenmez, snackbar/nav yeniden çalışmaz.
  void _onRegisterReset(
      RegisterReset event,
      Emitter<RegisterState> emit,
      ) {
    emit(
      const RegisterState(
        status: RegisterStatus.initial,
        errorMessage: null,
      ),
    );
  }
}