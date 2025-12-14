import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  optimizeDeps: {
    include: ['mapbox-gl'], // exclude yerine include kullanın
  },
  resolve: {
    alias: {
      'mapbox-gl': 'mapbox-gl/dist/mapbox-gl.js',
    },
  },
  define: {
    'process.env': {} 
  }
});