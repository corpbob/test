module namespace generate-enhanced-record = "http://asti.dost.gov.ph/ofis/mapping/generate-enhanced-record";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/generate-enhanced-record";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
  
import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-assist"
  at './map-assist.xqy';
  
declare function generate (
  $uri as xs:string
) as xs:string
{
  let $baseDoc := doc($uri)
  let $_ := xdmp:log("["||$uri||"] generating enhanced doc: " || xdmp:quote($baseDoc), "debug")
  let $mapDoc := common:load-doc-from-module(common:compute-mapping-uri($uri))
  let $dir := common:compute-directory($uri)
  let $docId := $baseDoc/person/*[node-name() = $mapDoc/mapping/id/data()]
  let $enhancedUri := concat("/enhanced", $uri)
  let $enhanced := build-enhanced-doc($baseDoc, $dir, $docId, $uri, $mapDoc)
  let $_ := xdmp:log("["||$uri||"] generated enhanced doc: " || $enhancedUri ||" -- "|| xdmp:quote($baseDoc), "debug")
  return (xdmp:document-insert($enhancedUri, $enhanced), $enhancedUri)[1]
};

declare %private function get-match-count($dir as xs:string, $id as xs:string) as node(){
  let $query := cts:and-query((
      cts:directory-query(concat($dir, $id, "/")),
      cts:element-value-query(xs:QName("status"), "ACTIVE"),
      cts:not-query(cts:element-value-query(xs:QName("admin-status"), "APPROVED")),
      cts:collection-query("match")
    ))
  return <match-count>{xdmp:estimate(cts:search(/, $query))}</match-count>
};

declare %private function get-perm-match-count($dir as xs:string, $id as xs:string) as node(){
  let $query := cts:and-query((
      cts:directory-query(concat($dir, $id, "/")),
      cts:element-value-query(xs:QName("status"), "ACTIVE"),
      cts:element-value-query(xs:QName("admin-status"), "APPROVED"),
      cts:collection-query("match")
    ))
  return <perm-match-count>{xdmp:estimate(cts:search(/, $query))}</perm-match-count>
};

declare %private function get-conflict-count($dir as xs:string, $id as xs:string) as node(){
  let $query := cts:and-query((
      cts:directory-query(concat($dir, $id, "/")),
      cts:element-value-query(xs:QName("status"), "ACTIVE"),
      cts:collection-query("conflict")
    ))
  return <conflict-count>{xdmp:estimate(cts:search(/, $query))}</conflict-count>
};

declare %private function build-enhanced-doc($doc as document-node(), 
    $dir as xs:string, $docId as xs:string,
    $uri as xs:string, $mapDoc as document-node()
  ) as document-node(){
  document {
    <enhanced>
      <baseUri>{$uri}</baseUri>
      {
        for $field in $mapDoc/mapping/*
        return
        for $prop in $doc/person/*[node-name() = $field/data()]
        return element {$field/node-name()} {upper-case($prop/data())}
      }
      {
        get-perm-match-count($dir, $docId)
      }
      {
        get-match-count($dir, $docId)
      }
      {
        get-conflict-count($dir, $docId)
      }
      {
        get-passport-elems($uri, $doc, $mapDoc)
      }
      <ofis-status>{ mp:get-ofis-status($uri) }</ofis-status>
    </enhanced>
  }
};

declare %private function get-passport-elems($uri as xs:string, $doc as document-node(), $personMap as document-node()) as node()*{
  for $passport in get-passports($uri, $doc, $personMap)
  return <passport>{$passport}</passport>
};

declare %private function get-passports($uri as xs:string, $doc as document-node(), $personMap as document-node()) as xs:string* {
  let $id := mp:get-id($uri)
  let $source := mp:get-source($uri)
  return
  if (lower-case($source) = "ofis") then
    (: it already got transferred :)
    ()
  else
    let $passportSrc := $personMap/mapping/passportdoc/data()
    let $passMap := common:load-doc-from-module(concat("/mapping/", $source, "/", $passportSrc, ".xml"))
    let $query := cts:and-query((
      cts:directory-query(concat("/", $source, "/", $personMap/mapping/passportdoc/data(), "/")),
      cts:element-value-query(xs:QName($passMap/mapping/personid/data()), $doc/person/*[node-name() = $personMap/mapping/id/data()]/data()),
      cts:not-query(cts:element-value-query(xs:QName($passMap/mapping/passport/data()), ("", " ")))
    ))
    let $passports := cts:search(/, $query)
    return distinct-values($passports//*[node-name() = $passMap/mapping/passport/data()][string-length()>1]/data()) 
};