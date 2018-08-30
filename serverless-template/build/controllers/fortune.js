'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getFortune = getFortune;

var _fortuneCookie = require('fortune-cookie');

var _fortuneCookie2 = _interopRequireDefault(_fortuneCookie);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getFortune() {
  const fortune = _fortuneCookie2.default[Math.floor(Math.random() * 250) + 1];
  const message = 'success!';
  const nodeVersion = process.versions.node;

  return {
    fortune,
    message,
    'node version': nodeVersion
  };
}
//# sourceMappingURL=fortune.js.map