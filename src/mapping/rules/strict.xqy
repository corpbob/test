module namespace strict = "http://asti.dost.gov.ph/ofis/mapping/rule/strict";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/rule/strict";

(:
 : Pattern other matching rules to this document. The only public method is build-query.
 :)
declare function build-query($doc as document-node(), $mapDoc as document-node()) as cts:query {
  cts:and-query((
      build-gender-query($doc, $mapDoc/mapping/gender),
      build-name-query($doc, $mapDoc/mapping/first, $mapDoc/mapping/middle, $mapDoc/mapping/last),
      build-dob-query($doc, $mapDoc/mapping/dob),
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
  let $middleName := $doc/person/*[node-name() = $middle/data()]
  let $lastName := $doc/person/*[node-name() = $last/data()]
  let $firstQ := cts:element-value-query(xs:QName($first/data()), ($firstName, tokenize($firstName, "\s+")))
  let $initials := get-initials($middleName)
  let $middleQ := 
    if ($initials = $middleName) then
      (: how do we do reverse match, i.e. initials to long value? :)
      ()
    else
      cts:element-value-query(xs:QName($middle/data()), ($middleName, get-initials($middleName), ""))
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
  return cts:element-value-query(xs:QName($field/data()), ($fieldVal, ""))
};

declare %private function build-id-query($doc as document-node(), $field as node()) as cts:query? {
  let $fieldVal := $doc/person/*[node-name() = $field/data()]
  return cts:not-query(cts:element-value-query(xs:QName($field/data()), ($fieldVal, "")))
};
