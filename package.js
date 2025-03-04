
Package.describe({
  name: 'pfafman:reactive-table',
  summary: "Paging Table for Meteor",
  version: "1.0.1",
  git: "https://github.com/pfafman/meteor-reactive-table.git",
});

Package.onUse(function (api, where) {
  
  // Client
  api.use(
    [
    //'modules',
    'pfafman:filesaver',
    'pfafman:counter',
    'templating',
    'reactive-dict',
    'less',
    'tmeasday:check-npm-versions'
    ]
    , 'client');

  // Server and Client
  api.use([
    //'ecmascript',
    'underscore',
    'coffeescript',
    'mongo',
    'compat:publish-counts',
    'softwarerero:accounts-t9n',
    'meteorstuff:materialize-modal'
    ], ['client', 'server']);


  api.imply([
    'compat:publish-counts',
  ], ["client", "server"]);


  //api.imply('dburles:mongo-collection-instances');

  api.addFiles(
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

  api.addFiles(
    [
    'lib/common/reactiveTable.coffee',
    'lib/common/t9n.coffee',
    ], ['server','client']);


});


Package.onTest(function (api) {

});
