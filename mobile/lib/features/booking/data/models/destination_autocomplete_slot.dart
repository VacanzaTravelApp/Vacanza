import 'package:equatable/equatable.dart';

import 'destination_suggestion.dart';

/// Autocomplete state for hotel destination (separate from hotel search results).
class DestinationAutocompleteSlot extends Equatable {
  final DestinationSuggestion? selected;
  final List<DestinationSuggestion> suggestions;
  final bool loadingSuggestions;
  final String? suggestionError;

  const DestinationAutocompleteSlot({
    this.selected,
    this.suggestions = const [],
    this.loadingSuggestions = false,
    this.suggestionError,
  });

  DestinationAutocompleteSlot copyWith({
    DestinationSuggestion? selected,
    bool clearSelected = false,
    List<DestinationSuggestion>? suggestions,
    bool clearSuggestions = false,
    bool? loadingSuggestions,
    String? suggestionError,
    bool clearSuggestionError = false,
  }) {
    return DestinationAutocompleteSlot(
      selected: clearSelected ? null : (selected ?? this.selected),
      suggestions:
          clearSuggestions ? const [] : (suggestions ?? this.suggestions),
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
