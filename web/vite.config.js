// vite.config.js (CSS hatasını da çözen versiyon)

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  
  // 🔥 KRİTİK AYARLAR:
  optimizeDeps: {
    exclude: ['react-map-gl', 'mapbox-gl'],
  },

  resolve: {
    alias: {
      'mapbox-gl': 'mapbox-gl/dist/mapbox-gl.js',
      // CSS dosyasını manuel olarak node_modules içindeki yerine yönlendirir.
      // Not: 'path' modülünün yüklenmesi gerekir.
      // 'mapbox-gl/dist/mapbox-gl.css': path.resolve(__dirname, 'node_modules/mapbox-gl/dist/mapbox-gl.css') 
    },
  },
  
  define: {
    'process.env': {} 
  }
});