module namespace comparison-detail = "http://marklogic.com/rest-api/transform/comparison-detail";
declare default function namespace "http://marklogic.com/rest-api/transform/comparison-detail";

declare function transform (
  $context as map:map,
  $params as map:map,
  $content as document-node()
) as document-node()
{
  let $doc := $content
  let $docUri := map:get($context, "uri")
  (: this is getting very very specific. consider making this configurable. :)
  let $matchDir := concat(substring-before(substring-after($docUri, "/enhanced"), ".xml"), "/")
  let $newDoc := build-revised-doc($doc, $matchDir)
  return $newDoc
};

declare %private function build-revised-doc($doc as document-node(), $dir as xs:string) as document-node(){
  let $result := person-to-json($doc)
  let $person := map:get($result, "person")
  let $_ := ( 
    map:put($person, "permanent-matches", retrieve-permanent-matches($dir)),
    map:put($person, "matches", retrieve-matches($dir)),
    map:put($person, "conflicts", retrieve-conflicts($dir))
    )

  return xdmp:to-json($result)
};

(: declaring function as json:array() is failing :)
declare %private function retrieve-conflicts($dir as xs:string) {
  let $query := cts:and-query((
      cts:directory-query($dir),
      cts:element-value-query(xs:QName("status"), "ACTIVE"),
      cts:collection-query("conflict")
    ))
  let $matches := cts:search(/, $query)
  let $result := json:array()
  let $_ :=
    for $match in $matches
    return json:array-push($result, person-to-json(doc(concat("/enhanced", $match/conflict/uri))))
  return $result
};

declare %private function retrieve-matches($dir as xs:string) {
  let $query := cts:and-query((
      cts:directory-query($dir),
      cts:element-value-query(xs:QName("status"), "ACTIVE"),
      cts:not-query(cts:element-value-query(xs:QName("admin-status"), "APPROVED")),
      cts:collection-query("match")
    ))
  let $matches := cts:search(/, $query)
  let $result := json:array()
  let $_ :=
    for $match in $matches
    return json:array-push($result, person-to-json(doc(concat("/enhanced", $match/match/uri))))
  return $result
};

declare %private function retrieve-permanent-matches($dir as xs:string) {
  let $query := cts:and-query((
      cts:directory-query($dir),
      cts:element-value-query(xs:QName("status"), "ACTIVE"),
      cts:element-value-query(xs:QName("admin-status"), "APPROVED"),
      cts:collection-query("match")
    ))
  let $result := json:array()
  let $matches := cts:search(/, $query)
  let $_ :=
    for $match in $matches
    return json:array-push($result, person-to-json(doc(concat("/enhanced", $match/match/uri))))
  return $result
};

declare %private function person-to-json($doc as document-node()) as map:map {
  let $result := json:object()
  let $person := json:object()
  let $_ :=
    for $prop in $doc/enhanced/*
    return map:put($person, $prop/local-name(), $doc/enhanced/*[node-name() = $prop/node-name()]/data())
  let $_ := map:put($result, "person", $person)
  return $result
};
