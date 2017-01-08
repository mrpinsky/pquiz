const gulp = require('gulp');

require('./backend');
require('./frontend');

gulp.task('clean', gulp.parallel('clean:frontend', 'clean:backend'));
gulp.task('build', gulp.parallel('build:frontend', 'build:backend'));
// gulp.task('watch', gulp.parallel('watch:frontend', 'watch:backend'));
gulp.task('serve', gulp.parallel('serve:frontend', 'serve:backend'));