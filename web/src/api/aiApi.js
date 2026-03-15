import http from "./http";

export const aiApi = {
    // Create a new conversation
    createConversation: async () => {
        const response = await http.post('/chat/conversations');
        return response.data;
    },

    // List all conversations for the user
    listConversations: async (limit = 10, offset = 0) => {
        const response = await http.get('/chat/conversations', {
            params: { limit, offset }
        });
        return response.data;
    },

    // Send a message to a specific conversation
    sendMessage: async (conversationId, content) => {
        const response = await http.post(`/chat/conversations/${conversationId}/messages`, {
            content
        });
        return response.data;
    },

    // Get message history for a specific conversation
    getMessages: async (conversationId, limit = 50, offset = 0) => {
        const response = await http.get(`/chat/conversations/${conversationId}/messages`, {
            params: { limit, offset }
        });
        return response.data;
    },

    getRoutes: async () => {
        const response = await http.get('/routes');
        return response.data;
    },

    getRoute: async (routeId) => {
        const response = await http.get(`/routes/${routeId}`);
        return response.data;
    },

    deleteRoute: async (routeId) => {
        const response = await http.delete(`/routes/${routeId}`);
        return response.data;
    }
};

export default aiApi;
