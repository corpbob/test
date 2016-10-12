import module namespace cpf = "http://marklogic.com/cpf" 
  at "/MarkLogic/cpf/cpf.xqy";
  
import module namespace cp = "http://asti.dost.gov.ph/ofis/mapping/check-passport"
  at "/mapping/check-passport.xqy";
  
declare variable $cpf:document-uri as xs:string external;
declare variable $cpf:transition as node() external;

if (cpf:check-transition($cpf:document-uri, $cpf:transition)) then try {
  (
    cp:check-mapping($cpf:document-uri),
    cpf:success( $cpf:document-uri, $cpf:transition, () )
  )
}
catch ($e) {
  cpf:failure( $cpf:document-uri, $cpf:transition, $e, () )
}
else ()