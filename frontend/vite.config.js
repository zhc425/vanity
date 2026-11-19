import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  build: { modulePreload: { polyfill: false } },
  server: { port: 5173, strictPort: true, allowedHosts: ['cd66-210-44-10-39.ngrok-free.app'] },
  preview: { allowedHosts: ['cd66-210-44-10-39.ngrok-free.app'] }
});