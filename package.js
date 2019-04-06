
Package.describe({
  name: 'pfafman:reactive-table',
  summary: "Paging Table for Meteor",
  version: "0.4.14",
  git: "https://github.com/pfafman/meteor-reactive-table.git",
});

Package.on_use(function (api, where) {
  
  // Client
  api.use(
    [
    //'modules',
    'pfafman:filesaver',
    'pfafman:counter',
    'templating',
    'reactive-dict',
    'less',
    'tmeasday:check-npm-versions@0.3.1'
    ]
    , 'client');

  // Server and Client
  api.use([
    //'ecmascript',
    'underscore',
    'coffeescript',
    'mongo',
    'tmeasday:publish-counts',
    'softwarerero:accounts-t9n',
    'meteorstuff:materialize-modal'
    ], ['client', 'server']);


  api.imply([
    'tmeasday:publish-counts@0.7.3',
  ], ["client", "server"]);


  //api.imply('dburles:mongo-collection-instances');

  api.add_files(
    [
    'lib/client/helpers.coffee',
    'lib/client/templates/table.html',
    'lib/client/templates/table.less',
    'lib/client/templates/table.coffee',
    'lib/client/templates/form.html',
    'lib/client/templates/form.coffee',
    'lib/client/templates/filter.html',
    'lib/client/templates/filter.coffee',
    'lib/client/templates/checkbox.html',
    'lib/client/templates/checkbox.coffee',
    'lib/client/templates/select.html',
    'lib/client/templates/select.coffee',
    ]
    , 'client');

  api.add_files(
    [
    'lib/common/reactiveTable.coffee',
    'lib/common/t9n.coffee',
    ], ['server','client']);


});


Package.on_test(function (api) {

});
