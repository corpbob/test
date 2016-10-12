module namespace ofis-common = "http://asti.dost.gov.ph/ofis/common";
declare default function namespace "http://asti.dost.gov.ph/ofis/common";

declare variable $MAPS as map:map := map:map();

declare function remove-null-str($inStr as xs:string?) as xs:string?{
  if (lower-case($inStr) = 'null') then 
    ()
  else
    $inStr
};

declare function process-elem-name($inStr as xs:string?) as xs:string?{
  lower-case($inStr)
};

declare function process-date($inStr as xs:string?) as xs:string? {
  let $inStr := remove-null-str($inStr)
  let $result := 
    (: for now limit the length, consider doing a date parsing. :)
    if (string-length($inStr) >= 10) then
      substring($inStr, 1, 10)
    else
      ()
  return
  (: should we filter 1970-01-01 too? :)
  if ($result = ("1900-01-01")) then
    ()
  else
    $result
};

declare function process-gender($inStr as xs:string?) as xs:string? {
  let $checkStr := lower-case(remove-null-str($inStr))
  return
  (: should we consider 1 and 0's :)
  (: 
   : this is one approach, but we are unnecessarily modifying the data which
   : they might not appreciate
  if ($checkStr = ("f", "female")) then
    "Female"
  else if ($checkStr = ("m", "male")) then
    "Male"
   :)
  if ($checkStr = ("f", "female", "m", "male")) then
    $inStr
  else
    ()
};

declare function process-name($inStr as xs:string?, $allowOneChar as xs:boolean?) as xs:string? {
  let $inStr := replace(remove-null-str($inStr), "[^a-z'\-\s]", "", "i")
  let $tokens := tokenize($inStr, "\s+")
  let $tokens :=
    for $token in $tokens
    let $value := lower-case($token)
    (: 
     : or alternatively, use thesaurus to compare these names/extensions
     : so how do we include a thsr:expand in all-xml.
     : or just use it during the matching/deduping process 
     :)
    return
	  (: 
	   : this is one approach, but we are unnecessarily modifying the data which
	   : they might not appreciate
      if ($value = ("ma", "maria")) then
        "MA"
      else if ($value = ("jr", "junior")) then
        "JR"
      else if ($value = ("sr", "senior")) then
        "SR"
      else if ($allowOneChar and matches($token, "^x{2,}$", "i")) then
        ()
      else if (not($allowOneChar) and matches($token, "^x{1,}$", "i")) then
        ()
      else
       :)
        empty-repeating($token, $allowOneChar)
  return string-join($tokens, " ")
};

declare function empty-repeating($inStr as xs:string?, $allowOneChar as xs:boolean?) as xs:string? {
  let $flag := 
    if ($allowOneChar) then
      "+"
    else
      "*"
  return 
    if (matches($inStr, concat("^(.)\1", $flag, "$"))) then
      ()
    else
      $inStr
};

declare function process-passport($inStr as xs:string?) as xs:string? {
  let $inStr := replace(remove-null-str($inStr), "[^a-z0-9]", "", "i")
  return empty-repeating($inStr, xs:boolean("false"))
};

declare function load-doc-from-module($map-uri as xs:string) as document-node() {
  let $result := map:get($ofis-common:MAPS, $map-uri)
  return 
  if (empty($result)) then
    let $result := load-doc-from-module-direct($map-uri)
    let $_ := map:put($ofis-common:MAPS, $map-uri, $result)
    return $result
  else
    $result
};

declare %private function load-doc-from-module-direct($map-uri as xs:string) as document-node() {
  let $dbName := xdmp:database-name(xdmp:database())
  let $modDb := xdmp:database(replace($dbName, '-content', '-modules'))
  return xdmp:invoke-function(
    function() {
      doc($map-uri)
    }, <options xmlns="xdmp:eval">
    <database>{$modDb}</database>
    <transaction-mode>query</transaction-mode>
  </options>)
};

declare function compute-mapping-uri($docUri as xs:string) as xs:string {
  let $tokens := tokenize($docUri, "/")
  let $tokens := remove($tokens, count($tokens))
  return concat("/mapping", string-join($tokens, "/"), ".xml")
};

declare function compute-directory($docUri as xs:string) as xs:string {
  let $tokens := tokenize($docUri, "/")
  let $tokens := remove($tokens, count($tokens))
  return concat(string-join($tokens, "/"), "/")
};