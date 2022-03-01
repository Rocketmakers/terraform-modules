import { LoggerLevel } from '@rocketmakers/log';
import { Args } from '@rocketmakers/shell-commands/lib/args';
import { createLogger, setDefaultLoggerLevel } from '@rocketmakers/shell-commands/lib/logger';
import { Npm } from '@rocketmakers/shell-commands/lib/npm';
import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';
import { generateReadmes } from './readme/readme';
import { RepositoryPaths } from './paths/repositoryPaths';

const logger = createLogger('readmes');

Prerequisites.register({
  command: 'terraform-docs',
  description: 'Generates docs for terraform',
  installInstructions: 'asdf plugin add terraform-docs https://github.com/looztra/asdf-terraform-docs',
});

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

  const { version } = await Npm.loadPackageJson(RepositoryPaths.resolve('package.json'));

  await generateReadmes({
    rootDir: RepositoryPaths.resolve(),
    version,
  });
}

run()
  .then(() => logger.info('🚀 Done 🚀'))
  .catch((err) => {
    logger.fatal(err);
    process.exit(-1);
  });
