import http from "./http";

const asArray = (data) => (Array.isArray(data) ? data : []);

export const aiApi = {
    // Create a new conversation
    createConversation: async () => {
        const response = await http.post('/chat/conversations');
        return response.data;
    },

    // List all conversations for the user
    listConversations: async (limit = 50, offset = 0) => {
        const response = await http.get('/chat/conversations', {
            params: { limit, offset }
        });
        return asArray(response.data);
    },

    // Send a message to a specific conversation
    sendMessage: async (conversationId, content) => {
        const response = await http.post(`/chat/conversations/${conversationId}/messages`, {
            content
        });
        return response.data;
    },

    // Get message history for a specific conversation
    getMessages: async (conversationId, limit = 100, offset = 0) => {
        const response = await http.get(`/chat/conversations/${conversationId}/messages`, {
            params: { limit, offset }
        });
        return asArray(response.data);
    },

    getRoutes: async () => {
        const response = await http.get('/routes');
        return response.data;
    },

    getRoute: async (routeId) => {
        const response = await http.get(`/routes/${routeId}`);
        return response.data;
    },

    /** All routes saved for this conversation (oldest first). */
    getRoutesForConversation: async (conversationId) => {
        try {
            const response = await http.get(`/routes/conversation/${conversationId}`);
            return asArray(response.data);
        } catch {
            return [];
        }
    },

    deleteRoute: async (routeId) => {
        const response = await http.delete(`/routes/${routeId}`);
        return response.data;
    },

    /**
     * Polygon-based itinerary (Task 1). Body: { coordinates, totalDays?, travelStyle?, categories? }
     * coordinates: outer ring [[lon, lat], ...]
     */
    createRouteFromPolygon: async (body) => {
        const response = await http.post('/chat/routes/from-polygon', body);
        return response.data;
    },

    /**
     * Kayıtlı sohbet rotasında tek günü, harita polygon'undaki POI'lara göre yeniden üretir.
     * Body: { conversationId, day, coordinates, travelStyle?, categories? }
     */
    replanDayFromPolygon: async (body) => {
        const response = await http.post('/chat/routes/replan-day-from-polygon', body);
        return response.data;
    },
};

export default aiApi;
