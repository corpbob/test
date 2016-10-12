module namespace generate-conflicts = "http://asti.dost.gov.ph/ofis/mapping/generate-conflicts";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/generate-conflicts";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
import module namespace conflict = "http://asti.dost.gov.ph/ofis/mapping/rule/conflict" 
  at "./rules/conflict.xqy";
import module namespace source = "http://asti.dost.gov.ph/ofis/mapping/rule/source" 
  at './rules/source.xqy';
import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-assist"
  at './map-assist.xqy';

declare function check-mapping (
  $uri as xs:string
)
{
  let $baseDoc := doc($uri)
  let $mapDoc := common:load-doc-from-module(common:compute-mapping-uri($uri))
  let $passports := get-passports($uri, $baseDoc, $mapDoc)
  return
  (: assumes a person record :)
  if (empty($passports)) then
    ()
  else
    let $dir := common:compute-directory($uri)
    let $docId := $baseDoc/person/*[node-name() = $mapDoc/mapping/id/data()]
    let $baseQuery := (cts:directory-query($dir), source:build-query($baseDoc, $mapDoc))
    let $query := conflict:build-query($baseDoc, $mapDoc, $passports)
    return 
    if (empty($query)) then
      ()
    else
      let $matches := cts:search(/, cts:and-query(($query, $baseQuery)))
      for $match in $matches
      let $matchId := $match/person/*[node-name() = $mapDoc/mapping/id/data()]
      return
      if ($docId != $matchId) then 
      (
        create-if-clear(
          concat($dir, $docId, "/"),
          document-uri($match),
          $matchId,
          mp:create-conflict-document(document-uri($match))
        ), create-if-clear(
          concat($dir, $matchId, "/"),
          $uri,
          $docId,
          mp:create-conflict-document($uri)
        )
      )
      else ()
};

(: 
 : main diff from matches:
 : 1. will overwrite matches unless status is permanent/approved.
 : 2. 
 :)
declare %private function create-if-clear($dir as xs:string, $matchUri as xs:string, $matchId as xs:string, $doc as document-node()) {
  let $query := cts:and-query((
      cts:directory-query($dir),
      cts:element-value-query(xs:QName("uri"), $matchUri),
      cts:element-value-query(xs:QName("admin-status"), "APPROVED")
    ))
  let $uri := concat($dir, $matchId, ".xml")
  return
  if (empty(cts:uris("", ("eager", "document"), $query))) then
    xdmp:document-insert($uri, $doc, (), "conflict")
  else
    ()
};

declare %private function get-passports($uri as xs:string, $doc as document-node(), $personMap as document-node()) as xs:string* {
  let $id := mp:get-id($uri)
  let $source := mp:get-source($uri)
  return
  if (lower-case($source) = "ofis") then
    $doc/person/passport[string-length()>1]/data()
  else
    let $passportSrc := $personMap/mapping/passportdoc/data()
    let $passMap := common:load-doc-from-module(concat("/mapping/", $source, "/", $passportSrc, ".xml"))
    let $query := cts:and-query((
      cts:directory-query(concat("/", $source, "/", $personMap/mapping/passportdoc/data(), "/")),
      cts:element-value-query(xs:QName($passMap/mapping/personid/data()), $doc/person/*[node-name() = $personMap/mapping/id/data()]/data()),
      cts:not-query(cts:element-value-query(xs:QName($passMap/mapping/passport/data()), ("", " ")))
    ))
    let $passports := cts:search(/, $query)
    return $passports//*[node-name() = $passMap/mapping/passport/data()][string-length()>1]/text() 
};