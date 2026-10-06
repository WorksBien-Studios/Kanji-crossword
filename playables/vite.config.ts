import { defineConfig } from 'vite';

// Relative base so the build can be served from any path (YouTube Playables hosts it in a subfolder).
export default defineConfig({
  base: './',
  build: { target: 'es2020', outDir: 'dist', assetsInlineLimit: 0, chunkSizeWarningLimit: 900 },
  test: { include: ['src/**/*.test.ts'] },
});
