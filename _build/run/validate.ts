import { join } from 'path';
import { LoggerLevel } from '@rocketmakers/log';
import { Args } from '@rocketmakers/shell-commands/lib/args';
import { FileSystem } from '@rocketmakers/shell-commands/lib/fs';
import { createLogger, setDefaultLoggerLevel } from '@rocketmakers/shell-commands/lib/logger';
import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';
import { Terraform } from '@rocketmakers/shell-commands/lib/terraform';
import { RepositoryPaths } from './paths/repositoryPaths';
import { writeAwsProviderConfig, writeAzureProviderConfig } from './providers/providers';

const logger = createLogger('temp-provider-config');

async function run() {
  const args = await Args.match({
    log: Args.single({
      description: 'The log level',
      shortName: 'l',
      defaultValue: process.env.LOG_LEVEL || 'info',
      validValues: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
    }),
    directory: Args.single({
      description: 'The directory to validate',
      mandatory: true,
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

  const parentDirectoryPath = RepositoryPaths.resolve(args.directory);
  const moduleDirectories = FileSystem.getFolders(parentDirectoryPath);

  for (const moduleDirectory of moduleDirectories) {
    if (args.directory === 'aws') {
      logger.debug(`Writing aws provider config to directory: '${moduleDirectory.path}'`);
      await writeAwsProviderConfig(moduleDirectory.path);
    } else if (args.directory === 'azure') {
      logger.debug(`Writing azurerm provider config to directory: '${moduleDirectory.path}'`);
      await writeAzureProviderConfig(moduleDirectory.path);
    }

    const relativePath = join(args.directory, moduleDirectory.name);
    logger.info(`Validating ${relativePath}`);
    await Terraform.init(moduleDirectory.path);
    await Terraform.validate(moduleDirectory.path);
  }
}

run()
  .then(() => logger.info('🚀 Done 🚀'))
  .catch((err) => {
    logger.fatal(err);
    process.exit(-1);
  });
