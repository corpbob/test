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

    var root = input.root;
    var rootObject = root.toObject();
    var data = rootObject.data;
    xdmp.log(fn.concat('uri: ', data.uri));

    if(!data.matches){
        return { error: "Nothing to undo." };
    }

    var rejected_index = data.matches.length - 1;
    if(data.matches.length < 1){
        return { error: "Index out of bounds."};
    }

    var rejected = data.matches[rejected_index];
    if(!rejected){
        return { error: "Nothing to undo."};
    }

    var uuid = rejected.uuid;
    var json = cts.search(cts.jsonPropertyValueQuery('uuid',uuid))
    var own_container;
    var matchingInstance;
    if(json){
        var candidates = [];
        var found = false;
        var count = json.count;
        for(var i=0;i<count;i++){
            var v = json.next();
            if(v.value){
                var o = v.value.toObject();
                //result.push(o);
                if(o.matches && o.matches.length > 0){

                    for(var j=0;j<o.matches.length;j++){
                        var p = o.matches[j];
                        //result.push(p.uuid);
                        //result.push(uuid);
                        if(p.uuid === uuid){
                            found = true;
                            matchingInstance = o;
                            break;
                        }
                    }

                    if(found){
                        break;
                    }

                } //end if

                if(o.resolved.uuid === uuid){
                    own_container = o;
                    //result.push(own_container);
                    continue;
                }
            }
        }


    }

    if(found){
        //return an error..
        return { error: "Cannot undo. Another instance is matching this record: " + matchingInstance.uri };
    } else {


        if(own_container){
            //delete this
            xdmp.log("Will delete this container: " + own_container.uri);
            xdmp.documentDelete(own_container.uri);
        }

        //save the changes
        xdmp.log("saving changes");
        data.resolved.status = 'similar';
        xdmp.documentInsert(data.uri, data);
        xdmp.log(data);
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