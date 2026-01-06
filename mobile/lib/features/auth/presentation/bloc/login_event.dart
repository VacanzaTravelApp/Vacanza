import 'package:equatable/equatable.dart';

/// Login ile ilgili tüm event'lerin base sınıfı.
///
/// Şu an sadece:
///  - LoginSubmitted (email + password ile giriş denemesi)
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Kullanıcı "Log In" butonuna bastığında
/// BLoC'e gönderilecek event.
///
/// UI katmanından sadece email ve password geliyor.
/// Gerisini AuthRepository hallediyor.
class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}