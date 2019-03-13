Package Template
=========

Get up to speed with writing a @hixme npm package in no time.  Supports babel and jest unit tests with code coverage reports.


## Template Instructions

This README.md is an example of a simple standard you can you.   Update it to be your own.

1. Clone this template
```bash
  git clone git@bitbucket.org:hixme/npm-package-template.git your-package-name
  cd your-package-name
  rm -rf .git
  git init
```

2. Create a new bitbucket repository
3. Update the package.json name, description and other details (name=@hixme/your-package-name)
3. Update this readme
4. Add code and unit tests
5. Update version using semver 
```bash
  npm version [version number]
```
5. Publish to npm
```bash
  npm publish 
```

## Installation

```bash
  npm install @hixme/number-sum
```

## Usage

```js
  import { sum } from '@hixme/number-sum';
  const summed = sum(1,2);
```
  
  Output should be `3`


## Tests

  `npm test`

## Contributing

In lieu of a formal style guide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code.