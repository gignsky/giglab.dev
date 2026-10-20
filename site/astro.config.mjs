// @ts-check
import { defineConfig } from 'astro/config';

// Static output, no SSR adapter -- the Rust server (Phase 2) owns everything
// dynamic (docs/ARCHITECTURE.md §3.1).
export default defineConfig({
  site: 'https://giglab.dev',
});
