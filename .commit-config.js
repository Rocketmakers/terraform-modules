/**
 * Used as the single source of truth for cz-customizable and standard-version configuration
 */
const types = [
  {
    name: 'build',
    description: 'Changes that affect the build system or external dependencies',
    changelogHeading: 'Build System',
    allowBreakingChanges: true,
  },
  {
    name: 'ci',
    description: 'Changes made to the CI pipeline',
    changelogHeading: 'CI',
    allowBreakingChanges: true,
  },
  {
    name: 'chore',
    description: 'Other changes',
    changelogHeading: 'Other Changes',
    allowBreakingChanges: true,
  },
  {
    name: 'feat',
    description: 'A new feature',
    changelogHeading: 'Features',
    allowBreakingChanges: true,
  },
  {
    name: 'fix',
    description: 'A bug fix',
    changelogHeading: 'Bug Fixes',
    allowBreakingChanges: true,
  },
  {
    name: 'perf',
    description: 'A code change that improves performance',
    changelogHeading: 'Performance Improvements',
    allowBreakingChanges: true,
  },
  {
    name: 'refactor',
    description: 'A code change that neither fixes a bug nor adds a feature',
    changelogHeading: 'Code Refactoring',
    allowBreakingChanges: true,
  },
  {
    name: 'test',
    description: 'Adding or updating tests',
    changelogHeading: 'Tests',
    allowBreakingChanges: true,
  },
  {
    name: 'docs',
    description: 'Documentation only changes',
    changelogHeading: '',
    allowBreakingChanges: true,
  },
  {
    name: 'release',
    description: 'Changes made during the release process (e.g. changelog commit)',
    changelogHeading: '',
    allowBreakingChanges: true,
  },
  {
    name: 'style',
    description:
      'Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)',
    changelogHeading: '',
    allowBreakingChanges: true,
  },
  {
    name: 'upgrade',
    description: 'Upgrades to tools, providers, dependencies etc',
    changelogHeading: 'Upgrades',
    allowBreakingChanges: true,
  },
];

// Used to set indentation for readable CLI output
const longestTypeName = types.reduce((longest, type) => Math.max(type.name.length, longest), 0);

/*****************************************
 * Exports
 *****************************************/

/**
 * The config object used with cz-customizable
 */
const czCustomizable = {
  types: types.sort(sortByChangeLog).map((t) => buildCommitizenTypeConfig(t, longestTypeName)),
  allowCustomScopes: false,
  allowBreakingChanges: types.filter((t) => t.allowBreakingChanges).map((t) => t.name),
  upperCaseSubject: true,

  // The choice of scopes will be project specific
  scopes: [
    { name: '' },
    { name: 'aws-gitlab-ci' },
    { name: 'azure-gitlab-ci' },
    { name: 'gcp-gitlab-ci' },
    { name: 'azure-github-ci' },
    { name: 'gcp-github-ci' },
    { name: 'shared-ci' },
    { name: 'terratest' },
    { name: 'config' },
    { name: 'scripts' },
  ],
};

const standardVersion = {
  types: types.map(buildStandardVersionConfig),
  skip: {
    tag: true,
    bump: true,
    commit: true,
  },
};

module.exports = {
  czCustomizable,
  standardVersion,
};

/*****************************************
 * Helper functions
 *****************************************/

/**
 * Sorts two types based on whether they have a changelogHeading
 */
function sortByChangeLog(a, b) {
  const ac = !!a.changelogHeading;
  const bc = !!b.changelogHeading;
  return ac === bc ? 0 : ac ? -1 : 1;
}

/**
 * Builds an object used to configure a cz-customizable commit type
 * @param {*} type An element from the types array defined in this file
 * @param {number} nameIndentSize The minimum indentation to use for readability when creating a commit
 */
function buildCommitizenTypeConfig(type, nameIndentSize) {
  const { name, description, changelogHeading } = type;
  const spaces = Array.from({ length: nameIndentSize - name.length }, () => ' ').join('');
  const notInChangelogMsg = changelogHeading ? '' : '[not in changelog] ';

  return {
    value: name,
    name: `${name}${spaces} : ${notInChangelogMsg}${description}`,
  };
}

function buildStandardVersionConfig(type) {
  return {
    type: type.name,
    section: type.changelogHeading,
    hidden: !type.changelogHeading,
  };
}
