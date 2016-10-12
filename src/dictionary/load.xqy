module namespace dict-thes-load = "http://asti.dost.gov.ph/ofis/dict-thes-load";
declare default function namespace "http://asti.dost.gov.ph/ofis/dict-thes-load";

import module namespace common = "http://asti.dost.gov.ph/ofis/common"
  at '/transform/common.xqy';
import module namespace cdict = "http://marklogic.com/xdmp/custom-dictionary" 
  at "/MarkLogic/custom-dictionary.xqy";
import module namespace thsr="http://marklogic.com/xdmp/thesaurus" 
  at "/MarkLogic/thesaurus.xqy";

declare function load-dictionary($uri as xs:string) {
  (: Add an entry to the English custom dictionary :)
  let $language := "en"
  (: Get the English custom dictionary :)
  let $dictionary := cdict:dictionary-read($language)
  (:TODO test this, can't afford to do check each iteration :)
  let $dictionary := 
    if (fn:empty($dictionary)) then 
      (cdict:dictionary-write($language, 
        element cdict:dictionary { 
          attribute xml:lang { $language }}
        ), cdict:dictionary-read($language))
    else
      $dictionary
  
  let $entries := common:load-doc-from-module($uri)
  return for $entry in $entries
    cdict:dictionary-write($language,
      xdmp:node-insert-child($dictionary/dictionary,$entry))
}

declare function load-thesaurus($file-system-uri as xs:string, $uri as xs:string) {
  thsr:load($file-system-uri, $uri)
}