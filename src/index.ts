import { registerPlugin } from '@capacitor/core';

import type { PosPlugin } from './definitions';

const Pos = registerPlugin<PosPlugin>('Pos', {
  web: () => import('./web').then((m) => new m.PosWeb()),
});

export * from './definitions';
export { Pos };
