/* eslint-env node */
import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  // .env dosyasındaki değişkenleri yükle
  // eslint-disable-next-line no-undef
  const env = loadEnv(mode, process.cwd(), '');

  // .env'den gelen URL'i al (Yoksa senin IP'ni fallback olarak kullanır)
  const backendUrl = env.VITE_BACKEND_BASE_URL || 'http://localhost:8080';

  return {
    plugins: [react()],
    server: {
      host: "0.0.0.0",
      port: 9003,
      proxy: {
        "/auth": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
        },
        "/gamification": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
        },
        "/pois": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
        },
        "/user": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
        },
        "/users": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
        },
        "/bookings": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
        },
        "/chat": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
        },
        "/admin": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          ws: true,
          configure: (proxy, _options) => {
            proxy.on('error', (err, _req, _res) => {
              console.log('proxy error', err);
            });
            proxy.on('proxyReq', (proxyReq, req, _res) => {
              console.log('Sending Request to the Target:', req.method, req.url);
            });
            proxy.on('proxyRes', (proxyRes, req, _res) => {
              console.log('Received Response from the Target:', proxyRes.statusCode, req.url);
            });
          },
        },
      },
    },
    optimizeDeps: {
      include: ["mapbox-gl"],
    },
    resolve: {
      alias: {
        "mapbox-gl": "mapbox-gl/dist/mapbox-gl.js",
      },
    },
    define: {
      "process.env": {},
    },
  };
});
