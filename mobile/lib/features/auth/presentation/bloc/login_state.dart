import 'package:equatable/equatable.dart';

/// Login ekranının durumunu temsil eden status enum'u.
///
/// UI bu enum'a bakarak:
///  - butonu enable/disable eder
///  - loading spinner gösterir
///  - hata veya başarı senaryolarına göre tepki verir.
enum LoginStatus {
  initial,    // Ekran açıldığında / idle
  submitting, // Şu anda login isteği atılıyor
  success,    // Login başarıyla tamamlandı
  failure,    // Login sırasında hata oluştu
}

class LoginState extends Equatable {
  final LoginStatus status;

  /// Firebase ve/veya backend'ten gelen hata mesajı.
  /// initial / success / submitting durumunda genelde null olur.
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
  });

  /// State'in bir kısmını güncellemek için copyWith kullanıyoruz.
  /// Immutable state pattern'ine uygun.
  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  bool get isSubmitting => status == LoginStatus.submitting;
  bool get isSuccess => status == LoginStatus.success;
  bool get isFailure => status == LoginStatus.failure;

  @override
  List<Object?> get props => [status, errorMessage];
}