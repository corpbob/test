(function () {
  'use strict';

  angular.module('app.root')
    .controller('RootCtrl', RootCtrl);

  RootCtrl.$inject = ['messageBoardService', '$rootScope'];

  function RootCtrl(messageBoardService, $rootScope) {
    var ctrl = this;
    $rootScope.$on('ofis:title', function(event, newValue){
      if(newValue){
        ctrl.title = newValue;
      }
    });

    angular.extend(ctrl, {
      messageBoardService: messageBoardService
    });
  }
}());
