module namespace denormalize-record = "http://asti.dost.gov.ph/ofis/mapping/denormalize-record";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/denormalize-record";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';

(: assumes a person uri :)
declare function denormalize (
  $uri as xs:string
)
{
  (: assumes a structure of /<source>/person/1.xml :)
  let $source := tokenize($uri, "/")[2]
  return
  if (lower-case($source) = "ofis") then
    ()
  else
    process-doc($uri)
};

declare %private function process-doc($uri as xs:string) {
  let $doc := doc($uri)
  let $mapDoc := common:load-doc-from-module(common:compute-mapping-uri($uri))
  let $passports := build-passport-elems($uri, $doc, $mapDoc)
  let $existing := $doc/person/passport
  return
  if (compare-passport-list($passports, $existing)) then
    ()
  else
    (: this will cause update and potentially cause a cyclic event. :)
    let $normalized := build-normalized-doc($doc, $passports)
    return xdmp:document-insert($uri, $normalized)
};

declare %private function build-normalized-doc($doc as document-node(), 
    $passports as node()*
  ) as document-node(){
  document {
    <person>
      {
        (: this assumes that the root is person. might be a bad idea. :)
        for $field in $doc/person/*
        return
        if ($field/local-name() = "passport") then
          (: ignore, will add later :)
          ()
        else
          element {$field/node-name()} {$field/data()}
      }
      {
        $passports
      }
    </person>
  }
};

declare %private function build-passport-elems($uri as xs:string, $doc as document-node(), $personMap as document-node()) as node()* {
  let $source := tokenize($uri, "/")[2]
  let $passportSrc := $personMap/mapping/passportdoc/data()
  return
    if (empty($passportSrc)) then
      ()
    else
    let $passMap := common:load-doc-from-module(concat("/mapping/", $source, "/", $passportSrc, ".xml"))
    let $passportDir := concat("/", $source, "/", $passportSrc, "/")
    let $personId := $doc/person/*[node-name() = $personMap/mapping/id/data()]
    for $passport in get-passports($passportDir, $passMap , $personId)
    return element {"passport"} {$passport//*[node-name() = $passMap/mapping/passport/data()]/data()}
};

declare %private function get-passports($passportDir as xs:string, $passportMap as document-node(), $personId as xs:string) as document-node()* {
  let $personFk := $passportMap/mapping/personid/data()
  let $query := cts:and-query((
      cts:directory-query($passportDir),
      cts:element-value-query(xs:QName($personFk), $personId)
    ))
  return cts:search(/, $query)
};

(: this assumes passport nodes :)
declare %private function compare-passport-list($l1 as node()*, $l2 as node()*) as xs:boolean{
  let $result := empty($l1) and empty($l2) or not(empty($l1)) and not(empty($l2))
  
  let $check :=
    for $entry in $l1
    return cts:contains($l2, $entry/data())
  let $result := $result and empty(index-of($check, false()))
  
  let $check :=
    for $entry in $l2
    return cts:contains($l1, $entry/data())
  let $result := $result and empty(index-of($check, false()))
  
  return $result
};
