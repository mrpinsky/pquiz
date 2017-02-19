const gulp = require('gulp');
const mocha = require('gulp-mocha');

const config = gulp.config;

const runTests = function runTests() {
  process.env.NODE_ENV = 'test';
  return gulp.src('test/index.spec.js', { cwd: config.backend.dest, read: false })
  .pipe(mocha());
};

module.exports = {
  test: runTests,
};
