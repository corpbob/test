(function () {
  'use strict';
  angular.module('app.detail')
  .controller('DetailCtrl', DetailCtrl);

  DetailCtrl.$inject = ['doc', '$stateParams', '$location'];
  function DetailCtrl(doc, $stateParams, $location) {
    var ctrl = this;

    var uri = $stateParams.uri;

    ctrl.result= doc.data.person;
    ctrl.location = $location;
    /*var contentType = doc.headers('content-type');

    var x2js = new X2JS();

    if (contentType.lastIndexOf('application/json', 0) === 0) {

      ctrl.xml = vkbeautify.xml(x2js.json2xml_str(doc.data));
      ctrl.json = doc.data;
      ctrl.type = 'json';
    } else if (contentType.lastIndexOf('application/xml', 0) === 0) {
      ctrl.xml = vkbeautify.xml(doc.data);

      ctrl.json = x2js.xml_str2json(doc.data);
      ctrl.type = 'xml';

    } else if (contentType.lastIndexOf('text/plain', 0) === 0) {
      ctrl.xml = doc.data;
      ctrl.json = {'Document' : doc.data};
      ctrl.type = 'text';
    } else if (contentType.lastIndexOf('application', 0) === 0 ) {
      ctrl.xml = 'Binary object';
      ctrl.json = {'Document type' : 'Binary object'};
      ctrl.type = 'binary';
    } else {
      ctrl.xml = 'Error occured determining document type.';
      ctrl.json = {'Error' : 'Error occured determining document type.'};
    }
 */
    angular.extend(ctrl, {
      doc : doc.data,
      uri : uri
    });
  }

  DetailCtrl.prototype.resolve = function(uri){
    this.location.url('/compare');
  };

}());
