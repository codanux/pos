import { WebPlugin } from '@capacitor/core';

import type { PosPlugin } from './definitions';

export class PosWeb extends WebPlugin implements PosPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
