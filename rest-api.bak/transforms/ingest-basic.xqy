module namespace rest-ingest-basic = "http://marklogic.com/rest-api/transform/ingest-basic";
declare default function namespace "http://marklogic.com/rest-api/transform/ingest-basic";

import module namespace basic = "http://asti.dost.gov.ph/ofis/basic" at '/transform/basic.xqy';
import module namespace common = "http://asti.dost.gov.ph/ofis/common" at '/transform/common.xqy';
import module namespace tasks = "http://asti.dost.gov.ph/ofis/tasks/manager" at '/tasks/task-manager.xqy';

declare function transform (
  $context as map:map,
  $params as map:map,
  $content as document-node()
) as document-node()
{
  let $doc := $content
  let $docUri := map:get($context, "uri")
  let $mapUri := common:compute-mapping-uri($docUri)
  let $newDoc := basic:transform($mapUri, $doc)
  let $_ := tasks:schedule-task($docUri, "initial")
  return $newDoc
};