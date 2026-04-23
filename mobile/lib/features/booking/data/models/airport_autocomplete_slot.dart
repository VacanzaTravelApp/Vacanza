import 'package:equatable/equatable.dart';

import 'airport_suggestion.dart';

/// Autocomplete UI state for one flight endpoint (origin or destination).
///
/// Kept separate from flight search results loading/error in [BookingCubit].
class AirportAutocompleteSlot extends Equatable {
  final AirportSuggestion? selected;
  final List<AirportSuggestion> suggestions;
  final bool loadingSuggestions;
  final String? suggestionError;

  const AirportAutocompleteSlot({
    this.selected,
    this.suggestions = const [],
    this.loadingSuggestions = false,
    this.suggestionError,
  });

  AirportAutocompleteSlot copyWith({
    AirportSuggestion? selected,
    bool clearSelected = false,
    List<AirportSuggestion>? suggestions,
    bool clearSuggestions = false,
    bool? loadingSuggestions,
    String? suggestionError,
    bool clearSuggestionError = false,
  }) {
    return AirportAutocompleteSlot(
      selected: clearSelected ? null : (selected ?? this.selected),
      suggestions: clearSuggestions ? const [] : (suggestions ?? this.suggestions),
      loadingSuggestions: loadingSuggestions ?? this.loadingSuggestions,
      suggestionError: clearSuggestionError
          ? null
          : (suggestionError ?? this.suggestionError),
    );
  }

  @override
  List<Object?> get props =>
      [selected, suggestions, loadingSuggestions, suggestionError];
}
