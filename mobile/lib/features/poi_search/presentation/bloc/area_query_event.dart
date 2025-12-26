import 'package:equatable/equatable.dart';
import '../../data/models/selected_area.dart';
/// Viewport’tan gelen BBOX güncellemesi.
/// Not: USER_SELECTION aktifse BLoC bunu ignore edecek.
abstract class AreaQueryEvent extends Equatable {
  const AreaQueryEvent();
  @override
  List<Object?> get props => [];
}

class ViewportChanged extends AreaQueryEvent {
  final BboxArea bbox;
  const ViewportChanged(this.bbox);

  @override
  List<Object?> get props => [bbox];
}