module namespace ingest-basic = "http://asti.dost.gov.ph/ofis/mlcp/ingest-basic";
declare default function namespace "http://asti.dost.gov.ph/ofis/mlcp/ingest-basic";

import module namespace basic = "http://asti.dost.gov.ph/ofis/basic" at '../basic.xqy';
import module namespace common = "http://asti.dost.gov.ph/ofis/common" at '../common.xqy';
import module namespace tasks = "http://asti.dost.gov.ph/ofis/tasks/manager" at '/tasks/task-manager.xqy';

declare function transform (
  $content as map:map,
  $context as map:map
) as map:map*
{
  let $docUri := map:get($content, "uri")
  let $doc := map:get($content, "value")
  let $mapUri := common:compute-mapping-uri($docUri)
  let $newDoc := basic:transform($mapUri, $doc)
  let $_ := map:put($content, "value", $newDoc)
  let $_ := tasks:schedule-task($docUri, "initial")
  
  return $content
};