import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import netlify from '@astrojs/netlify';

export default defineConfig({
  integrations: [tailwind()],
  output: 'server',
  adapter: netlify({
    edgeMiddleware: true // Enable edge middleware for better performance
  }),
  vite: {
    ssr: {
      noExternal: ['@astrojs/netlify']
    }
  }
});