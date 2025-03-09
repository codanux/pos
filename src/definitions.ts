export interface PosPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
