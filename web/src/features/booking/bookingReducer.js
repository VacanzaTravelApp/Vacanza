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
    isRoundTrip: false
  }
};

export function bookingReducer(state, action) {
  switch (action.type) {
    case "UPDATE_PARAM":
      // Eğer payload doğrudan sortBy içeriyorsa state'in köküne yazar
      // Diğer her şeyi searchParams içine güvenli bir şekilde merge eder
      return { 
        ...state, 
        sortBy: action.payload.sortBy !== undefined ? action.payload.sortBy : state.sortBy,
        bookingType: action.payload.bookingType || state.bookingType,
        searchParams: { 
          ...state.searchParams, 
          ...action.payload 
        }
      };
    case "SEARCH_START":
      return { ...state, loading: true };
    case "SEARCH_SUCCESS":
      return { ...state, loading: false, items: action.payload, view: 'results' };
    case "SEARCH_ERROR":
      return { ...state, loading: false };
    case "RETRY":
      return { ...state, view: 'search', items: [], sortBy: 'low' };
    case "RESET_STATE":
      return initialState;
    default:
      return state;
  }
}