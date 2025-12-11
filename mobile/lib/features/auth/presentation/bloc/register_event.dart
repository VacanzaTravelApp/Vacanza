import 'package:equatable/equatable.dart';

/// Tüm register eventlerinin base sınıfı.
/// Şimdilik tek eventimiz var: RegisterSubmitted
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