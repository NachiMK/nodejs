'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
const authorizer = exports.authorizer = (event, context, done) => {
  const token = event.authorizationToken;

  switch (token) {
    case 'allow':
      done(null, generatePolicy('user', 'Allow', event.methodArn));
      break;
    case 'deny':
      done(null, generatePolicy('user', 'Deny', event.methodArn));
      break;
    case 'unauthorized':
      done('Unauthorized');
      break;
    default:
      done('Error');
  }
};

const generatePolicy = (principalId, Effect, Resource) => {
  const authResponse = {
    principalId
  };

  if (Effect && Resource) {
    authResponse.policyDocument = {
      Version: '2012-10-17',
      Statement: [{
        Action: 'execute-api:Invoke',
        Effect,
        Resource
      }]
    };
  }

  return authResponse;
};
//# sourceMappingURL=index.js.map