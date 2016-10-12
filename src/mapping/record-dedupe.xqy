module namespace record-dedupe = "http://asti.dost.gov.ph/ofis/mapping/record-dedupe";
declare default function namespace "http://asti.dost.gov.ph/ofis/mapping/record-dedupe";

import module namespace common = "http://asti.dost.gov.ph/ofis/common"
  at '/transform/common.xqy';
import module namespace mp = "http://asti.dost.gov.ph/ofis/mapping/map-assist"
  at './map-assist.xqy';
import module namespace tasks = "http://asti.dost.gov.ph/ofis/tasks/manager"
  at '/tasks/task-manager.xqy';

(:
 : The focus is to do a dedup.
 : Raw records need to be kept, and at the same time a merge record to handle everything
 :)

declare function declare-as-perm-match (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $tasks := xdmp:invoke-function(
      function() {merge-internal($primaryUri, $secondaryUri)},
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
  for $task in $tasks
  return tasks:process-task-chain($task)
};

declare function break-perm-match (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $tasks := xdmp:invoke-function(
      function() {break-internal($primaryUri, $secondaryUri)},
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
  for $task in $tasks
  return tasks:process-task-chain($task)
};

declare %private function break-internal (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  (:
   : first find the merge doc
   :)
  let $main := get-merge-doc($primaryUri, $secondaryUri)
  (:
   : break the link between merge doc and selected/applicable dependents
   : delete applicable passport records
   :)
  let $_ := xdmp:log("[break-internal] scheduling: " || $main)
  let $result := (
      (
        if ($main = $primaryUri) then
          ()
        else
          break-mapping($main, $primaryUri)
      )
      ,
      (
        if ($main = $secondaryUri) then
          ()
        else
          break-mapping($main, $secondaryUri)
      )
      ,
      tasks:schedule-task($main, "initial")
    )
  (:
   : if only one dependent remains, break that too
   : discard the merge doc if no dependent remains
   :)
  let $remaining := find-remaining-dependents($main, $primaryUri, $secondaryUri)
  let $_ := xdmp:log("["||$main||"] remaining: ("||count($remaining)||")" || xdmp:quote($remaining))
  let $_ :=
  if (count($remaining) = 1) then
    break-mapping($main, $remaining[1])
  else ()
  let $_ :=
  if (count($remaining) <= 1) then
    delete-merge-doc($main)
  else ()
  return $result
};

declare %private function merge-internal (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  if (check-status($primaryUri, $secondaryUri)) then
    (: only applicable to unique records :)
    let $main := get-merge-doc($primaryUri, $secondaryUri)
    let $_ := merge-validation($primaryUri, $secondaryUri)
    let $_ := xdmp:log("[merge-internal] scheduling: " || $main)
    return (
      (
        if ($main = $primaryUri) then
          ()
        else
          record-mapping($main, $primaryUri)
      )
      ,
      (
        if ($main = $secondaryUri) then
          ()
        else
          record-mapping($main, $secondaryUri)
      )
      ,
      tasks:schedule-task($main, "initial")
    )
  else
    ()
};

declare %private function get-merge-doc(
  $primaryUri as xs:string,
  $secondaryUri as xs:string
) as xs:string {
  (: this info will/should not be carried over by generate-enhanced. :)
  if (not(empty(doc($primaryUri)//ofis-merge-status/data()))) then
    $primaryUri
  else if (not(empty(doc($secondaryUri)//ofis-merge-status/data()))) then
    $secondaryUri
  else
    let $mergeUri := find-potential-merge-doc($primaryUri, $secondaryUri)
    return
    if (empty($mergeUri)) then
      create-merge-doc($primaryUri, $secondaryUri)
    else
      $mergeUri
};

declare %private function find-potential-merge-doc(
  $primaryUri as xs:string,
  $secondaryUri as xs:string
) {
  let $matchUris := cts:uris("", ("document","eager"), cts:and-query((
    cts:element-query(xs:QName("match"), cts:and-query(()))
    , cts:or-query((
      cts:element-value-query(xs:QName("uri"), $primaryUri),
      cts:element-value-query(xs:QName("uri"), $secondaryUri)
    ))
  )))
  let $_ := xdmp:log("["||$primaryUri||","||$secondaryUri||"] checking for merge doc: " || xdmp:quote($matchUris))
  return
  if (empty($matchUris)) then
    (: if this is empty, return empty :)
    ()
  else
    let $personMap := common:load-doc-from-module(common:compute-mapping-uri($primaryUri))
    let $idQuery :=
      for $matchUri in $matchUris
      let $tokens := tokenize($matchUri, "/")
      (:load mapping file:)
      return cts:element-value-query(xs:QName($personMap/mapping/id/data()), $tokens[4])
    let $source := mp:get-source($primaryUri)
    let $dirQ := cts:directory-query(concat("/", $source, "/person/"))
    let $flagQ := cts:element-value-query(xs:QName("ofis-merge-status"), "MERGE")
    let $query := cts:and-query((
      $dirQ, $flagQ, cts:or-query($idQuery)
    ))
    let $_ := xdmp:log("merge doc q: " || $query)
    let $result := cts:uris("", ("document","eager"), $query)[1]
    let $_ := xdmp:log("merge doc result: " || $result)
    return $result
};

declare %private function create-merge-doc(
  $primaryUri as xs:string,
  $secondaryUri as xs:string
) as xs:string {
  let $source := mp:get-source($primaryUri)
  let $id := sem:uuid-string()
  let $uri := concat("/", $source, "/person/", $id, ".xml")
  let $personMap := common:load-doc-from-module(common:compute-mapping-uri($primaryUri))
  return (xdmp:document-insert($uri,
    build-merge-doc(
      doc($primaryUri),
      doc($secondaryUri),
      $personMap,
      $id
    )
  ), $uri)[1]
};

declare %private function build-merge-doc(
  $primary as document-node(),
  $secondary as document-node(),
  $personMap as document-node(),
  $id as xs:string
) as document-node() {
  document {
    <person>
    {
      for $field in $primary/person/*
      return
      if ($field/node-name() = $personMap/mapping/id/data()) then
        element {$field/node-name()} {$id}
      else
        element {$field/node-name()} {get-longer($field/data(), $secondary/person/*[node-name() = $field/node-name()])}
    }
      <ofis-merge-status>MERGE</ofis-merge-status>
    </person>
  }
};

declare %private function get-longer(
  $first as xs:string,
  $second as xs:string
) as xs:string {
  if (string-length($first) >= string-length($second)) then
    $first
  else
    $second
};

declare %private function record-mapping (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $source := mp:get-source($primaryUri)
  let $primaryId := mp:get-id($secondaryUri)
  let $secondaryId := mp:get-id($secondaryUri)
  let $personMap := common:load-doc-from-module(common:compute-mapping-uri($primaryUri))
  let $_ :=
  (
    create-mapping-document($primaryUri, $secondaryUri),
    xdmp:document-insert(
      concat("/", $source, "/person/", $secondaryId, "/status.xml"),
      (: add more info as needed :)
      <ofis><status>DUPLICATE</status></ofis>
    )
    , copy-passports (
      $primaryUri,
      $primaryId,
      $secondaryUri,
      doc($secondaryUri),
      $personMap
    )
  )
  (: make sure above is done first before scheduling anything :)
  let $_ := xdmp:log("[record-mapping] scheduling: " || $secondaryUri)
  return tasks:schedule-task($secondaryUri, "initial")
};

declare %private function check-status (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
) as xs:boolean
{
  let $priStat := mp:get-ofis-status($primaryUri)
  let $secStat := mp:get-ofis-status($secondaryUri)
  let $result := "UNIQUE" = $priStat and "UNIQUE" = $secStat
  return $result
};

declare %private function create-mapping-document (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $secDoc := doc($secondaryUri)
  return
  if (not(empty($secDoc/person/ofis-merge-status))) then
    let $_ := xdmp:log("transferring mapping docs: ", "debug")
    return
    transfer-mapping-document($primaryUri, $secondaryUri)
  else
    let $source := mp:get-source($primaryUri)
    let $primaryId := mp:get-id($primaryUri)
    let $secondaryId := mp:get-id($secondaryUri)
    let $_ := xdmp:log("creating mapping docs: ", "debug")
    return (
      (: update matching documents' admin-status :)
      mp:create-overwrite(
        concat("/", $source, "/person/", $primaryId, "/", $secondaryId, ".xml"),
        mp:create-perm-match-document($secondaryUri)
        ),
      mp:create-overwrite(
        concat("/", $source, "/person/", $secondaryId, "/", $primaryId, ".xml"),
        mp:create-perm-match-document($primaryUri)
        )
    )
};

declare %private function transfer-mapping-document (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $source := mp:get-source($primaryUri)
  let $secondaryId := mp:get-id($secondaryUri)
  let $dir := concat("/", $source, "/person/", $secondaryId, "/")
  for $doc in cts:search(/, cts:directory-query($dir))
  let $matchUri := $doc/match/uri/data()
  return
  if (empty($matchUri)) then
    ()
  else
    create-mapping-document($primaryUri, $matchUri)
};

declare %private function merge-validation (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $source := mp:get-source($primaryUri)
  let $secSrc := mp:get-source($secondaryUri)
  let $primaryStat := mp:get-ofis-status($primaryUri)
  let $secondaryStat := mp:get-ofis-status($secondaryUri)

  (: just a couple of validations :)
  let $_ :=
    if (not("UNIQUE" = ($primaryStat, $secondaryStat))) then
      xdmp:log("Both documents are duplicates.", "debug")
    else
      ()
  return
    if ($source = $secSrc) then
      ()
    else
      (: this should not be. but just in case :)
      error(xs:QName("ERROR"), "Source mismatch. primary: " || $source || ", secondary: " || $secSrc)
};

declare %private function copy-passports (
  $primaryUri as xs:string,
  $primaryId as xs:string,
  $secondaryUri as xs:string,
  $secondaryDoc as document-node(),
  $personMap as document-node()
)
{
  let $primaryId := mp:get-id($primaryUri)
  let $source := mp:get-source($primaryUri)
  let $passMapUri := concat("/mapping/", $source, "/", $personMap/mapping/passportdoc/data(), ".xml")
  let $passDir :=  concat("/", $source, "/", $personMap/mapping/passportdoc/data(), "/")
  let $passMap := common:load-doc-from-module($passMapUri)
  for $passport in mp:get-passports($secondaryUri, $secondaryDoc, $personMap)
  return xdmp:document-insert(concat($passDir, sem:uuid-string(), ".xml"),
    build-copy-passport($primaryId, $passport, $passMap, $secondaryUri))
};

declare %private function build-copy-passport (
  $primaryId as xs:string,
  $passport as document-node(),
  $passMap as document-node(),
  $secondaryUri as xs:string
)
{
  let $root := $passMap/mapping/rootname/data()
  return document {
    element {$root} {
      (
        (
          for $elem in $passport/*[node-name() = $root]/*
          return
            if ($elem/local-name() = $passMap/mapping/personid/data()) then
              (
                element {$elem/node-name()} {$primaryId},
                element {concat("orig_", $elem/node-name())} {$elem/data()}
              )
            else
              element {$elem/node-name()} {$elem/data()}
        )
        ,
        <rawsrc>{document-uri($passport)}</rawsrc>
        ,
        <merge-person-uri>{$secondaryUri}</merge-person-uri>
      )
    }
  }
};

declare %private function break-mapping (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
  let $source := mp:get-source($primaryUri)
  let $primaryId := mp:get-id($secondaryUri)
  let $secondaryId := mp:get-id($secondaryUri)
  let $personMap := common:load-doc-from-module(common:compute-mapping-uri($primaryUri))
  let $_ :=
  (
    break-mapping-document($primaryUri, $secondaryUri),
    xdmp:document-delete(
      concat("/", $source, "/person/", $secondaryId, "/status.xml")
    )
    , delete-imported-passports (
      $primaryUri,
      $secondaryUri,
      $personMap
    )
  )
  (: make sure above is done first before scheduling anything :)
  let $_ := xdmp:log("[break-mapping] scheduling: " || $secondaryUri)
  return tasks:schedule-task($secondaryUri, "initial")
};

declare %private function break-mapping-document (
  $primaryUri as xs:string,
  $secondaryUri as xs:string
)
{
    let $source := mp:get-source($primaryUri)
    let $primaryId := mp:get-id($primaryUri)
    let $secondaryId := mp:get-id($secondaryUri)
    return (
      (: update matching documents' admin-status :)
      xdmp:document-delete(
        concat("/", $source, "/person/", $primaryId, "/", $secondaryId, ".xml")
        ),
      xdmp:document-delete(
        concat("/", $source, "/person/", $secondaryId, "/", $primaryId, ".xml")
        )
    )
};

declare %private function delete-imported-passports (
  $primaryUri as xs:string,
  $secondaryUri as xs:string,
  $personMap as document-node()
)
{
  let $source := mp:get-source($primaryUri)
  let $passMapUri := concat("/mapping/", $source, "/", $personMap/mapping/passportdoc/data(), ".xml")
  let $passDir :=  concat("/", $source, "/", $personMap/mapping/passportdoc/data(), "/")
  for $uri in cts:uris("", ("document", "eager"),
      cts:and-query((
        cts:directory-query($passDir),
        cts:element-value-query(xs:QName("merge-person-uri"), $secondaryUri)
      ))
    )
  return xdmp:document-delete($uri)
};

declare %private function find-remaining-dependents (
  $main as xs:string,
  $primaryUri as xs:string,
  $secondaryUri as xs:string
) as xs:string* {
  let $links :=
  cts:uris("", (), cts:and-query((
    cts:directory-query(concat(substring-before($main, ".xml"), "/"))
    , cts:collection-query("match")
  )))
  let $ids := (
    mp:get-id($main),
    mp:get-id($primaryUri),
    mp:get-id($secondaryUri)
  )
  for $link in $links
  let $linkId := mp:get-id($link)
  return
  if ($linkId = $ids) then
    ()
  else
    $link
};

declare %private function delete-merge-doc (
  $uri as xs:string
) {
  let $enhancedUri := concat("/enhanced", $uri)
  let $ofisUri := cts:uris("", (), cts:and-query((
      cts:directory-query("/ofis/person/")
      , cts:element-value-query(xs:QName("rawuri"), $enhancedUri)
    )))[1]
  let $enhOfisUri := concat("/enhanced", $ofisUri)
  return (
    xdmp:document-delete($uri)
    ,
    if (exists(doc($enhancedUri))) then
      xdmp:document-delete($enhancedUri)
    else ()
    ,
    if (exists(doc($ofisUri))) then
      xdmp:document-delete($ofisUri)
    else ()
    ,
    if (exists(doc($enhOfisUri))) then
      xdmp:document-delete($enhOfisUri)
    else ()
  )
};
