module namespace check-passport = "http://asti.dost.gov.ph/ofis/mapping/check-passport";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/check-passport";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" 
  at '/transform/common.xqy';
import module namespace cpf = "http://marklogic.com/cpf" 
  at "/MarkLogic/cpf/cpf.xqy";

(: assumes a passport/travel uri:)
declare function check-mapping (
  $uri as xs:string
)
{
  let $source := tokenize($uri, "/")[2]
  let $doc := doc($uri)
  let $mapDoc := common:load-doc-from-module(common:compute-mapping-uri($uri))
  let $personId := $doc//*[node-name() = $mapDoc/mapping/personid/data()]
  (: 
   : assumptions:
   : 1. foreign key is id and is used as part of the uri
   : 2. passport/travel record only maps to a single person. 
   :)
  let $personUri := concat("/", $source, "/person/", $personId, ".xml")
  return cpf:document-set-processing-status($personUri, "updated")
};