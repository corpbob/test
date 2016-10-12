module namespace strict = "http://asti.dost.gov.ph/ofis/mapping/rule/source";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/rule/source";

declare function build-query($doc as document-node(), $mapDoc as document-node()) as cts:query? {
  if (empty($mapDoc/mapping/source)) then
    ()
  else
    build-source-query($doc, $mapDoc/mapping/source)
};

declare %private function build-source-query($doc as document-node(), $field as node()) as cts:query? {
  let $fieldVal := $doc/person/*[node-name() = $field/data()]
  return cts:not-query(cts:element-value-query(xs:QName($field/data()), ($fieldVal, "")))
};
