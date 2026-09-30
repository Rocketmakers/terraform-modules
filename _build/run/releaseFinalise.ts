#!/usr/bin/env node

import { LoggerLevel } from '@rocketmakers/log';
import { Args } from '@rocketmakers/shell-commands/lib/args';
import { Git } from '@rocketmakers/shell-commands/lib/git';
import { setDefaultLoggerLevel, createLogger } from '@rocketmakers/shell-commands/lib/logger';
import { Npm } from '@rocketmakers/shell-commands/lib/npm';
import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';
import { Shell } from '@rocketmakers/shell-commands/lib/shell';

import { RepositoryPaths } from './paths/repositoryPaths';
import { createPullRequest } from './release/githubCli';

const logger = createLogger('release-finalise');

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

  const cwd = { cwd: RepositoryPaths.resolve() };

  const { version } = await Npm.loadPackageJson(RepositoryPaths.resolve('package.json'));

  const branchName = await Git.getBranchName(cwd);
  if (!/^release\/\d+\.\d+\.\d+$/.test(branchName)) {
    throw new Error('You need to be on a release branch (release/x.x.x)');
  }

  logger.info('Committing the version, readmes and changelog');
  Git.preventHuskyHooks();
  await Shell.exec('git', ['add', 'package.json', 'CHANGELOG.md', '**/README.md'], cwd);
  await Shell.exec('git', ['commit', '-m', `release: Changelog for v${version}`], cwd);

  const targetBranch = 'main';
  logger.info(`Pushing ${branchName}`);
  await Shell.exec('git', ['push', 'origin', branchName, '--set-upstream'], cwd);

  logger.info(`Creating a pull request from ${branchName} to ${targetBranch}`);
  await createPullRequest({
    title: `Release ${version}`,
    body: 'This should just contain a version bump, updated readmes and the changelog.',
    head: branchName,
    base: targetBranch,
  });
}

run()
  .then(() => logger.info('🚀 Done 🚀'))
  .catch((err) => {
    logger.fatal(err);
    process.exit(-1);
  });
