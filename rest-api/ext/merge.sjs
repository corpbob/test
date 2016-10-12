function get(context, params) {
    // return zero or more document nodes
};

function post(context, params, input) {
    // return zero or more document nodes
    context.outputTypes = ["application/json"];
    xdmp.log(input);
    var json = cts.search( cts.andQuery([
            cts.notQuery(cts.jsonPropertyValueQuery("not-equivalent","abc")),
            cts.jsonPropertyValueQuery("lvkey", "ROLANDO-ACORDA")]
    ))

    var results = [];
    var tmp = [];
    var uri = 0;
    var count = json.count;
    var min = 9999;
    for(var i=0;i<count;i++){
        var v = json.next();
        if(v.value){
            var o = v.value.toObject();
            if(o.matches && o.matches.length > 0){
                var d = spell.levenshteinDistance("ROLANDO-ACORDAZZ", o.matches[0].lvkey);
                if(d<min){
                    min = d;
                    uri = o.uri;
                    if(min === 0){
                        break;
                    }
                }
            }
        }
    }

    var jsonDoc = {};
    if(uri){
        var doc =  fn.doc(uri);
        //doc.matches.push({ "name": "bobby" });

        var jsonDoc = xdmp.toJSON(doc).toObject();
        var matches = jsonDoc.matches;
        if(matches){
            matches.push({ "name": "bobby" });
        }
    }
    return { context: context, params: params, input:jsonDoc };
};

function put(context, params, input) {
    // return at most one document node
};

function deleteFunction(context, params) {
    // return at most one document node
};

exports.GET = get;
exports.POST = post;
exports.PUT = put;
exports.DELETE = deleteFunction;