import http from "./http";

export const currencyApi = {
    /**
     * Convert single currency
     * GET /api/v1/currencies/convert?amount=100&fromCurrency=USD&toCurrency=EUR
     */
    convert: async (amount, fromCurrency, toCurrency) => {
        try {
            const response = await http.get("/api/v1/currencies/convert", {
                params: {
                    amount,
                    fromCurrency: fromCurrency.toUpperCase(),
                    toCurrency: toCurrency.toUpperCase()
                }
            });
            return response.data;
        } catch (error) {
            handleCurrencyError(error);
            throw error;
        }
    },

    /**
     * Batch Cost Forecasting
     * POST /api/v1/currencies/forecast
     */
    forecast: async (targetCurrency, items) => {
        try {
            const response = await http.post("/api/v1/currencies/forecast", {
                targetCurrency: targetCurrency.toUpperCase(),
                items: items.map(item => ({
                    ...item,
                    currency: item.currency.toUpperCase()
                }))
            });
            return response.data;
        } catch (error) {
            handleCurrencyError(error);
            throw error;
        }
    }
};

function handleCurrencyError(error) {
    if (error.response) {
        const { status, data } = error.response;
        if (status === 503) {
            // Service Unavailable - external provider down
            console.warn("Currency service is temporarily unavailable. Using fallback or original prices.");
        } else if (status === 400) {
            console.error("Invalid currency data:", data.message);
        }
    }
}
