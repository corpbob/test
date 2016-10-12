/* global MLSearchController */
(function () {
  'use strict';

  angular.module('app.search')
    .controller('SearchCtrl', SearchCtrl);

  SearchCtrl.$inject = ['$scope', '$location', 'userService', 'MLSearchFactory', 'x2js', '$rootScope'];

  // inherit from MLSearchController
  var superCtrl = MLSearchController.prototype;
  SearchCtrl.prototype = Object.create(superCtrl);

  var ctrlOpts = {};

  function initOpts(searchFactory) {
    ctrlOpts = {
      "bi" : searchFactory.newContext({
          "queryOptions" : "bi-person",
          "suggestOptions" : "bi-person"
        }),
      "dfa" : searchFactory.newContext({
          "queryOptions" : "dfa-person",
          "suggestOptions" : "dfa-person"
        }),
      "ofis" : searchFactory.newContext({
          "queryOptions" : "ofis-person",
          "suggestOptions" : "ofis-person"
        }),
        "all" : searchFactory.newContext({
            "queryOptions" : "similar"
        })
    };
  }

  function switchOption($scope, $location, userService, searchFactory, ctrl, option) {
    initOpts(searchFactory);
    var mlSearch = ctrlOpts[option];

    superCtrl.constructor.call(ctrl, $scope, $location, mlSearch);
    //ctrl.mlSearch.qtext='status:similar';
    ctrl.init();
    //ctrl.search("resolved_status:similar");

    ctrl.setSnippet = function(type) {
      mlSearch.setSnippet(type);
      ctrl.search();
    };

    $scope.$watch(userService.currentUser, function(newValue) {
      ctrl.currentUser = newValue;
    });
  }

  function SearchCtrl($scope, $location, userService, searchFactory, x2js, $rootScope) {
    var ctrl = this;
    this.x2js = x2js;
    this.scope = $scope;
    this.location = $location;
    this.userService = userService;
    this.searchFactory = searchFactory;

    $rootScope.$emit('ofis:title',' ');

    var ds = this.location.search()['datasource'];
    if(ds){
      $scope.datasource = ds;
    } else {
      $scope.datasource = 'bi';
    }

    //use all for now
      $scope.datasource = 'all';

    switchOption($scope, $location, userService, searchFactory, ctrl, $scope.datasource);

  }

  SearchCtrl.prototype.updateSearchResults = function updateSearchResults(data) {
    this.searchPending = false;
    this.response = data;
    var x2js = this.x2js;
    var results = [];
    if(this.response.results && this.response.results.length > 0){
      this.response.results.forEach(function(result){
        var extracted = result.extracted;
        if(extracted && extracted.content.length > 0){
          var content = extracted.content[0]
          results.push(content);
        }
      });
      console.log(results);
    }
    this.results = results;
    this.qtext = this.mlSearch.getText();
    this.page = this.mlSearch.getPage();
    return this;
  };

  SearchCtrl.prototype.changeOption = function(datasource){
    console.log("change option ", datasource);
    switchOption(this.scope, this.location, this.userService, this.searchFactory, this, datasource);
    this.location.search('datasource',datasource);
  };

}());
