import fortuneCookie from 'fortune-cookie';

export function getFortune() {
  // grab a random fortune from the 'fortune-cookie' module
  const fortune = fortuneCookie[Math.floor(Math.random() * 250) + 1];
  const message = 'success!';
  const nodeVersion = process.versions.node;

  return {
    fortune,
    message,
    'node version': nodeVersion,
  };
}
