{{#if requiredInputs}}
## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
{{#each requiredInputs}}
| `{{this.name}}` | {{{Newlines this.description}}} | {{{Newlines this.type}}} |
{{/each}}
{{/if}}

{{#if optionalInputs}}
## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
{{#each optionalInputs}}
| `{{this.name}}` | {{{Newlines this.description}}} | {{{Newlines this.type}}} | {{{Newlines this.default}}} |
{{/each}}
{{/if}}

{{#if outputs}}
## Outputs

| name      | description                 |
| --------- | --------------------------- |
{{#each outputs}}
| `{{this.name}}` | {{{Newlines this.description}}} |
{{/each}}
{{/if}}

{{#if requirements}}
## Requirements

These are required by the module.

| name | version |
| ---- | ------- |
{{#each requirements}}
| `{{this.name}}` | {{{this.version}}} |
{{/each}}
{{/if}}

{{#if providers}}
## Providers

These are the providers used by the module.

| name | version |
| ---- | ------- |
{{#each providers}}
| `{{this.name}}` | {{{this.version}}} |
{{/each}}
{{/if}}
