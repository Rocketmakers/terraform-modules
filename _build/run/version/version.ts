import { Logger } from '@rocketmakers/log';
import { Git } from '@rocketmakers/shell-commands/lib/git';
import { Shell } from '@rocketmakers/shell-commands/lib/shell';

import { RepositoryPaths } from '../paths/repositoryPaths';

/**
 * Parameters for the bumpVersion function
 */
export interface IBumpVersion {
  /**
   * The new version to bump to
   */
  newVersion: string;

  /**
   * If true then git working copy checks will be skipped
   */
  force: boolean;
}

async function isGitOnBranches(branchNames: RegExp[]) {
  const gitBranchOutput = await Git.getBranchName();
  const isGitOnDefinedBranches = branchNames.filter((branch) => branch.test(gitBranchOutput)).length > 0;
  if (!isGitOnDefinedBranches) {
    throw new Error(`Git HEAD not not valid for branches ${branchNames.join('|')}`);
  }
}

export async function bumpVersion({ newVersion, force }: IBumpVersion, logger: Logger) {
  const cwd = { cwd: RepositoryPaths.resolve() };
  if (!force) {
    await Git.throwIfNotClean(cwd);
    await isGitOnBranches([/^master$/, /^release\/.+$/]);
  } else {
    logger.warn('Careful now - Skipping checks on git working copy!');
  }

  await Shell.exec('npm', ['version', '--no-git-tag-version', newVersion], cwd);

  Git.preventHuskyHooks();
  await Shell.exec('git', ['add', 'package.json', 'package-lock.json'], cwd);
  await Shell.exec('git', ['commit', '-m', `release(version): bump to v${newVersion}`], cwd);
}
