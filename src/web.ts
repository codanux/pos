import { WebPlugin } from '@capacitor/core';

import type { PosPlugin } from './definitions';

export class PosWeb extends WebPlugin implements PosPlugin {
  async send(options: { ip: string, port: number, data: any }): Promise<void> {
    console.log('ECHO', options);
  }

  async scan(options: { ip: string, port: number }): Promise<any> {
    console.log('ECHO', options);
    return options;
  }
}
