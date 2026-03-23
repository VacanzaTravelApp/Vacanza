export const initialState = {
  bookingType: 'hotels',
  view: 'search',
  loading: false,
  items: [],
  sortBy: 'low',
  searchParams: {
    origin: '',
    destination: '',
    dates: '',
    checkOutDate: '',
    adults: 1,
    budget: '',
    isRoundTrip: false,
    travelClass: 'ECONOMY'
  },
  errors: {},
  generalError: null
};

export function bookingReducer(state, action) {
  switch (action.type) {
    case "UPDATE_PARAM":
      // If it's a pure tab switch (only bookingType in payload), reset the form.
      // If there are other params (like origin/destination), don't reset.
      const isPureTypeSwitch = action.payload.bookingType &&
        Object.keys(action.payload).length === 1 &&
        action.payload.bookingType !== state.bookingType;

      if (isPureTypeSwitch) {
        return {
          ...state,
          bookingType: action.payload.bookingType,
          searchParams: { ...initialState.searchParams },
          errors: {}
        };
      }

      // Clear error for the field being updated
      const newErrors = { ...state.errors };
      Object.keys(action.payload).forEach(key => {
        delete newErrors[key];
        if (key === 'dates') delete newErrors['dates'];
        if (key === 'origin') delete newErrors['origin'];
        if (key === 'destination') delete newErrors['destination'];
      });

      return {
        ...state,
        generalError: null,
        sortBy: action.payload.sortBy !== undefined ? action.payload.sortBy : state.sortBy,
        bookingType: action.payload.bookingType || state.bookingType,
        searchParams: {
          ...state.searchParams,
          ...action.payload
        },
        errors: newErrors
      };
    case "SET_ERRORS":
      return { ...state, errors: action.payload };
    case "SEARCH_START":
      return { ...state, loading: true };
    case "SEARCH_SUCCESS":
      return { ...state, loading: false, items: action.payload, view: 'results' };
    case "SEARCH_ERROR":
      return { ...state, loading: false, generalError: action.payload || "Search failed." };
    case "RETRY":
      return { ...state, view: 'search', items: [], sortBy: 'low' };
    case "RESET_STATE":
      return initialState;
    default:
      return state;
  }
}