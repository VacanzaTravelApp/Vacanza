import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: "0.0.0.0",
    port: 9002,
    proxy: {
      "/auth": {
        target: "http://165.232.69.83:9002",
        changeOrigin: true,
        secure: false,
      },
      "/pois": {
        target: "http://165.232.69.83:9002",
        changeOrigin: true,
        secure: false,
      },
      "/gamification": {
        target: "http://165.232.69.83:9002",
        changeOrigin: true,
        secure: false,
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
});
