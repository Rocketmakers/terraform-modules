import { join } from 'path';

export namespace RepositoryPaths {
  const repositoryRootPath = join(__dirname, '../../..');
  export function resolve(...relative: string[]) {
    return join(...[repositoryRootPath, ...relative]);
  }
}
