module namespace task-manager = "http://marklogic.com/rest-api/resource/task-manager";
declare default function namespace "http://marklogic.com/rest-api/resource/task-manager";

import module namespace otm = "http://asti.dost.gov.ph/ofis/tasks/manager"
  at '/tasks/task-manager.xqy';

declare function get(
    $context as map:map,
    $params  as map:map
) as document-node()*{
  let $_ := otm:process-tasks(10)
  return document { "Done" }
};

declare function put(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()? {
  let $_ := otm:process-tasks(10)
  return document { "Done" }
};

declare function post(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()*{
  xdmp:log("post")
};

declare function delete(
    $context as map:map,
    $params  as map:map
) as document-node()? {
  xdmp:log("delete")
};