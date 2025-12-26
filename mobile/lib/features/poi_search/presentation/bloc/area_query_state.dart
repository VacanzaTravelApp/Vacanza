import 'package:equatable/equatable.dart';
import '../../data/models/area_query_context.dart';

class AreaQueryState extends Equatable {
  final AreaQueryContext context;

  const AreaQueryState({required this.context});

  factory AreaQueryState.initial() => AreaQueryState(
    context: AreaQueryContext.initial(),
  );

  @override
  List<Object?> get props => [context];
}