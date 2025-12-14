import 'package:equatable/equatable.dart';

/// Register ekranının anlık durumunu temsil eden status enum'u.
/// UI bu enum'a bakarak:
/// - butonu disable/enable eder
/// - loading gösterir
/// - hata veya success durumunu bilir.
enum RegisterStatus {
  initial,    // ilk açılış / idle
  submitting, // şu an register isteği gönderiliyor
  success,    // register başarılı
  failure,    // register sırasında hata oldu
}

class RegisterState extends Equatable {
  final RegisterStatus status;

  /// Firebase / backend / bilinmeyen hatalar için gösterilecek mesaj.
  /// success ve initial durumunda null olur.
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  /// copyWith ile state'in sadece değişen kısımlarını güncelliyoruz.
  RegisterState copyWith({
    RegisterStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  bool get isSubmitting => status == RegisterStatus.submitting;
  bool get isSuccess => status == RegisterStatus.success;
  bool get isFailure => status == RegisterStatus.failure;

  @override
  List<Object?> get props => [status, errorMessage];
}