/*jshint node:true*/
'use strict';

 var args = {};
  process.argv.forEach(function(arg, index, array) {
    //console.log('argv['+index+']=' + arg);
    if (arg.match(/^--([^=]+)=(.*)$/)) {
      var key = arg.replace(/^--([^=]+)=(.*)$/, '$1');
      var val = arg.replace(/^--([^=]+)=(.*)$/, '$2');
      args[key] = val;
    }
  });


process.env['NODE_ENV'] = args['node-env'] || 'build';
process.env['PORT'] = args['app-port'] || 3041;
process.env['ML_HOST'] = args['ml-host'] || 'localhost';
process.env['ML_PORT'] = args['ml-port'] || 3040;

require(args['server-script'] || './node-server/node-app.js');