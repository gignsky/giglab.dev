// Status -> tile/readout treatment (docs/design/landing-annunciator.md, "Tile anatomy").
export type ProjectStatus = 'idea' | 'planned' | 'active' | 'paused' | 'shipped' | 'archived';

interface StatusStyle {
  glyph: string;
  word: string;
  bg: string;
  fg: string;
  border: string;
}

export const STATUS_STYLES: Record<Exclude<ProjectStatus, 'archived'>, StatusStyle> = {
  active: { glyph: '◆', word: 'IN FLIGHT', bg: 'var(--beacon)', fg: 'var(--on-signal)', border: 'var(--beacon)' },
  paused: { glyph: '▲', word: 'PAUSED', bg: 'var(--signal)', fg: 'var(--on-signal)', border: 'var(--signal)' },
  shipped: { glyph: '●', word: 'DOCKED', bg: 'var(--ok)', fg: 'var(--on-signal)', border: 'var(--ok)' },
  planned: { glyph: '○', word: 'CHARTED', bg: 'var(--panel)', fg: 'var(--ink)', border: 'var(--muted)' },
  idea: { glyph: '○', word: 'CHARTED', bg: 'var(--panel)', fg: 'var(--ink)', border: 'var(--muted)' },
};

export function statusStyle(status: ProjectStatus): StatusStyle {
  if (status === 'archived') {
    throw new Error('archived projects have no board treatment');
  }
  return STATUS_STYLES[status];
}

// Board order: the ordinal in `code` (GP-01 -> 1); the loader doesn't guarantee file order.
export function codeOrdinal(code: string): number {
  const match = code.match(/(\d+)$/);
  return match ? Number.parseInt(match[1], 10) : Number.MAX_SAFE_INTEGER;
}
