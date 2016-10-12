module namespace perm-match = "http://marklogic.com/rest-api/resource/perm-match";
declare default function namespace "http://marklogic.com/rest-api/resource/perm-match";

import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-actions"
  at '/mapping/map-actions.xqy';

declare function get(
    $context as map:map,
    $params  as map:map
) as document-node()*{
  xdmp:log("get")
};

declare function put(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()? {
  let $_ := mp:declare-as-perm-match(
      map:get($params, "primary"),
      map:get($params, "secondary")
    )
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
  let $_ := mp:break-perm-match(
      map:get($params, "primary"),
      map:get($params, "secondary")
    )
  return document { "Done" }
};