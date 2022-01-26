import { LoggerLevel } from '@rocketmakers/log';
import { Args } from '@rocketmakers/shell-commands/lib/args';
import { createLogger, setDefaultLoggerLevel } from '@rocketmakers/shell-commands/lib/logger';
import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';
import { validateSubdirectories } from './validate/validate';

const logger = createLogger('validate');

async function run() {
  const args = await Args.match({
    log: Args.single({
      description: 'The log level',
      shortName: 'l',
      defaultValue: process.env.LOG_LEVEL || 'info',
      validValues: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
    }),
  });

  if (args?.log) {
    setDefaultLoggerLevel(args.log as LoggerLevel);
  }

  if (!args) {
    if (process.argv.includes('--help')) {
      return;
    }

    throw new Error('There was a problem parsing the arguments');
  }

  await Prerequisites.check();

  const parentDirectories = ['aws', 'azure', 'gcp', 'shared'];
  const failedModules: string[] = [];
  for (const parentDirectory of parentDirectories) {
    const failed = await validateSubdirectories(parentDirectory, logger);
    failedModules.push(...failed);
  }

  if (failedModules.length > 0) {
    const s = failedModules.length === 1 ? '' : 's';
    logger.error(`The following module${s} failed to validate (see logs for details)`, failedModules);
    process.exit(1);
  }
}

run()
  .then(() => logger.info('🚀 Done 🚀'))
  .catch((err) => {
    logger.fatal(err);
    process.exit(-1);
  });
