# Hixme **`Serverless`**

> This is [**`Serverless`**],
> [Hixme] Engineering's New Backend / `API` Framework

## `v2.0.0` Release

> New Features

- **`v2.0.0`**
  - Move eslint config out from 'package.json' and into a yaml confid: '.eslintrc.yml'
  - Renaming '.node-version' to '.nvmrc' and sets to version '9'
  - Also updates 'bitbucket-pipelines.yml' to compile using node 9
  - Overhaul of 'env.js' code and terminal echo/printing helpers
  - Bumps all deps listed in 'package.json' to latest-stable
  - Migrate error to yaml: 'schemas/_error.yml'
  - Reformats 'schemas/all.yml' to enhance readability
  - Additional utilities added to 'src/utils/index.js'
  - Improves webpack config: 'webpack.config.js'
  - Within 'schemas/', updates and reformats 'resources.yml' and 'models.yml'
  - Bumps package MAJOR version
  - Adds these changes to 'CHANGELOG.md'
- **`v2.0.3`**
  - updates `.env` file examples/text
  - Adds additional quick, sanity-checking type of debugging info (optional) to the '/ping' endpoint
    - Two optional query string paramaters (that would need to be set to a truthy-value): `showENV` and `showEvent`

### More Coming Soon

> **Note**
>
> Improvements to `v2.x.x` daily, throughout February 2018

---

## `v1.0.0` Release

- An Entirely Event-Driven, Service-Oriented Architecture (SOA)
- Enforces more modular and composable design patterns and service interfaces
- [**`Serverless`**] will undergird all future backend / `API` development
  - Fun fact: We've already built **six** such services!
- Increases engineer productivity and speed of new development
  - Creating, deploying, and testing new [Hixme] `API`s is easier, faster, and more enjoyable
  - Our new scaffolding and workflow automation tools offer better consistency across a set of disparate microservices
    - Engineers will be able to jump into a serverless project foreign to them, recognize a familiar & unified project / folder structure, and can then immediately be productive
- Hixme's total cost to build, maintain, and scale a constellation of microservices will _decrease_
  - Improved function- and service-level packaging of our code, techniques like "dependency tree-shaking", and other included optimizations yield us smaller, more efficient service bundles
    - And all that means we get more performant lambda-execution times, decreased infrastructure / resource usage, and cheaper aws invoices!

### Upcoming New Features

#### Currently Under Development

#### Under Consideration

- Migrate existing lambda handlers over and into new framework
- Our `REST`ful HTTP-interface designs and well-organized serverless project / folder structures help ensure we continue following our own best practices
  - Results in a manageable collection of microservices (as opposed to hundreds of individual lambdas)
- Add remaining `json` schemas / models to their respective projects
- "If [we] want to further optimize the bundle and are using ES6 features, you can use the UglifyJS Webpack Plugin together with the harmony branch of UglifyJS 2 or the Babili Webpack Plugin.": https://www.npmjs.com/package/serverless-plugin-webpack


[hixme]: https://hixme.com "Hixme, Inc."

[**`serverless`**]: https://github.com/serverless/serverless "Serverless"
