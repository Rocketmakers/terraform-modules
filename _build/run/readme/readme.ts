import { FileSystem } from '@rocketmakers/shell-commands/lib/fs';
import { Shell } from '@rocketmakers/shell-commands/lib/shell';
import { createLogger } from '@rocketmakers/shell-commands/lib/logger';
import * as handlebars from "handlebars";
import * as path from 'path';
import * as _ from 'underscore';

const logger = createLogger('logger');

const readmeTemplateFilename = 'readme.tpl';

interface ITerraformInput {
  name: string
  type: string
  description: string
  default: any
  required: boolean
}

interface ITerraformOutput {
  name: string
  description: string
}

interface ITerraformProvider {
  name: string
  alias: string
  version: string
}

interface ITerraformRequirement {
  name: string
  version: string
}

interface ITerraformModuleRaw {
  header: string
  inputs: ITerraformInput[]
  outputs: ITerraformOutput[]
  providers: ITerraformProvider[]
  requirements: ITerraformRequirement[]
}

interface ITerraformModuleProcessed {
  header: string
  requiredInputs: ITerraformInput[]
  optionalInputs: ITerraformInput[]
  outputs: ITerraformOutput[]
  providers: ITerraformProvider[]
  requirements: ITerraformRequirement[]
}

async function generateReadme(rootDir: string) {
  logger.info(`Generating readme for '${rootDir}'...`);

  const content = await Shell.execOutput('terraform-docs', ['json', './'], {
    cwd: rootDir,
  });
  
  const data = preprocessModule(JSON.parse(content));

  logger.trace('Extracted data', data);

  const coreTemplateContent = await FileSystem.readFileAsync(path.join(__dirname, '../../../', 'readme.core.tpl'));
  const generateCoreTemplate = handlebars.compile(coreTemplateContent.toString());
  const coreContent = generateCoreTemplate(data);

  const templateContent = await FileSystem.readFileAsync(path.join(rootDir, readmeTemplateFilename));
  const generateTemplate = handlebars.compile(templateContent.toString());
  const output = generateTemplate({ coreContent });
  await FileSystem.writeFileAsync(path.join(rootDir, 'README.md'), output);

  logger.info('Complete');
}

function containsTemplate(rootDir: string) {
  return !!FileSystem.getFiles(rootDir).find(x => x.name === readmeTemplateFilename);
}

function preprocessModule(module: ITerraformModuleRaw): ITerraformModuleProcessed {
  const { header, inputs, outputs, providers, requirements } = module
  const [requiredInputs, optionalInputs] = _.partition(inputs, i => i.required)

  return {
    header,
    requiredInputs: _.sortBy(requiredInputs, i => i.name),
    optionalInputs: _.sortBy(optionalInputs.map(x => {
      return {
        ...x,
        default: JSON.stringify(x.default).replace(/^"/, '').replace(/"$/, '')
      }
    }), i => i.name),
    outputs: _.sortBy(outputs, o => o.name),
    providers: _.sortBy(providers, p => p.name),
    requirements: _.sortBy(requirements, r => r.name),
  }
}

export async function generateReadmes(rootDir: string) {
  const folders = FileSystem.getFolders(rootDir);
  for (const folder of folders) {
    if (folder.name === 'node_modules') {
      continue;
    }

    handlebars.registerHelper('Newlines', content => (content as string)?.replace(/\n/g, '<br />'));

    logger.trace(`Checking '${folder.path}'...`);
    if (containsTemplate(folder.path)) {
      await generateReadme(folder.path);
    }
    
    await generateReadmes(folder.path);
  }
}