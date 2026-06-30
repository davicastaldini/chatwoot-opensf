import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';

// OPENSF: quando servido atrás de um domínio HTTPS (Traefik), o Vite precisa
// permitir o host público e falar HMR por wss na mesma origem.
// Usa OPENSF_PUBLIC_HOST (não VITE_RUBY_HOST) pra não interferir com o binding
// interno do vite-ruby, que deve ficar em 0.0.0.0:3036.
const publicHost = process.env.OPENSF_PUBLIC_HOST || null;

export default defineConfig({
  plugins: [ruby(), vue(vueOptions), yaml()],
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
      },
    },
  },
  resolve: { alias: aliases },
  ...(publicHost
    ? {
        server: {
          host: '0.0.0.0',
          allowedHosts: [publicHost],
          hmr: { host: publicHost, protocol: 'wss', clientPort: 443 },
        },
      }
    : {}),
});
