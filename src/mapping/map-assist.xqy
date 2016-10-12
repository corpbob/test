module namespace map-assist = "http://asti.dost.gov.ph/ofis/mapping/map-assist";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/map-assist";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
  
declare function create-perm-match-document($uri as xs:string) as document-node(){
  document { 
    <match>
      <uri>{$uri}</uri>
      <status>ACTIVE</status>
      <admin-status>APPROVED</admin-status>
      <date>{fn:format-dateTime(fn:current-dateTime(), "[Y0001]-[M01]-[D01] [H01]:[m01]:[s01]:[f01]")}</date>
    </match>
  }
};

declare function create-match-document($uri as xs:string) as document-node(){
  document { 
    <match>
      <uri>{$uri}</uri>
      <status>ACTIVE</status>
      <date>{fn:format-dateTime(fn:current-dateTime(), "[Y0001]-[M01]-[D01] [H01]:[m01]:[s01]:[f01]")}</date>
    </match>
  }
};

declare function create-conflict-document($uri as xs:string) as document-node(){
  document { 
    <conflict>
      <uri>{$uri}</uri>
      <status>ACTIVE</status>
      <date>{fn:format-dateTime(fn:current-dateTime(), "[Y0001]-[M01]-[D01] [H01]:[m01]:[s01]:[f01]")}</date>
    </conflict>
  }
};

declare function delete-if-exist($uri as xs:string) {
  if (empty(doc($uri))) then
    ()
  else
    xdmp:document-delete($uri)
};

(: force-overwrite :)
declare function create-overwrite($uri as xs:string, $doc as document-node()) {
  xdmp:document-insert($uri, $doc, (), "match")
};

(: assumes a person uri :)
declare function get-ofis-status($uri as xs:string) as xs:string {
  let $source := get-source($uri)
  let $id := get-id($uri)
  let $result := (
    doc(concat("/", $source, "/person/", $id, "/status", ".xml"))/ofis/status/data()
    ,"UNIQUE"
    )[1]
  return $result
};

declare function get-source($uri as xs:string) as xs:string {
  if (starts-with($uri, "/enhanced")) then
    tokenize($uri, "/")[3]
  else
    tokenize($uri, "/")[2]
};

declare function get-id($uri as xs:string) as xs:string {
  let $tokens := tokenize($uri, "[/.]")
  return $tokens[count($tokens) - 1]
};

declare function get-passports($uri as xs:string, $doc as document-node(), $personMap as document-node()) as document-node()* {
  let $id := get-id($uri)
  let $source := get-source($uri)
  return
  if (lower-case($source) = "ofis") then
    $doc/person/passport[string-length()>1]/data()
  else
    let $passportSrc := $personMap/mapping/passportdoc/data()
    let $passMap := common:load-doc-from-module(concat("/mapping/", $source, "/", $passportSrc, ".xml"))
    let $query := cts:and-query((
      cts:directory-query(concat("/", $source, "/", $personMap/mapping/passportdoc/data(), "/")),
      cts:element-value-query(xs:QName($passMap/mapping/personid/data()), $doc/person/*[node-name() = $personMap/mapping/id/data()]/data())
    ))
    return cts:search(/, $query)
};