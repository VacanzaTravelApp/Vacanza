export const initialState = {
  bookingType: "hotels",
  loading: false,
  error: null,
  items: [],
  searchParams: {
    destination: "", 
    dates: "",       
    adults: 1,       
    budget: "",
    sortBy: "PRICE_ASC"
  }
};

export function bookingReducer(state, action) {
  switch (action.type) {
    case "SET_TYPE":
      return { ...state, bookingType: action.payload, items: [] };
    case "UPDATE_PARAM":
      return { ...state, searchParams: { ...state.searchParams, ...action.payload } };
    case "SEARCH_START":
      return { ...state, loading: true, error: null };
    case "SEARCH_SUCCESS":
      return { ...state, loading: false, items: action.payload };
    case "SEARCH_ERROR":
      return { ...state, loading: false, error: action.payload };
    default:
      return state;
  }
}