import { Args } from '@rocketmakers/shell-commands/lib/args';
import { createLogger, setDefaultLoggerLevel } from '@rocketmakers/shell-commands/lib/logger';
import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';
import { generateReadmes } from './readme/readme';
import * as path from 'path';

Prerequisites.register({
  command: 'terraform-docs',
  description: 'Generates docs for terraform',
  installInstructions: 'brew install terraform-docs'
})

async function run() {
  const args = await Args.match({
    log: Args.single({
      description: 'The log level',
      shortName: 'l',
      defaultValue: process.env.LOG_LEVEL || 'info',
      validValues: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
    })
  });

  if (!args) {
    return;
  }

  const { log } = args;

  setDefaultLoggerLevel(log as any);
  const logger = createLogger('readme');

  try {
    await Prerequisites.check();

    await generateReadmes(path.join(__dirname, '../../'));
  } catch (e) {
    logger.error(e.message);
    process.exit(-1);
  }
}

// eslint-disable-next-line @typescript-eslint/no-floating-promises
run();
