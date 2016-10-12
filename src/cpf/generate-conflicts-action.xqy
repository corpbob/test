import module namespace cpf = "http://marklogic.com/cpf" 
  at "/MarkLogic/cpf/cpf.xqy";
  
import module namespace gc = "http://asti.dost.gov.ph/ofis/mapping/generate-conflicts"
  at "/mapping/generate-conflicts.xqy";
  
declare variable $cpf:document-uri as xs:string external;
declare variable $cpf:transition as node() external;

if (cpf:check-transition($cpf:document-uri, $cpf:transition)) then try {
    (
      gc:check-mapping($cpf:document-uri),
      cpf:success( $cpf:document-uri, $cpf:transition, () )
    )
}
catch ($e) {
  cpf:failure( $cpf:document-uri, $cpf:transition, $e, () )
}
else ()