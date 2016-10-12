module namespace loose = "http://asti.dost.gov.ph/ofis/mapping/rule/loose";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/rule/loose";

(:
 : Pattern other matching rules to this document. The only public method is build-query.
 :)
declare function build-query($doc as document-node(), $mapDoc as document-node()) as cts:query {
  cts:and-query((
      build-gender-query($doc, $mapDoc/mapping/gender),
      build-name-query($doc, $mapDoc/mapping/first, $mapDoc/mapping/middle, $mapDoc/mapping/last),
      build-id-query($doc, $mapDoc/mapping/id)
    ))
};

declare %private function build-gender-query($doc as document-node(), $field as node()) as cts:query? {
  let $fieldVal := $doc/person/*[node-name() = $field/data()]
  return
    if ($fieldVal = ("F", "FEMALE")) then
      cts:element-value-query(xs:QName($field/data()), ("F", "FEMALE", ""))
    else if ($fieldVal = ("M", "MALE")) then
      cts:element-value-query(xs:QName($field/data()), ("M", "MALE", ""))
    else
      ()
};

declare %private function build-name-query($doc as document-node(), $first as node(), $middle as node(), $last as node()) as cts:query? {
  (: now how do we do the concatenation comparison as an or query :)
  let $firstName := $doc/person/*[node-name() = $first/data()]
  let $lastName := $doc/person/*[node-name() = $last/data()]
  let $firstQ := cts:element-word-query(xs:QName($first/data()), ($firstName, tokenize($firstName, "\s+")))
  let $lastQ := cts:element-value-query(xs:QName($last/data()), $lastName)
  return cts:and-query(($firstQ, $lastQ))
};

declare %private function build-dob-query($doc as document-node(), $field as node()) as cts:query? {
  let $fieldVal := $doc/person/*[node-name() = $field/data()]
  return cts:element-value-query(xs:QName($field/data()), ($fieldVal, ""))
};

declare %private function build-id-query($doc as document-node(), $field as node()) as cts:query? {
  let $fieldVal := $doc/person/*[node-name() = $field/data()]
  return cts:not-query(cts:element-value-query(xs:QName($field/data()), ($fieldVal, "")))
};
