# Serverless Template

> This is the template for creating new [Serverless](https://serverless.com/ "Build auto-scaling, pay-per-execution, event-driven apps on AWS Lambda")-powered API microservices.

## Getting Started

Want to create a new serverless project? Perfect!

1.  Install (or Upgrade) [Serverless](https://serverless.com/ "Build auto-scaling, pay-per-execution, event-driven apps on AWS Lambda") Globally:

        npm install --global serverless

2.  Create New Project (using Hixme's template):

    > **Note**:
    > this process will become easier in the future.
    > Until then, bare with the `git` and other `shell` commands for now. :)

          git clone git@bitbucket.org:hixme/serverless-template.git your-service-name && \
          cd your-service-name/ && \
          rm -rf .git/ && \
          git init

3.  All done!

    At this point, you'll find yourself inside the directory of your new project.
    You will have a fresh copy of the Hixme serverless template and _zero_ git commit history.

    You're all set to start developing in _serverless_!

## Update `README.md` & `package.json`

Since you're cloning from _this_ template, you'll want to completely change this `README.md` file. You should end up with `package.json` and `README.md` files that makes sense for your service.

> **It's Important To...**
>
> Update `README.md` with instructions for your service: how to get it up and running, how to run tests, etc.

## Getting Up and Running

After cloning the project

#### Install Project Dependencies

```bash
npm install
```

in you project's root directory. Then, you can

#### Start Local `Dev` Server

```bash
npm start
```


* * *

> **Note:**
>
> The content below will move into a `./docs/` folder—or into a wiki _soon_.

# Tips, Tricks, & How-Tos

### Get Service Information / Endpoints

    npm run info

    # or, fetch info about your service in a particular stage:

    npm run info:stage -- dev
    npm run info:stage -- int
    npm run info:stage -- prod
    npm run info:stage -- foo-bar-fizz-buzz-stage-name-here

### Build Project / Transpile Everything to `ES5`

    npm run build

    # or, watch for file changes and continually (re-)build while you work!

    npm run watch

    # ( which is an alias to `npm run build:watch` )

### Invoke Functions Locally

    npm run invoke:local -- your-function-name-here --data '{"yourJSONPayload":"goes right here\!"}'

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

* * *

#### Hixme Serverless Template (ver `1.0.0`)

Template Features:

-   Encrypted code (in s3) at rest
-   Improved lambda webpack bundling and dependency tree-shaking
-   Only _necessary_, _actually used_ dependencies are bundled together

[serverless]: https://serverless.com/ "Build auto-scaling, pay-per-execution, event-driven apps on AWS Lambda"



****

# Notes
This project prefers that you are running the latest version of Node. Currently that is version `v9.5.0`+. Recommended method of managing multiple versions of node on your machine: follow the install instructions: https://github.com/creationix/nvm/
