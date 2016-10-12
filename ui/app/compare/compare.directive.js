(function () {

    'use strict';

    angular.module('app.compare')
        .directive('compareDir', CompareDirective)
        .controller('CompareDirController', CompareDirController)
        .controller('ModalInstanceCtrl', ModalInstanceCtrl);

    function CompareDirective() {
        return {
            restrict: 'EA',
            controller: 'CompareDirController',
            controllerAs: 'ctrl',
            replace: true,
            scope: {
                model: '=',
                //page: '=',
                tabName: '=',
                label: '=',
                update: '&onUpdate',
                //mode: '@',
                submit: '&onSubmit'
            },
            templateUrl: 'app/compare/compare-dir.html'
        };
    }

    CompareDirController.$inject = ['$scope', 'MLRest', '$uibModal'];
    ModalInstanceCtrl.$inject = ['$scope', '$uibModalInstance', 'person', 'ctrl', 'options'];

    var fields = [ 'id', 'first', 'middle', 'last', 'passport-list', 'dob', 'birthplace', 'gender', 'baseUri'];
    var tabnames = [ 'matches', 'conflicts', 'permMatch'];
    var delimiter = '|';


    function augment(person) {
        for (var i = 1; i < fields.length; i++) {
            var f = fields[i];
            if (f === 'passport-list') {
                var passport = person['passport'];
                var passport_list = "";
                if (passport && passport.length > 0) {
                    for (var j = 0; j < passport.length; j++) {
                        passport_list += passport[j] + ',';
                    }
                    passport_list = passport_list.substring(0, passport_list.length - 1);
                    person[f] = person.id + delimiter + passport_list;
                }
            } else {
                if (person[f]) {
                    person[f] = person.id + delimiter + person[f];
                }
            }
        }
    }

    function reverseAugment(resolved) {
        var copy = {};
        angular.copy(resolved, copy);
        for (var i = 1; i < fields.length; i++) {
            var f = fields[i];
            var value = copy[f]
            if (value && f === 'passport-list') {
                var passport_list = value.split(',');
                if (passport_list && passport_list.length > 0) {
                    var passport = resolved['passport'];
                    if (!passport) {
                        passport = [];
                        resolved.passport = passport;
                    }
                    for (var j = 0; j < passport_list.length; j++) {
                        passport[j] = passport_list[j];
                    }
                }
            }
            if (value) {
                var idx = value.indexOf(delimiter);
                if (idx > -1) {
                    copy[f] = value.substring(idx + 1);
                }
            }
        }

        return copy;
    }

    function ModalInstanceCtrl($scope, $uibModalInstance, person, ctrl, options) {
        $scope.person = person;


        $scope.selected = {
            item: 'test'
        };

        if (options && options.operation) {
            var op = options.operation;
            if (op === 'unmatch') {
                $scope.operation = 'REJECT matching record';
            } else if (op === 'undo') {
                $scope.operation = 'UNDO rejection of record';
            }
        }

        $scope.handleRejectUndo = function () {
            var targettab = ctrl.targetTab;
            var copy = {};
            angular.copy(ctrl.model, copy);
            var index = updateJson(copy, person, ctrl.tabName, targettab);

            var data = {
                data: copy.doc
            };

            var restOptions = {
                format: 'json',
                uri: ctrl.doc.uri,
                method: 'PUT',
                data: data,
                params: options.params
                // TODO: add read/update permissions here like this:
                // 'perm:sample-role': 'read',
                // 'perm:sample-role': 'update'
            };

            ctrl.mlRest.extension(options.operation, restOptions).success(function (data) {
                //updateArrays(ctrl.tabs, currentTab, newTab);
                //ctrl.tab = newTab;

                console.log(data);
                updateJson(ctrl.model, person, ctrl.tabName, targettab);
                if (ctrl.model.doc[ctrl.tabName].length === 0) {
                    ctrl.scope.$emit("compare:tab", 'matches');
                }

                //$uibModalInstance.close($scope.selected.item);
                //ctrl.updateArray('rejected', person);
                //delete person.loading;
            }).error(function (data) {
                console.log(data);
            });
            $uibModalInstance.close($scope.selected.item);
        };

        $scope.cancel = function () {
            $uibModalInstance.dismiss('cancel');
        };
    }


    function CompareDirController($scope, mlRest, $uibModal) {
        var ctrl = this;
        //ctrl.itemsArray = $scope.itemsArray;

        ctrl.scope = $scope;
        ctrl.model = $scope.model;
        ctrl.doc = ctrl.model.doc;
        ctrl.label = $scope.label;
        ctrl.mlRest = mlRest;
        ctrl.tabName = $scope.tabName;
        ctrl.uibModal = $uibModal;

        ctrl.submit = function (p) {
            var copy = reverseAugment(p);
            $scope.submit(copy);
        };

        ctrl.updateArray = function (name, item) {
            $scope.update({ name: name, item: item});
        };

        //ctrl.page = $scope.page;
        //angular.copy($scope.doc, ctrl.doc);

        ctrl.doc.isResolved = true;


        var itemsArray = [];
        angular.copy(ctrl.doc[ctrl.tabName], itemsArray);


        ctrl.resolved = {};
        angular.copy(ctrl.model.doc.resolved, ctrl.resolved);

        itemsArray.forEach(function(item){
            for(var i=0;i<fields.length;i++){
                var field = fields[i];
                item[field + '_equal'] = (item[field] === ctrl.model.doc.resolved[field]);

            }
        });

        augment(ctrl.resolved);
        ctrl.primary = {};
        angular.copy(ctrl.model.doc.resolved, ctrl.primary);
        augment(ctrl.primary);
        ctrl.primary.merge = true;
        ctrl.primary.choosePassport = true;
        itemsArray.forEach(function (item) {
            augment(item);
        });

        ctrl.model.itemsArray = itemsArray;
        var labelData = { tab: 'matches', name: 'Duplicate'};
        ctrl.model.columnLabelData = { matches: 'Match', rejected: 'Rejected'};
        if (itemsArray.length > 1) {
            if (itemsArray[0].source != itemsArray[1].source) {
                labelData.tab = 'matches';
                labelData.name = 'Match';
            }
        }


        $scope.$emit('compare:label', labelData);
        ctrl.allresolved = String(ctrl.doc.id);

        //ctrl.choose(ctrl.doc);


        /*angular.extend(ctrl, {
         itemsArray: itemsArray,
         tab: $scope.tabName
         });
         */

    }

    CompareDirController.prototype.choose = function (chosen) {
        //chosen.merge = true;
        for (var i = 1; i < fields.length; i++) {
            var field = fields[i];
            var value = chosen[field];
            if (value) {
                this.resolved[field] = String(value);
            }
        }
    };


    CompareDirController.prototype.samePerson = function (person) {

        var ctrl = this;
        person.loading = true;
        var idx = this.doc.baseUri.indexOf(delimiter);
        var primary = this.doc.baseUri;
        if (idx > -1) {
            primary = this.doc.baseUri.substring(idx + 1);
        }

        var settings = {
            method: 'PUT',
            params: {
                'rs:primary': primary,
                'rs:secondary': person.baseUri
            },
            data: {}

        };

        if (!person.isResolved) {
            settings.method = 'DELETE';
        }

        if (true) {
            this.mlRest.extension('perm-match', settings).success(function (data) {
                //updateArrays(ctrl.tabs, currentTab, newTab);
                //ctrl.tab = newTab;
                console.log(data);
                delete person.loading;
            }).error(function (data) {
                person.status = 'Error';
            });
        }

    };

    CompareDirController.prototype.merge = function () {

        var ctrl = this;
        var targettab = "merged";
        var copy = {};
        angular.copy(ctrl.model, copy)
        var person = ctrl.model.itemsArray[0];
        if (!person.merge) {
            alert('Click on "Include"');
            return;
        }
        var index = updateJson(copy, person, "matches", targettab);

        copy.doc.resolved = ctrl.resolved;
        copy.doc.resolved = reverseAugment(copy.doc.resolved);
        copy.doc.resolved.status = 'unique';
        delete copy.doc.resolved['passport-list'];
        var data = {
            data: copy.doc
        };

        var restOptions = {
            format: 'json',
            uri: ctrl.doc.uri,
            method: 'PUT',
            data: data,
            params: {}
            // TODO: add read/update permissions here like this:
            // 'perm:sample-role': 'read',
            // 'perm:sample-role': 'update'
        };

        var options = {
            format: 'json',
            uri: copy.doc.uri
            //method: 'POST'
            // TODO: add read/update permissions here like this:
            // 'perm:sample-role': 'read',
            // 'perm:sample-role': 'update'
        };

        ctrl.mlRest.updateDocument(copy.doc, options).then(function (data) {
            updateJson(ctrl.model, person, 'matches', targettab);
            if (ctrl.model.doc[ctrl.tabName].length === 0) {
                ctrl.scope.$emit("compare:tab", 'matches');
            }
        });


        if (false) {
            var ctrl = this;
            var master = {
                merged: [],
                uri: this.doc.uri

            };

            if (ctrl.itemsArray.length > 0) {
                ctrl.itemsArray.forEach(function (item) {
                    if (item.merge) {
                        master.merged.push(item);
                    }
                })
            }

            master.resolved = ctrl.resolved;
            console.log(master.resolved);

            var options = {
                format: 'json',
                uri: 'bobby.json',
                method: 'POST'
                // TODO: add read/update permissions here like this:
                // 'perm:sample-role': 'read',
                // 'perm:sample-role': 'update'
            };

            var copy = reverseAugment(master.resolved);
            ctrl.mlRest.extension('merge', options).success(function (data) {
                //updateArrays(ctrl.tabs, currentTab, newTab);
                //ctrl.tab = newTab;
                console.log(data);
                angular.copy(master.resolved, ctrl.itemsArray[0]);
                ctrl.itemsArray.splice(1, 1);
                //delete person.loading;
            }).error(function (data) {
                //person.status = 'Error';
            });

        }

        //this.itemsArray[1].isResolved = true;
    };

    CompareDirController.prototype.open = function (size, targetTab, person, ctrl, options) {
        var ctrl = this;
        var modalInstance = this.uibModal.open({
            animation: true,
            templateUrl: 'myModalContent.html',
            controller: 'ModalInstanceCtrl',
            size: size,
            resolve: {
                person: person,
                options: options,
                ctrl: ctrl
            }
        });

        modalInstance.result.then(function (selectedItem) {
            ctrl.scope.selected = selectedItem;
        }, function () {
            console.log('Modal dismissed at: ' + new Date());
        });
    };

    CompareDirController.prototype.unmatch = function (person) {
        if (person.unmatch) {
            this.target = reverseAugment(person);
            this.targetTab = 'rejected';
            var options = {
                operation: 'unmatch',
                params: {
                    'rs:op': 'reject'
                }
            };
            this.open('lg', this.tabName, this.target, this, options);
        }
    };

    CompareDirController.prototype.handlePassport = function (person) {
        var ctrl = this;
        var passport = person.passport[0];
        var index = ctrl.resolved.passport.indexOf(passport);
        if (person.choosePassport) {
            if (index < 0) {
                ctrl.resolved.passport.push(passport);
            }
        } else {
            if (index > -1) {
                ctrl.resolved.passport.splice(index, 1);
            }
        }

        var passportList = '';
        for (var i = 0; i < ctrl.resolved.passport.length; i++) {
            passportList += ctrl.resolved.passport[i] + ',';
        }

        ctrl.resolved['passport-list'] = passportList.substring(0, passportList.length - 1);
    }

    CompareDirController.prototype.unReject = function (person) {
        if (person.unReject) {
            this.target = reverseAugment(person);
            this.targetTab = 'matches';
            var options = {
                operation: 'undo',
                params: {}
            };
            this.open('lg', this.tabName, this.target, this, options);
        }
    };


    function updateJson(ctrl, person, sourceName, destName) {
        var index;
        var sourceArray = ctrl.doc[sourceName];
        for (var i = 0; i < sourceArray.length; i++) {
            var item = sourceArray[i];
            if (item.id == person.id) {
                index = i;
                break;
            }
        }

        var spliced;

        if (index >= 0) {
            spliced = sourceArray.splice(index, 1);
            ctrl.itemsArray.splice(index, 1);
        }

        var destArray = ctrl.doc[destName];
        if (!destArray) {
            destArray = [];
            ctrl.doc[destName] = destArray;

        }

        destArray.push(spliced[0]);

        delete ctrl.doc.isResolved;
        ctrl.doc['match-count'] = ctrl.doc['matches'].length;

    }
}());
