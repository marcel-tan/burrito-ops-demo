import { createApp } from './app';
import { log } from './logger';

const port = Number(process.env.PORT ?? 8080);

createApp().listen(port, () => {
  log('info', 'order-ahead listening', { port });
});
