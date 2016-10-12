module namespace generate-perm-matches = "http://asti.dost.gov.ph/ofis/mapping/generate-perm-matches";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/generate-perm-matches";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
import module namespace exact = "http://asti.dost.gov.ph/ofis/mapping/rule/exact" 
  at "./rules/exact.xqy";
import module namespace source = "http://asti.dost.gov.ph/ofis/mapping/rule/source" 
  at './rules/source.xqy';
import module namespace mactions = "http://asti.dost.gov.ph/ofis/mapping/map-actions"
  at './map-actions.xqy';
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
    let $baseQuery := (cts:directory-query($dir), source:build-query($baseDoc, $mapDoc))
    let $query := exact:build-query($baseDoc, $mapDoc, $passports)
    return 
    if (empty($query)) then
      ()
    else
      let $matches := cts:search(/, cts:and-query(($query, $baseQuery)))
      for $match in $matches
      return mactions:declare-as-perm-match($uri, document-uri($match))
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