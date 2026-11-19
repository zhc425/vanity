import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// 相对路径部署，便于放到 GitHub Pages 或任意子目录
export default defineConfig({
  base: './',
  plugins: [react()],
  build: { modulePreload: { polyfill: false }, assetsInlineLimit: 0 },
  server: { port: 5173, strictPort: true, host: true },
  preview: { host: true }
});
