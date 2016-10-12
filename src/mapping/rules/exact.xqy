module namespace strict = "http://asti.dost.gov.ph/ofis/mapping/rule/exact";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/rule/exact";

import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-assist"
  at '../map-assist.xqy';
import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
  
(:
 : Pattern other matching rules to this document. The only public method is build-query.
 :)
declare function build-query($doc as document-node(), $mapDoc as document-node(), $passports as xs:string*) as cts:query? {
  let $passportQuery := build-passport-query($doc, $mapDoc, $passports)
  return
  if (empty($passportQuery)) then
    ()
  else
    cts:and-query((
        build-gender-query($doc, $mapDoc/mapping/gender),
        build-name-query($doc, $mapDoc/mapping/first, $mapDoc/mapping/middle, $mapDoc/mapping/last),
        build-dob-query($doc, $mapDoc/mapping/dob),
        $passportQuery,
        build-id-query($doc, $mapDoc/mapping/id)
      ))
};

declare %private function build-gender-query($doc as document-node(), $field as node()) as cts:query? {
  let $fieldVal := $doc/person/*[node-name() = $field/data()]
  return
    if ($fieldVal = ("F", "FEMALE")) then
      cts:element-value-query(xs:QName($field/data()), ("F", "FEMALE"))
    else if ($fieldVal = ("M", "MALE")) then
      cts:element-value-query(xs:QName($field/data()), ("M", "MALE"))
    else
      ()
};

declare %private function build-name-query($doc as document-node(), $first as node(), $middle as node(), $last as node()) as cts:query? {
  (: now how do we do the concatenation comparison as an or query :)
  let $firstName := $doc/person/*[node-name() = $first/data()]
  let $middleName := $doc/person/*[node-name() = $middle/data()]
  let $lastName := $doc/person/*[node-name() = $last/data()]
  let $firstQ := cts:element-value-query(xs:QName($first/data()), $firstName)
  let $initials := get-initials($middleName)
  let $middleQ := 
    if ($initials = $middleName) then
      (: how do we do reverse match, i.e. initials to long value? :)
      ()
    else
      cts:element-value-query(xs:QName($middle/data()), ($middleName, get-initials($middleName)))
  let $lastQ := cts:element-value-query(xs:QName($last/data()), $lastName)
  return cts:and-query(($firstQ, $middleQ, $lastQ))
};

declare %private function get-initials($inStr as xs:string?) as xs:string? {
  let $tokens := tokenize($inStr, "\s+")
  let $tokens :=
    for $token in $tokens
    return substring($token, 1, 1)
  return string-join($tokens, " ")
};

declare %private function build-dob-query($doc as document-node(), $field as node()) as cts:query? {
  let $fieldVal := $doc/person/*[node-name() = $field/data()]
  return cts:element-value-query(xs:QName($field/data()), $fieldVal)
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

declare %private function build-id-query($doc as document-node(), $field as node()) as cts:query? {
  let $fieldVal := $doc/person/*[node-name() = $field/data()]
  return cts:not-query(cts:element-value-query(xs:QName($field/data()), ($fieldVal, "")))
};
