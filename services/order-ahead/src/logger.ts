type Level = 'debug' | 'info' | 'warn' | 'error';

const SERVICE = process.env.SERVICE_NAME ?? 'order-ahead';
const VERSION = process.env.SERVICE_VERSION ?? 'dev';

export function log(level: Level, message: string, fields: Record<string, unknown> = {}): void {
  const line = JSON.stringify({
    ts: new Date().toISOString(),
    level,
    service: SERVICE,
    version: VERSION,
    message,
    ...fields,
  });
  if (level === 'error' || level === 'warn') {
    process.stderr.write(line + '\n');
  } else {
    process.stdout.write(line + '\n');
  }
}
