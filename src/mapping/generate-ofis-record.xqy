module namespace generate-ofis-record = "http://asti.dost.gov.ph/ofis/mapping/generate-ofis-record";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/generate-ofis-record";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
(:
 : This will assume the following
 : 1. it is processing a record with root <enhanced>
 : 2. record would have <baseUri>
 : 3. ofis records would have <source> of OFIS.
 : 4. the structure of enhanced is fixed. considering the depth and redundancy, not repeating.
 :)
declare function generate (
  $uri as xs:string
) as xs:string?
{
  let $baseDoc := doc($uri)
  let $ofisUri := generate-ofis-uri($uri)
  (: seems a bit round about to achieve this :)
  let $ofisId := substring-before(substring-after($ofisUri, "/ofis/person/"), ".xml")
  (: this assumes structure of /enhanced/<source>/person/1.xml :)
  let $source := upper-case(substring-before(substring-after($uri, "/enhanced/"), "/person"))
  return
  if ($source = "OFIS") then
    (: nothing to do, do not generate OFIS for OFIS :)
    ()
  else if ($baseDoc/enhanced/ofis-status/data() != "UNIQUE") then
    (: delete the record if it exists :)
    (
      delete-if-exist($ofisUri),
      delete-if-exist(concat("/enhanced", $ofisUri))
    )
  else
    (: non-OFIS, create one. :)
    let $mapDoc := common:load-doc-from-module(common:compute-mapping-uri($ofisUri))
    let $ofisDoc := build-ofis-doc($baseDoc, $mapDoc, $ofisId, $source, $uri)
    return (xdmp:document-insert($ofisUri, $ofisDoc), $ofisUri)[1]
};

declare %private function build-ofis-doc(
    $doc as document-node(), 
    $mapDoc as document-node(),
    $id as xs:string,
    $source as xs:string,
    $rawUri as xs:string
) as document-node() {
  document {
  <person>
    <id>{$id}</id>
    <source>{$source}</source>
    <rawuri>{$rawUri}</rawuri>
    {
      for $field in $mapDoc/mapping/*
      return
        if (local-name-from-QName($field/node-name()) = "id") then
          ()
        else
          for $prop in $doc/enhanced/*[node-name() = $field/data()]
          return element {$field/node-name()} {$prop/data()}
    }
  </person>
  }
};

declare %private function generate-ofis-uri($uri) as xs:string {
  let $query := cts:and-query((
      cts:directory-query("/ofis/person/"),
      cts:element-value-query(xs:QName("rawuri"), $uri)
    ))
  let $matches := cts:uris("", ("eager", "document"), $query)
  return
  if (empty($matches)) then
    concat("/ofis/person/", sem:uuid-string(), ".xml")
  else 
    $matches[1]
};

declare %private function delete-if-exist($uri) {
  if (empty(doc($uri))) then
    ()
  else
    xdmp:document-delete($uri)
};