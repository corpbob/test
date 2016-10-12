var headers = [ "id","person_id","passport_number","date_updated" ];
var basedir = '../ofis-slush-new-json';
var fs = require('fs');
var readline = require('readline');
var uuid = require('uuid');
var parse = require('csv-parse');

var count = 1;
if(!fs.existsSync(basedir)){
	fs.mkdirSync(basedir);
}

if(!fs.existsSync(basedir + '/1')){
	fs.mkdirSync(basedir + '/' + 1);
}

var data = {};
var rd = readline.createInterface({
    input: fs.createReadStream('out3'),
    output: process.stdout,
    terminal: false
});

function getFieldValue(name, row){
	var index = headers.indexOf(name);
	if(index > -1){
		return row[index].replace(/\\/g,'').replace(/\"/g,'\\"').trim();
	}

	throw new Error("field not found: " + name);
}

function getTriple(theuuid, predicate, schema, fields){

	var object = getFieldValue(predicate, fields);
	if(object === 'NULL'){
		return null;
	}
	var str = '<http://example.com/person/' + theuuid + '> <http://example.com/dfa/person/' + predicate + '> "' +  object + '"^^<http://www.w3.org/2001/XMLSchema#' + schema + '> .';

	return str;
}


function log(str){
	if(str){
		console.log(str);
	}
}

rd.on('line', function (line) {
	//parse(line, {}, function(err, output){
	if(true){
		//var theuuid = uuid.v4();
		var idx = line.indexOf('{');
    var uri;
		if(idx > -1){
			uri = line.substring(0,idx).trim();
			line = line.substring(idx);
		}
		var dir = Math.ceil(count / 100000);
		var basedir_dir = basedir + '/' + dir;
		var basedir_dir_data = basedir_dir + '/data';
		if(!fs.existsSync(basedir_dir)){
			console.log('creating directory', basedir_dir);
			fs.mkdirSync(basedir_dir);
		}

		if(!fs.existsSync(basedir_dir_data)){
			console.log('creating directory', basedir_dir_data);
			fs.mkdirSync(basedir_dir_data);
		}

			fs.writeFileSync(basedir_dir + uri, line);	
			count++;
		}
});

rd.on('close', function () {
	//console.log(data);
});

var str = 'RD700,"OTHER FILLINGS, N.E.C.",registration docs';
/*tmp.forEach(function(item){
 console.log(item);
 var myRe = new RegExp("\"([a-zA-Z0-9, :.)(]+)\"",'g');
 var res = myRe.exec(item);
 console.log(res[1]);
});
*/
/*
var myRe = new RegExp("([^,]+),\"([a-zA-Z0-9, :.)(]+)\",([^,]+)",'g');
var res0 = myRe.exec(str);
console.log(res0);
*/

