const gulp = require('gulp');
gulp.config = require('./config');

require('./tasks');

gulp.task('default', gulp.series('clean', 'serve'));
