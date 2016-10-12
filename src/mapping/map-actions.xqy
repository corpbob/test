module namespace map-records = "http://asti.dost.gov.ph/ofis/mapping/map-actions";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/map-actions";

import module namespace cpf = "http://marklogic.com/cpf" 
  at "/MarkLogic/cpf/cpf.xqy";
import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-assist"
  at './map-assist.xqy';
import module namespace rec-dedup = "http://asti.dost.gov.ph/ofis/mapping/record-dedupe"
  at './record-dedupe.xqy';
import module namespace rec-match = "http://asti.dost.gov.ph/ofis/mapping/record-match"
  at './record-match.xqy';
  
declare function declare-as-perm-match (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $source := mp:get-source($primaryUri)
  return
  if ($source = "ofis") then
    rec-match:declare-as-perm-match($primaryUri, $secondaryUri)
  else
    rec-dedup:declare-as-perm-match($primaryUri, $secondaryUri)
};

declare function break-perm-match (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $primaryId := mp:get-id($primaryUri) 
  let $secondaryId := mp:get-id($secondaryUri)
  let $source := mp:get-source($primaryUri)
  let $secSrc := mp:get-source($secondaryUri)
  let $_ :=
    if ($source = $secSrc) then
      ()
    else
      (: this should not be. but just in case :)
      error(xs:QName("ERROR"), "Source mismatch. primary: " || $source || ", secondary: " || $secSrc)
  return if ($source = "ofis") then
    rec-match:break-perm-match($primaryUri, $secondaryUri)
  else
    rec-dedup:break-perm-match($primaryUri, $secondaryUri)
    
};
