/* eslint-env node */
import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  // .env dosyasındaki değişkenleri yükle
  // eslint-disable-next-line no-undef
  const env = loadEnv(mode, process.cwd(), '');

  // .env'den gelen URL'i al (Yoksa senin IP'ni fallback olarak kullanır)
  const backendUrl = env.VITE_BACKEND_BASE_URL;

  return {
    plugins: [react()],
    server: {
      host: "0.0.0.0",
      port: 9002,
      proxy: {
        "/auth": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
        },
        "/gamification": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
        },
        "/pois": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
        },
        "/user": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
        },
        "/users": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
        },
        "/bookings": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
        },
        "/chat": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
        },
        "/routes": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
        },
        "/api": {
          target: backendUrl,
          changeOrigin: true,
          secure: false,
          timeout: 60000,
          proxyTimeout: 60000,
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