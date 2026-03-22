import { defineConfig } from 'astro/config';

export default defineConfig({
  // DS components may import from node_modules — allow symlinked paths
  vite: {
    server: {
      fs: {
        allow: ['..'],
      },
    },
  },
});
