import { join } from 'path';
import { FileSystem } from '@rocketmakers/shell-commands/lib/fs';

const providersFilename = 'providers.tf';

async function writeProviderConfig(moduleDirectoryPath: string, providerConfig: string): Promise<string> {
  const providersPath = join(moduleDirectoryPath, providersFilename);

  const silentFail = true;
  await FileSystem.unlinkAsync(providersPath, silentFail);
  await FileSystem.writeFileAsync(providersPath, providerConfig, { encoding: 'utf-8' });

  return providersPath;
}

/**
 * Writes AWS provider config to the given directory
 * @param moduleDirectoryPath The directory to write to
 *
 * @description The AWS provider needs a default region so we write one here.
 * This allows terraform init to pass without having to hard code a region into the module configuration.
 * @returns The path to the file that was written
 */
export function writeAwsProviderConfig(moduleDirectoryPath: string): Promise<string> {
  return writeProviderConfig(
    moduleDirectoryPath,
    `provider "aws" {
  region = "eu-west-1"
}
`
  );
}

/**
 * Writes Azure provider config to the given directory
 * @param moduleDirectoryPath The directory to write to
 *
 * @description Due to https://github.com/hashicorp/terraform-provider-azurerm/issues/7359#issuecomment-648711339 we need to setup
 * an azure providers record in order for terraform-providers to pass.
 * However, according to https://www.terraform.io/docs/language/modules/develop/providers.html we should not be defining
 * provider blocks in reusable modules.
 * This allows terraform init to pass without having to hard code a region into the module configuration.
 */
export function writeAzureProviderConfig(moduleDirectoryPath: string): Promise<string> {
  return writeProviderConfig(
    moduleDirectoryPath,
    `provider "azurerm" {
  subscription_id = "68bb123f-6027-4e99-8ab0-a01fb16cdd79"
  features {}
}
`
  );
}
