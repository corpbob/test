module namespace basic = "http://asti.dost.gov.ph/ofis/basic";
declare default function namespace "http://asti.dost.gov.ph/ofis/basic";

import module namespace common = "http://asti.dost.gov.ph/ofis/common" at './common.xqy';

declare function transform (
  $mappingUri as xs:string,
  $doc as document-node()
) as document-node()
{
  let $mapDoc := common:load-doc-from-module($mappingUri)
  let $rootName := $mapDoc/mapping/rootname/data()
  let $newDoc := process-document($rootName, $doc, $mapDoc)
  return $newDoc
};

declare %private function process-document($node-name as xs:string, $doc as document-node(), $mapDoc as document-node()) as document-node() {
  let $root := $doc/element()
  let $children :=
    for $item in $doc/root/*
    let $nodeName := local-name-from-QName(node-name($item))
    let $nodeValue :=
      if ($mapDoc/mapping/dob/data() = $item/node-name()) then
        common:process-date(data($item)) 
      else if ($mapDoc/mapping/gender/data() = $item/node-name()) then
        common:process-gender(data($item)) 
      else if ($mapDoc/mapping/passport/data() = $item/node-name()) then
        common:process-passport(data($item)) 
      else if (
          $mapDoc/mapping/first/data() = $item/node-name()
          or $mapDoc/mapping/middle/data() = $item/node-name()
          or $mapDoc/mapping/last/data() = $item/node-name()
        ) then
        common:process-name(data($item), ($mapDoc/mapping/middle/data() = $item/node-name()))
      else 
        common:remove-null-str(data($item))  
    return element {$nodeName} {$nodeValue}
  return document {element {$node-name} {$children}}
};