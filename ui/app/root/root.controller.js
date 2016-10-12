(function () {
  'use strict';

  angular.module('app.root')
    .controller('RootCtrl', RootCtrl);

  RootCtrl.$inject = ['messageBoardService', '$rootScope', '$http', '$scope'];

  function RootCtrl(messageBoardService, $rootScope, $http, $scope) {
    var ctrl = this;

    $http.get('/api/hostname').then(function(response){
      console.log('hostname: ' + response.data);
	$scope.hostname=response.data;
    });

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
