xquery version "1.0-ml";
module namespace ofisToJson =
  "http://marklogic.com/rest-api/transform/ofis-to-json";

declare function ofisToJson:tojson($doc as node(), $object as json:object) as item()*
{
 (: let $object := json:object() :)
 let $_ := xdmp:log($doc)
 let $content := $doc
 let $_ := for $n in $content/*
             let $_ := xdmp:log($n)
             let $count := count($n/*)
             let $_ := xdmp:log($count)

             let $_ := if( $count > 0)
                       then
                          let $object2 := json:object()
                          let $_ := ofisToJson:tojson($n, $object2)
                          return map:put($object, string(node-name($n)), $object2)
                       else map:put($object, string(node-name($n)), string($n))
             return ()
 return ()

};


declare function ofisToJson:transform(
  $context as map:map,
  $params as map:map,
  $content as document-node()
) as document-node()
{
  if (fn:empty($content/*))
  then
      $content
  else
      let $_ := xdmp:log(concat("testing....", map:get($context,"uri")))

      let $data := $content/node()
      let $object := json:object()

      let $_ :=  ofisToJson:tojson($data, $object)
      return xdmp:to-json($object)
};
