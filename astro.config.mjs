import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import netlify from '@astrojs/netlify';

export default defineConfig({
  integrations: [tailwind()],
  output: 'static',
  adapter: netlify({
    edgeMiddleware: false // Enable edge middleware for better performance
  }),
  vite: {
    ssr: {
      noExternal: []
    }
  }
});