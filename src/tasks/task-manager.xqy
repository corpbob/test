module namespace ofis-tasks-manager = "http://asti.dost.gov.ph/ofis/tasks/manager";
declare default function namespace "http://asti.dost.gov.ph/ofis/tasks/manager";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
import module namespace gor = "http://asti.dost.gov.ph/ofis/mapping/generate-ofis-record"
  at "/mapping/generate-ofis-record.xqy";
import module namespace gc = "http://asti.dost.gov.ph/ofis/mapping/generate-conflicts"
  at "/mapping/generate-conflicts.xqy";
import module namespace gm = "http://asti.dost.gov.ph/ofis/mapping/generate-matches"
  at "/mapping/generate-matches.xqy";
import module namespace gpm = "http://asti.dost.gov.ph/ofis/mapping/generate-perm-matches"
  at "/mapping/generate-perm-matches.xqy";
import module namespace ger = "http://asti.dost.gov.ph/ofis/mapping/generate-enhanced-record"
  at "/mapping/generate-enhanced-record.xqy";

declare variable $runningFlag as xs:boolean := false();

declare function schedule-task($docUri as xs:string, $task as xs:string) as xs:string? {
  if (check-task($docUri, $task)) then
    let $_ := xdmp:log("at schedule-task", "debug")
    let $uri := concat("/tasks/", sem:uuid-string(), ".xml")
    let $_ := xdmp:document-insert(
      $uri,
      <task>
        <uri>{$docUri}</uri>
        <goal>{$task}</goal>
      </task>,
      (),
      $task
    )
    return $uri
  else
    ()
};

declare %private function check-task($docUri as xs:string, $task as xs:string) as xs:boolean {
  let $query := cts:and-query((
    cts:directory-query("/tasks/"),
    cts:element-value-query(xs:QName("uri"), $docUri),
    cts:element-value-query(xs:QName("goal"), $task)
  ))
  let $result := empty(cts:search(/, $query))
  return $result
};

declare function schedule-task-and-run($docUri as xs:string, $task as xs:string) {
  let $uri := xdmp:invoke-function(
      function() {schedule-task($docUri, $task)},
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
  return process-task-chain($uri)
};

declare function reset-flag() {
  let $ofis-tasks-manager:runningFlag := false()
  return ()
};

declare function process-tasks($size as xs:long) {
  (:
  if ($ofis-tasks-manager:runningFlag) then
    xdmp:log("already running. no need to overlap.")
  else
  :)
  let $_ := xdmp:log("at start of tasks", "debug")
  let $ofis-tasks-manager:runningFlag := true()
  let $taskUris := cts:uris("", 
      ("document", "eager", "score-random", "sample="||$size), 
      cts:directory-query("/tasks/")
    )
  let $_ :=
    for $taskUri in $taskUris
    let $_ := xdmp:log("at each task start", "debug")
    return process-task-chain($taskUri) 
  let $ofis-tasks-manager:runningFlag := false()
  let $_ := xdmp:log("at end of process-tasks: " || count($taskUris), "debug")
  return ()
};

declare function process-task-chain($taskUri as xs:string) {
  let $next := xdmp:invoke(
      "./task-worker.xqy",
      (xs:QName("uri"), $taskUri),
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    ) 
  return process-task-chain($next)
};

declare function process-task($taskUri as xs:string) {
  let $req := xdmp:request()
  let $_ := prof:enable($req)
  let $task := doc($taskUri)
  return
  if (empty($task)) then 
  (
    xdmp:log('task not found: '||$taskUri),
    prof:disable($req)
  )
  else
    let $_ := xdmp:log("["||$taskUri||"] at process task", "debug")
    let $next := process-document($task/task/uri/data(), $task/task/goal/data())
    let $_ := xdmp:log("["||$taskUri||"] at delete task", "debug")
    let $_ := xdmp:document-delete($taskUri)
    let $_ := xdmp:log("["||$taskUri||"] at end task", "debug")
    let $_ := prof:disable($req)
    let $dump := prof:report($req)
    let $_ := analyze-prof-dump($dump)
    return $next
};

declare function process-document($uri as xs:string, $goal as xs:string) {
  if (starts-with($uri, "/enhanced")) then
    (: generate ofis record :)
    let $next := gor:generate($uri)
    let $_ := xdmp:log("["||$uri||"] at process document: " || $goal)
    return schedule-task($next, "initial")
  else
    let $tokens := tokenize($uri, "/")
    let $source := $tokens[2]
    let $type := $tokens[3]
    let $personMap := common:load-doc-from-module(concat("/mapping/", $source, "/person.xml"))
    let $_ := xdmp:log("["||$uri||"] at process document: " || $goal)
    return
    if ($type = $personMap/mapping/passportdoc/data()) then
      (: 
       : TODO: if the corresponding person record is a "duplicate" 
       : 1. copy the passport over
       : 2. trigger the task for the primary instead.
       :)
      let $next := process-passport($uri)
      return schedule-task($next, "enhanced")
    else if ($type = $personMap/mapping/rootname/data()) then
      if ($goal = "initial") then
        let $_ := xdmp:log("["||$uri||"] at check map start", "debug")
        let $_ := check-mapping($uri)
        let $_ := xdmp:log("["||$uri||"] at schedule next task", "debug")
        return schedule-task($uri, "enhanced")
      else if ($goal = "enhanced") then
        let $_ := xdmp:log("["||$uri||"] generating enhanced document")
        let $next := ger:generate($uri)
        return schedule-task($next, "initial")
      else
        () (: process person :)
    else
      () (: what do we do with this :)
};

declare %private function process-passport($uri as xs:string) {
  let $source := tokenize($uri, "/")[2]
  let $doc := doc($uri)
  let $mapDoc := common:load-doc-from-module(common:compute-mapping-uri($uri))
  let $personId := $doc//*[node-name() = $mapDoc/mapping/personid/data()]
  let $personUri := concat("/", $source, "/person/", $personId, ".xml")
  let $_ := check-mapping($personUri)
  return $personUri
};

declare %private function check-mapping($uri as xs:string) {
  let $_ := xdmp:log("at check perm-match", "debug")
  let $_ := xdmp:invoke-function(
      function() {gpm:check-mapping($uri)},
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
  let $_ := xdmp:log("at check match", "debug")
  let $_ := xdmp:invoke-function(
      function() {gc:check-mapping($uri)},
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
  let $_ := xdmp:log("at check conflict", "debug")
  return
    xdmp:invoke-function(
      function() {gm:check-mapping($uri, "strict")},
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
};

declare %private function analyze-prof-dump($dump as node()) {
  for $time in $dump//*:shallow-time
  let $dur := seconds-from-duration($time/data()) + 60 * minutes-from-duration($time/data())
  return
    if ($dur > 1) then
      xdmp:log(xdmp:quote($time/..))
    else
      ()
};