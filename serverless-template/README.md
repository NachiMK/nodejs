# Serverless Template

> This is the template for creating new [Serverless](https://serverless.com/ "Build auto-scaling, pay-per-execution, event-driven apps on AWS Lambda")-powered API microservices.  This has all the latest Hixme libraries, best practices, and examples for common tasks such as interfacing with DynamoDB, Aurora, and more... 

## Getting Started

Want to create a new serverless project? Perfect!

1.  Install (or Upgrade) [Serverless](https://serverless.com/ "Build auto-scaling, pay-per-execution, event-driven apps on AWS Lambda") Globally:

        sudo npm install --global serverless

2.  Create New Project (using Hixme's template):

    > **Note**:
    > this process will become easier in the future.
    > Until then, bare with the `git` and other `shell` commands for now. :)

          git clone git@bitbucket.org:hixme/serverless-template.git your-service-name
          cd your-service-name
          rm -rf .git
          git init

3.  All done!

    At this point, you'll find yourself inside the directory of your new project.
    You will have a fresh copy of the Hixme serverless template and _zero_ git commit history.

    You're all set to start developing in _serverless_!

## Getting Up and Running

After cloning the project

#### Update package.json

```bash
"name": "my-service",
"version": "1.0.0",
"description": "Description of my service",
```

#### Install Project Dependencies

```json
npm install
```

in you project's root directory. Then, you can

## Testing 
There are a few different options for trying out your new service

#### Create Jest Tests

1. Create your Jest tests in the `__tests__` folder
2. Run your tests
```bash
npm test
```

#### Debug using Visual Studio Code

1. Select a configuration to test
2. Click play button to run

##### Add new VS Code configuration

1. Edit configuration using .vscode/launch.json
2. Copy from an existing configuration object

#### Start Local `Dev` Server

1. Start local serverless server
```bash
npm start
```

2. Use Postman to test the http endpoit


## Developing your service

There are a bunch of examples to help get you up to speed.  Use these as a starting point but delete them once you write your own.

## Update `README.md` & `package.json`

Since you're cloning from _this_ template, you'll want to completely change this `README.md` file. You should end up with `package.json` and `README.md` files that makes sense for your service.

> **It's Important To...**
>
> Update `README.md` with instructions for your service: how to get it up and running, how to run tests, etc.

## Serverless.yml vs Config.yml
We decided to split up the serverless.yml into two files to make it easier to get started and focus on just the changes you want to make.   This also makes it easier for us to upgrade the stuff that doesn't change from service to service.  The config.yml has the stuff that changes for each service (functions and permissions) while the serverless.yml has all the stuff that doesn't change.  One exception is you might want to comment out a serverless.yml plugin in your service if it's causing problems or you are not using it.

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

### Debug serverless packaging issues

    sls package


#### Hixme Serverless Template (ver `2.5.0`)

Template Features:

-   Objection.js / knex.js / PostgreSQL examples
-   DynamoDB examples
-   Unit tests now use the stage of package.json
-   yml split into serverless.yml (unchanging) and config.yml (functions and permissions)
-   serverless-prune-plugin to delete old lambda versions so we don't run out of space
-   serverless-content-encoding to compress response payloads to make them faster to transmit
-   serverless-domain-manager to use subdomain alias for protection against changing api gateway urls
-   Encrypted code (in s3) at rest
-   Improved lambda webpack bundling and dependency tree-shaking
-   Only _necessary_, _actually used_ dependencies are bundled together

[serverless]: https://serverless.com/ "Build auto-scaling, pay-per-execution, event-driven apps on AWS Lambda"


****

## Folders / Layers
#### routes
HTTP endpoints that call into controllers layer (should be very thin)

#### triggers
dynamo, s3, sns, schedule (anything that's not an http endpoint)

#### controllers
Where the main business logic or CRUD orchestration lives.     Typically makes calls to the data layer.

#### data 
Functions for doing basic CRUD operations on a database.   This is the Model in MVC.

### proxy
Wrappers to call other lambdas or services

#### modules
Reusable code such as utilities or libraries that can eventually be made into a package.

#### scripts
Any scripts related to the service that may or may not grow up to be a lambda / endpoint some day

#### schemas
Any json schemas that are shared across multiple endpoints

# Notes
This project prefers that you are running the latest version of Node that is supported by AWS Lambda. Currently that is version `v8.10`. Recommended method of managing multiple versions of node on your machine: follow the install instructions: https://github.com/creationix/nvm/
