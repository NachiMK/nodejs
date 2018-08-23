import ODSLogger from './ODSLogger'

console.log('Testing ODSLogger print information and above...')
ODSLogger.log('info', 'Log from the Logger - simple string')
const testparam = {
  test: 'Test string in object',
  numbertest: 123,
}
ODSLogger.log('info', 'Log from the Logger - object %j', testparam)
ODSLogger.log('info', 'Log from the Logger - printf style %s', 'test string in logger')
ODSLogger.log('info', `string interpolation:${testparam}`)
console.log('DONE - Testing ODSLogger print information and above...')

console.log('Testing ODSLogger print warn and above...')
ODSLogger.log('info', 'Log from the Logger - should not print this.')
ODSLogger.log('warn', 'Log from the Logger - warning message should print')
ODSLogger.log('error', 'Log from the Logger - Error should print this.')
console.log('DONE - Testing ODSLogger print warn and above...')

// testing from cli: odsloglevel=info node lib/modules/log/generate-test.js
// testing from cli: odsloglevel=warn node lib/modules/log/generate-test.js
// testing from cli: odsloglevel=error node lib/modules/log/generate-test.js
