import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';
import { Shell } from '@rocketmakers/shell-commands/lib/shell';

const gh = 'gh';

Prerequisites.register({
  command: gh,
  description: 'Github CLI',
  installInstructions: 'https://cli.github.com',
});

/**
 * Parameters required to create a GitHub pull request
 */
export interface ICreatePullRequest {
  title: string;
  body: string;
  head: string;
  base: string;
}

/**
 * Creates a pull request on GitHub using the GitHub CLI
 */
export async function createPullRequest({ title, body, head, base }: ICreatePullRequest) {
  await Shell.exec(gh, ['pr', 'create', '--title', title, '--body', body, '--head', head, '--base', base]);
}
