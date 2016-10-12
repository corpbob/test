function get(context, params) {
    // return zero or more document nodes
};

function post(context, params, input) {
    // return zero or more document nodes
    //xdmp.log("declaring update...");

};

function put(context, params, input) {
    // return at most one document node
    //declareUpdate();
    context.outputTypes = ["application/json"];

    for(var k in input){
        xdmp.log(fn.concat('k ; ', k));
    }
    var root = input.root;
    var json = root.toObject();
    var data = json.data;

    if(data.matches){
        if(data.matches.length == 0) {
            data.resolved['status'] = 'unique';
        } else if(data.matches.length > 0){
            data.resolved['status'] = 'similar';
        }
    } else {
        data.resolved['status'] = 'unique';
    }

    if(true){
        xdmp.documentInsert(data.uri, data);
    }


    if(true){

        if(params && params.op === 'reject'){
            xdmp.log("rejecting");
            if(data.rejected && data.rejected.length > 0){
                //reject index is always the last index;
                var index = data.rejected.length -1;
                var rejected = data.rejected[index];
                xdmp.log("dump of rejected: ");
                xdmp.log(rejected);
                if(rejected){
                    //we will search a new equivalence class.
                    var str=rejected.lvkey;
                    var andQuery = [ cts.jsonPropertyValueQuery('lvkey', str, ['wildcarded'])];
                    for(var i=0;i<=str.length;i++){
                        var prefix = str.substring(0,i);
                        var suffix = str.substring(i+1);
                        var newstr = prefix + '*' + suffix;
                        xdmp.log(newstr);
                        var q = cts.jsonPropertyValueQuery('lvkey', newstr, ['wildcarded']);
                        andQuery.push(q);
                    }

                    var json = cts.search( cts.orQuery(andQuery))
                    if(json){
                        var candidates = [];
                        var count = json.count;
                        for(var i=0;i<count;i++){
                            var v = json.next();
                            if(v.value){
                                var o = v.value.toObject();
                                //since the update cannot be seen immediately fron the insertDocument above, we
                                //will check if the candidate is the current document.
                                if(o.resolved.uuid === data.resolved.uuid){
                                    continue;
                                }
                                if(o.rejected && o.rejected.length > 0){
                                    var bool = true;
                                    for(var j=0;j<o.rejected.length;j++){
                                        var rej = o.rejected[j];
                                        if(rej.uuid !== rejected.uuid){
                                            bool = false;
                                            break;
                                        }
                                    }
                                    if(bool){
                                        candidates.push(o);
                                    }
                                } else {
                                    //we have no rejection, add to candidates
                                    candidates.push(o);
                                }
                            }
                        }
                    }

                    var min =3;
                    var index =0;
                    var uri;



                    if(candidates.length > 0){

                        for(var i=0;i<candidates.length;i++){
                            var c = candidates[i];
                            var d = spell.levenshteinDistance(rejected.lvkey, c.resolved.lvkey);
                            if(d < min){
                                min = d;
                                index = i;
                                uri = c.uri;
                            }

                            if(min === 0){
                                break;
                            }
                        }
                    }

                    //have we found a new equivalence class?
                    if(min < 3){
                        var equivalenceClass = fn.doc(uri);
                        if(equivalenceClass){
                            var jsonDoc = xdmp.toJSON(equivalenceClass).toObject();
                            var matches = jsonDoc.matches;
                            if(!matches){
                                matches = jsonDoc.matches = [];
                            }
                            matches.push(rejected);
                            xdmp.log('equivalenceClass');
                            xdmp.log(equivalenceClass);
                            xdmp.documentInsert(equivalenceClass.uri, equivalenceClass);
                        }
                    } else {
                        //we are our own equivalence class.
                        rejected.status = 'unique';
                        var uri = '/data/' + rejected.uuid + '.json';
                        var container = {
                            resolved: rejected,
                            matches: [],
                            'match-count': 0,
                            uri: uri,
                            rejected: []
                        };

                        xdmp.log('newContainer');
                        xdmp.log(container);
                        xdmp.documentInsert(uri, container);

                    }
                }
            }
        } else {
            xdmp.log("No params.");
        }

    }
    return input;
};

function deleteFunction(context, params) {
    // return at most one document node
};

exports.GET = get;
exports.POST = post;
exports.PUT = put;
exports.DELETE = deleteFunction;