import { LoggerLevel } from '@rocketmakers/log';
import { Args } from '@rocketmakers/shell-commands/lib/args';
import { createLogger, setDefaultLoggerLevel } from '@rocketmakers/shell-commands/lib/logger';
import { Prerequisites } from '@rocketmakers/shell-commands/lib/prerequisites';
import { Slack } from '@rocketmakers/shell-commands/lib/slack';

const logger = createLogger('slack');

async function run() {
  const args = await Args.match({
    log: Args.single({
      description: 'The log level',
      shortName: 'l',
      defaultValue: process.env.LOG_LEVEL || 'info',
      validValues: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
    }),
    testName: Args.single({
      shortName: 't',
      description: 'The name of the test',
    }),
    jobStatus: Args.single({
      description: 'Whether the test passed',
      defaultValue: process.env.CI_JOB_STATUS,
    }),
    webhookUrl: Args.single({
      description: 'The platform slack webhook URL for sending messages',
      defaultValue: process.env.SLACK_WEBHOOK_URL_PLATFORM,
    }),
    pipelineUrl: Args.single({
      description: 'The URL of the pipeline ',
      defaultValue: process.env.CI_PIPELINE_URL,
    }),
  });

  if (!args) {
    if (process.argv.includes('--help')) {
      return;
    }

    throw new Error('There was a problem parsing the arguments');
  }

  setDefaultLoggerLevel(args.log as LoggerLevel);

  await Prerequisites.check();

  await Slack.send(args.webhookUrl, {text: `Terratest ${args.jobStatus} for ${args.testName}. See it here ${args.pipelineUrl}`, });
}

run()
  .then(() => logger.info('🚀 Done 🚀'))
  .catch((err) => {
    logger.fatal(err);
    process.exit(-1);
  });
