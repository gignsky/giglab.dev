import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

// Reads projects/ at the repo root; shape is provisional (projects/README.md, ARCHITECTURE.md §7 item 5).
const projects = defineCollection({
  loader: glob({ pattern: '*.json', base: '../projects' }),
  schema: z.object({
    code: z.string().regex(/^[A-Z]{2}-\d{2}$/, 'code must look like GP-01'),
    title: z.string(),
    summary: z.string().max(90, 'summary must be at most 90 characters'),
    status: z.enum(['idea', 'planned', 'active', 'paused', 'shipped', 'archived']),
    repo: z.string().optional(),
    visibility: z.enum(['public', 'private']).default('public'),
    tags: z.array(z.string()).optional(),
    started: z.string().optional(),
    target: z.string().optional(),
    links: z.record(z.string(), z.string()).optional(),
  }),
});

export const collections = { projects };
