import { join } from 'path';
import { Logger } from '@rocketmakers/log';
import { FileSystem } from '@rocketmakers/shell-commands/lib/fs';
import { Terraform } from '@rocketmakers/shell-commands/lib/terraform';
import { writeAwsProviderConfig, writeAzureProviderConfig } from './providers';
import { RepositoryPaths } from '../paths/repositoryPaths';

/**
 * Validates all modules within a subdirectory
 * @param parentDirectoryName The name of the parent directory. This must be at the repository root.
 * @param logger The logger to use.
 * @returns An array of relative paths to modules that failed to validate.
 */
export async function validateSubdirectories(parentDirectoryName: string, logger: Logger): Promise<string[]> {
  const parentDirectoryPath = RepositoryPaths.resolve(parentDirectoryName);
  const moduleDirectories = FileSystem.getFolders(parentDirectoryPath);

  logger.info(`Validating all modules within '${parentDirectoryName}'`);

  const failed: string[] = [];

  for (const moduleDirectory of moduleDirectories) {
    const tempFiles = [join(moduleDirectory.path, '.terraform.lock.hcl')];

    if (parentDirectoryName === 'aws') {
      logger.debug(`Writing aws provider config to directory: '${moduleDirectory.path}'`);
      tempFiles.push(await writeAwsProviderConfig(moduleDirectory.path));
    } else if (parentDirectoryName === 'azure') {
      logger.debug(`Writing azurerm provider config to directory: '${moduleDirectory.path}'`);
      tempFiles.push(await writeAzureProviderConfig(moduleDirectory.path));
    }

    const relativePath = join(parentDirectoryName, moduleDirectory.name);
    logger.info(`Validating ${relativePath}`);

    try {
      await Terraform.init(moduleDirectory.path);
      await Terraform.validate(moduleDirectory.path);
    } catch {
      failed.push(relativePath);
    } finally {
      await Promise.all(
        tempFiles.map((tempFilePath) => {
          if (!FileSystem.exists(tempFilePath)) {
            return Promise.resolve();
          }
          logger.debug(`Deleting temporary file: '${tempFilePath}'`);
          return FileSystem.unlinkAsync(tempFilePath);
        })
      );
    }
  }

  return failed;
}
