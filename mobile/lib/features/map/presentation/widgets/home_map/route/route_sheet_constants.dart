/// Default expanded height (must match [DraggableRouteBottomSheet] initialChildSize).
const double kRouteSheetExpandedExtent = 0.54;

/// After flying to a stop/event on the map, collapse the draggable sheet to this
/// fraction of the screen so the POI stays visible above the panel while keeping
/// handle + title + Plan/Events bar from clipping mid-control.
const double kRouteSheetPeekExtent = 0.27;

/// Sheet extent at or below this is treated as "peek" for tap-to-expand and mini pill.
const double kRouteSheetPeekInteractionThreshold = 0.34;
