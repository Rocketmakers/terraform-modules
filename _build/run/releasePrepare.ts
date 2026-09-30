#!/usr/bin/env node

import { LoggerLevel } from '@rocketmakers/log';
import { Args } from '@rocketmakers/shell-commands/lib/args';
import { Git } from '@rocketmakers/shell-commands/lib/git';
import { setDefaultLoggerLevel, createLogger } from '@rocketmakers/shell-commands/lib/logger';
import { Npm } from '@rocketmakers/shell-commands/lib/npm';
import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';
import { Shell } from '@rocketmakers/shell-commands/lib/shell';

import { RepositoryPaths } from './paths/repositoryPaths';
import { generateReadmes } from './readme/readme';

const logger = createLogger('release-prepare');

async function run() {
  const args = await Args.match({
    log: Args.single({
      description: 'The log level',
      shortName: 'l',
      defaultValue: process.env.LOG_LEVEL || 'info',
      validValues: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
    }),
    as: Args.single({
      description: 'The kind of release to prepare',
      validValues: ['major', 'minor', 'patch'],
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

  const cwd = { cwd: RepositoryPaths.resolve() };

  const branchName = 'main';
  logger.info(`Checking out and pulling ${branchName}`);
  await Git.checkout({ branchName, errorIfGitNotClean: true }, cwd);
  await Git.pull({ errorIfNotTracking: true, errorIfGitNotClean: true }, cwd);

  logger.info('Bumping version and generating changelog');
  await Shell.exec('pnpm', ['exec', 'commit-and-tag-version', '--release-as', args.as], cwd);

  const { version } = await Npm.loadPackageJson(RepositoryPaths.resolve('package.json'));

  logger.info(`Generating readmes for v${version}`);
  await generateReadmes({ rootDir: RepositoryPaths.resolve(), version });

  await Shell.exec('git', ['checkout', '-b', `release/${version}`], cwd);
}

run()
  .then(() => logger.info('🚀 Done 🚀'))
  .catch((err) => {
    logger.fatal(err);
    process.exit(-1);
  });
