const parseArgs = require('minimist');
const gulpEnv = parseArgs(process.argv.slice(2), { string: 'uid' });

const dest = gulpEnv.dest || 'dist';

if (gulpEnv.production && gulpEnv.dest === undefined) {
  throw new Error('production build requires explicit destination');
}

module.exports = {
  argv: gulpEnv,
  isProd: !!gulpEnv.production,
  servicePort: (gulpEnv.port || 4000),
  dest: dest,
  // frontend: {
  //   dest: `${dest}/frontend`,
  //   src: 'src/angular',
  //   entry: 'app.js',
  //   templates: ['**/*.template.html'],
  //   sort: ['**/vendor.js', '**/app.js', '**/module.js', '**/*.js'],
  //   index: ['src/angular/index.html'],
  //   assets: ['assets/**'],
  //   libs: [],
  // },

  styles: {
    src: 'src/styles',
    files: ['**/*.scss'],
  },

  backend: {
    dest: `${dest}/backend`,
    src: 'src/node',
    scripts: ['**/*.js', '**/*.ts'],
    sql: ['**/*.sql'],
    templates: ['**/*.njn', '**/*.html'],
    assets: ['assets/**'],
  },

};
