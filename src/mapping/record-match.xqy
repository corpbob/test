module namespace record-match = "http://asti.dost.gov.ph/ofis/mapping/record-match";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/record-match";

import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-assist"
  at './map-assist.xqy';
import module namespace tasks = "http://asti.dost.gov.ph/ofis/tasks/manager" 
  at '/tasks/task-manager.xqy';

(:
 : This assumes that the person record being processed is that of ofis
 : No need to create a merge data, just simple matching between 2 records.
 :)
declare function declare-as-perm-match (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $tasks := xdmp:invoke-function(
      function() {merge-internal($primaryUri, $secondaryUri)},
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
  for $task in $tasks
  return tasks:process-task-chain($task)
};

declare function break-perm-match (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $tasks := xdmp:invoke-function(
      function() {break-internal($primaryUri, $secondaryUri)},
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
  for $task in $tasks
  return tasks:process-task-chain($task)
};

declare %private function merge-internal (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  if (check-status($primaryUri, $secondaryUri)) then
    (: only applicable to unique records :)
    let $primaryStat := mp:get-ofis-status($primaryUri)
    let $secondaryStat := mp:get-ofis-status($secondaryUri)
    let $primaryId := mp:get-id($primaryUri) 
    let $secondaryId := mp:get-id($secondaryUri)
    let $source := mp:get-source($primaryUri)
    
    let $duplicate :=
      if (not("UNIQUE" = ($primaryStat, $secondaryStat))) then
        xdmp:log("Both documents are duplicates.", "debug")
      else if ("UNIQUE" = $secondaryStat) then
        concat("/", $source, "/person/", $primaryId, "/status.xml")
      else
        concat("/", $source, "/person/", $secondaryId, "/status.xml")
    return (
      (: update matching documents' admin-status :)
      mp:create-overwrite(
        concat("/", $source, "/person/", $primaryId, "/", $secondaryId, ".xml"),
        mp:create-perm-match-document($secondaryUri)
        ),
      mp:create-overwrite(
        concat("/", $source, "/person/", $secondaryId, "/", $primaryId, ".xml"),
        mp:create-perm-match-document($primaryUri)
        ),
      (: create a "status.xml" file flagging the secondary document as duplicate. :)
      xdmp:document-insert(
        $duplicate,
        (: add more info as needed :)
        <ofis><status>DUPLICATE</status></ofis>
      ),
      tasks:schedule-task($primaryUri, "initial"),
      tasks:schedule-task($secondaryUri, "initial")
    )
  else
    ()
};

declare %private function break-internal (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $primaryId := mp:get-id($primaryUri) 
  let $secondaryId := mp:get-id($secondaryUri)
  let $source := mp:get-source($primaryUri)
  (: 
   : this assumes that the status should remain as match and never conflict. 
   :)
  let $_ := (
    mp:create-overwrite(
      concat("/", $source, "/person/", $primaryId, "/", $secondaryId, ".xml"),
      mp:create-match-document($secondaryUri)
      ),
    mp:create-overwrite(
      concat("/", $source, "/person/", $secondaryId, "/", $primaryId, ".xml"),
      mp:create-match-document($primaryUri)
      ),
    mp:delete-if-exist(concat("/", $source, "/person/", $primaryId, "/status.xml")),
    mp:delete-if-exist(concat("/", $source, "/person/", $secondaryId, "/status.xml"))
  )
  return (
    tasks:schedule-task($primaryUri, "initial"),
    tasks:schedule-task($secondaryUri, "initial")
  )
};

declare %private function check-status (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
) as xs:boolean
{
  let $priStat := mp:get-ofis-status($primaryUri)
  let $secStat := mp:get-ofis-status($secondaryUri)
  let $result := "UNIQUE" = $priStat and "UNIQUE" = $secStat
  return $result
};
