var headers = [ "id","photo","crn","last_name","first_name","middle_name","name_extension","other_name","gender","civil_status","birthdate","birthplace","date_updated" ];
var idIdx = 0;

var fs = require('fs');
var readline = require('readline');
var parse = require('csv-parse');

var count = 0;
var data = {};
var rd = readline.createInterface({
    input: fs.createReadStream('data/dfa_mergeddb_person_fin.csv'),
    output: process.stdout,
    terminal: false
});

function getFieldValue(name, row){
	if(name === 'datasource'){
		return 'DFA';
	}
	var index = headers.indexOf(name);
	if(index > -1){
		return row[index].replace(/\\/g,'').replace(/\"/g,'\\"').trim();
	}

	throw new Error("field not found: " + name);
}

function log(str){
	if(str){
		console.log(str);
	}
}

rd.on('line', function (line) {
	parse(line, {}, function(err, output){
		var fields = output[0];
		//basically ignore first line.
		if(fields[0] === 'id') return;
		var xml = '<doc>'
		for(var i=0;i<fields.length;i++){
			var f = fields[i];
			xml += '<' + headers[i] + '>' + fields[i] + '</' + headers[i] + '>';
		}
		xml += '</doc>';
		fs.writeFileSync('data/dfa/person/' + fields[idIdx] + '.xml',xml);
	});
});

rd.on('close', function () {
	//console.log(data);
});
