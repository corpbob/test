module namespace conflict = "http://asti.dost.gov.ph/ofis/mapping/rule/conflict";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/rule/conflict";

import module namespace strict = "http://asti.dost.gov.ph/ofis/mapping/rule/strict"
  at './strict.xqy';
import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-assist"
  at '../map-assist.xqy';
import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
  
declare function build-query($doc as document-node(), $mapDoc as document-node(), $passports as xs:string*) as cts:query? {
  let $passportQuery := build-passport-query($doc, $mapDoc, $passports)
  return
  if (empty($passportQuery)) then
    ()
  else
    cts:and-query((
        $passportQuery,
        cts:not-query(strict:build-query($doc, $mapDoc))
      ))
};

declare %private function build-passport-query($doc as document-node(), $personMap as document-node(), $passports as xs:string+) as cts:query? {
  let $uri := document-uri($doc)
  let $source := mp:get-source($uri)
  return
  if (lower-case($source) = "ofis") then
    cts:element-value-query(xs:QName("passport"), $passports)
  else
    let $passportSrc := $personMap/mapping/passportdoc/data()
    let $passMap := common:load-doc-from-module(concat("/mapping/", $source, "/", $passportSrc, ".xml"))
    let $id := mp:get-id($uri)
    let $query := cts:and-query((
        cts:directory-query(concat("/", $source, "/", $passportSrc, "/")),
        cts:element-value-query(xs:QName($passMap/mapping/passport/data()), $passports),
        cts:not-query(cts:element-value-query(xs:QName($passMap/mapping/personid/data()), $id))
      ))
    let $otherPps := cts:search(/, $query)
    let $otherIds := $otherPps//*[node-name() = $passMap/mapping/personid/data()]/data()
    return
    if (empty($otherPps)) then
      ()
    else
      cts:element-value-query(xs:QName($personMap/mapping/id/data()), $otherIds)
};
