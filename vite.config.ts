import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';

// OPENSF: quando servido atrás de um domínio HTTPS (Traefik), o Vite precisa
// permitir o host público e falar HMR por wss na mesma origem. Tudo via env,
// pra não cravar o domínio no código (mantém o fork limpo p/ rebase).
const publicHost =
  process.env.VITE_RUBY_HTTPS === 'true' && process.env.VITE_RUBY_HOST
    ? process.env.VITE_RUBY_HOST
    : null;

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
