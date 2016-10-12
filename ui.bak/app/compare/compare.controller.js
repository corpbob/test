(function () {
  'use strict';

  var fields = [ 'id', 'first', 'middle', 'last', 'passport', 'birthdate', 'birthplace', 'gender', 'baseUri', 'source'];
  var tabnames = [ 'matches', 'rejected', 'conflicts', 'merged'];
  var delimiter = '|';
  var tabLabels = {
    'ofis': {
      'matches': 'Match',
      'conflicts': 'Conflict',
      'merged': 'Permanent Match',
      'rejected': 'Rejected'
    },
    'non-ofis': {
      'matches': 'Duplicate',
      'conflicts': 'Conflict',
      'merged': 'Permanent Duplicate',
      'rejected': 'Rejected'
    }
  };


  angular.module('app.compare').filter('stripPrefix', function() {
    return function(input) {
      if(input){
        var idx = input.indexOf(delimiter);
        if(idx > -1){
          return input.substring(idx+1);
        }
        return input;
      }
    };
  }).filter('uuidPrefix', function() {
    return function(uuid) {
      if(uuid){
        var idx = uuid.indexOf('-');
        if(idx > -1){
          return uuid.substring(0,idx);
        }
        return uuid;
      }
    };
  })

  .controller('CompareCtrl', CompareCtrl);

  CompareCtrl.$inject = ['doc', '$stateParams', 'MLRest', '$rootScope'];

  function CompareCtrl(doc, $stateParams, MLRest, $rootScope) {
    console.log("compare doc: ", doc);
    var ctrl = this;
    this.mlRest = MLRest;
    ctrl.model = {};
    ctrl.model.doc = doc.data;
    ctrl.model.doc.isResolved = true;

    //ctrl.labels = tabLabels[ctrl.page];
    if(!ctrl.labels){
      ctrl.labels = tabLabels['non-ofis'];
    }

    $rootScope.$on('compare:label', function(event,data){
       ctrl.labels[data.tab] = data.name;
    });

    $rootScope.$on('compare:tab', function(event, data){
        ctrl.tab = data;
    });

    //determine which tab to activate
    ctrl.tab = 'matches';

    for(var i=0;i<tabnames.length;i++){
      var a = ctrl.model.doc[tabnames[i]];
      if(a && a.length > 0){
        ctrl.tab = tabnames[i];
        break;
      }
    }

    var uri = $stateParams.uri;
  }

  CompareCtrl.prototype.show = function(type){
    this.tab = type;
  };

  CompareCtrl.prototype.submit = function(person){
    console.log('resolved: ', person);
    alert(person.first);
  };

    CompareCtrl.prototype.updateArray = function(name, item){
        console.log('name', name);
        this[name].push(item);

    };
}());
