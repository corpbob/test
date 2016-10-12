module namespace generate-matches = "http://asti.dost.gov.ph/ofis/mapping/generate-matches";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/generate-matches";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
import module namespace strict = "http://asti.dost.gov.ph/ofis/mapping/rule/strict" 
  at "./rules/strict.xqy";
import module namespace loose = "http://asti.dost.gov.ph/ofis/mapping/rule/loose" 
  at "./rules/loose.xqy";
import module namespace source = "http://asti.dost.gov.ph/ofis/mapping/rule/source" 
  at './rules/source.xqy';
import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-assist"
  at './map-assist.xqy';

declare function check-mapping (
  $uri as xs:string,
  $level as xs:string
)
{
  let $baseDoc := doc($uri)
  let $mapDoc := common:load-doc-from-module(common:compute-mapping-uri($uri))
  let $dir := common:compute-directory($uri)
  let $docId := $baseDoc/person/*[node-name() = $mapDoc/mapping/id/data()]
  let $baseQuery := (cts:directory-query($dir), source:build-query($baseDoc, $mapDoc))
  let $query := 
    if ($level = "strict") then
      strict:build-query($baseDoc, $mapDoc)
    else if ($level = "loose") then
      loose:build-query($baseDoc, $mapDoc)
    else
      ()
  let $matches := 
    if (empty($query)) then
      ()
    else
      cts:search(/, cts:and-query(($query, $baseQuery)))
  for $match in $matches
  let $matchId := $match/person/*[node-name() = $mapDoc/mapping/id/data()]
  (: 
   : TODO: consider clearing other match records for this doc
   : but even that has a catch, you could hit conflicting updates. 
   :)
  return
  if ($docId != $matchId) then 
  (
    create-if-clear(
      concat($dir, $docId, "/", $matchId, ".xml"),
      mp:create-match-document(document-uri($match))
    ), create-if-clear(
      concat($dir, $matchId, "/", $docId, ".xml"),
      mp:create-match-document($uri)
    )
  )
  else ()
};

declare %private function create-if-clear($uri as xs:string, $doc as document-node()) {
  if (empty(doc($uri))) then
    xdmp:document-insert($uri, $doc, (), "match")
  else
    ()
};