import 'package:equatable/equatable.dart';

/// Tüm register event'lerinin base sınıfı.
///
/// Şu anda 2 eventimiz var:
///  - RegisterSubmitted: kullanıcı "Sign Up" butonuna bastığında gelir.
///  - RegisterReset: success/failure sonrası state'i tekrar initial'e almak için kullanılır.
abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

/// Kullanıcı "Sign Up" butonuna bastığında
/// BLoC'e gönderilecek event.
///
/// UI'dan gelen tüm gerekli alanları taşıyoruz.
class RegisterSubmitted extends RegisterEvent {
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String password;

  /// Birden fazla preferred name olabileceği için liste tutuyoruz.
  /// Örn: ["Ahmet"], ["Serhat"], ["Ahmet", "Serhat"]
  final List<String> preferredNames;

  const RegisterSubmitted({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.preferredNames,
  });

  @override
  List<Object?> get props => [
    firstName,
    middleName,
    lastName,
    email,
    password,
    preferredNames,
  ];
}

/// Success/failure gibi senaryolardan sonra
/// RegisterState'i tekrar "sıfırlamak" için kullanılan event.
///
/// VACANZA-82 notu:
///   "Success state sadece bir kere consume edilmeli; tekrar rebuild'lerde
///    snackbar tekrar tetiklenmemeli"
///
/// Bunu sağlamak için:
///   - success alındıktan sonra UI tarafı RegisterReset event'ini atar
///   - BLoC bu eventi yakalayıp state'i tekrar initial'e çeker
///   - Böylece listener success -> initial geçişinde sadece 1 kez çalışır.
class RegisterReset extends RegisterEvent {
  const RegisterReset();

  @override
  List<Object?> get props => [];
}