export interface PosPlugin {
  send(options: { ip: string, port: number, data: string }): void;
  scan(options: { ip: string, port: number }): Promise<any>;
}
