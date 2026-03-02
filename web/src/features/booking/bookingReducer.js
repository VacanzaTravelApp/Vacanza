export const initialState = {
  bookingType: "hotels", // 'hotels' veya 'flights'
  view: "search",        // 'search' (form) veya 'results' (liste)
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
      // Tip değişince sonuçları temizle ve arama moduna dön
      return { ...state, bookingType: action.payload, items: [], view: "search" };
      
    case "UPDATE_PARAM":
      return { ...state, searchParams: { ...state.searchParams, ...action.payload } };
      
    case "SEARCH_START":
      return { ...state, loading: true, error: null };
      
    case "SEARCH_SUCCESS":
      // Sonuç gelince otomatik olarak 'results' görünümüne geç
      return { 
        ...state, 
        loading: false, 
        items: action.payload, 
        view: action.payload.length > 0 ? "results" : "search",
        error: action.payload.length === 0 ? "Hiç sonuç bulunamadı." : null 
      };
      
    case "SEARCH_ERROR":
      return { ...state, loading: false, error: action.payload, view: "search" };

    case "RETRY":
      // Sonuçlardan tekrar arama formuna dönmek için
      return { ...state, view: "search", items: [] };
      // bookingReducer.js içinde switch-case kısmına:
case "RESET_STATE":
  return initialState;

    default:
      return state;
  }
}