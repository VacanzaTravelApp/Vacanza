import { useState, useEffect } from 'react';
import http from '../api/http';

const useFetch = (url) => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const response = await http.get(url);
                setData(response.data);
                setLoading(false);
            } catch (err) {
                setError(err);
                setLoading(false);
            }
        };

        fetchData();
        // Standard 60s polling for admin live dashboard
        const interval = setInterval(fetchData, 60000);

        return () => clearInterval(interval);
    }, [url]);

    return { data, loading, error };
};

export default useFetch;
