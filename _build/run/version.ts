#!/usr/bin/env node

import { LoggerLevel } from '@rocketmakers/log';
import { Args } from '@rocketmakers/shell-commands/lib/args';
import { setDefaultLoggerLevel, createLogger } from '@rocketmakers/shell-commands/lib/logger';
import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';

import { bumpVersion } from './version/version';

const logger = createLogger('version');

async function run() {
  const args = await Args.match({
    force: Args.single({
      description: 'Skip checks on git branch and clean working copy (potentially dangerous...)',
      defaultValue: 'false',
    }),
    log: Args.single({
      description: 'The log level',
      shortName: 'l',
      defaultValue: process.env.LOG_LEVEL || 'info',
      validValues: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
    }),
    version: Args.single({
      description: 'The new version number',
      shortName: 'v',
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

  const newVersion = args.version?.trim();
  if (!newVersion) {
    throw new Error('Expecting a version number via --version (-v)');
  }

  logger.info(`Bumping version: ${newVersion}`);
  await bumpVersion({ newVersion, force: args.force === 'true' }, logger);
}

run()
  .then(() => logger.info('🚀 Done 🚀'))
  .catch((err) => {
    logger.fatal(err);
    process.exit(-1);
  });
