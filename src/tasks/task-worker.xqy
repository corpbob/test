import module namespace otm = "http://asti.dost.gov.ph/ofis/tasks/manager"
  at '/tasks/task-manager.xqy';

declare variable $uri as xs:string external;

xdmp:invoke-function(
  function() {otm:process-task($uri)},
  <options xmlns="xdmp:eval">
    <transaction-mode>update-auto-commit</transaction-mode>
  </options>
)
