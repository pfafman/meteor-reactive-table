
Package.describe({
  //name: 'pfafman:meteor-reactive-table',
  summary: "Paging Table for Meteor",
  version: "0.0.1",
  git: "https://github.com/pfafman/meteor-reactive-table.git",
});

Package.on_use(function (api, where) {
  api.versionsFrom("METEOR@1.0.4");

  // Client
  api.use(
    [
    'templating',
    'reactive-var',
    'less'
    ]
    , 'client');

  // Server and Client
  api.use([
    'underscore',
    'coffeescript',
    'mongo',
    'tmeasday:publish-counts',
    ], ['client', 'server']);

  api.imply('tmeasday:publish-counts');

  //api.imply('dburles:mongo-collection-instances');

  api.add_files(
    [
    'lib/client/table.html',
    'lib/client/table.less',
    'lib/client/table.coffee',
    'lib/client/templates/checkbox.html',
    'lib/client/templates/checkbox.coffee',
    'lib/client/templates/select.html',
    'lib/client/templates/select.coffee',
    ]
    , 'client');

  //api.add_files(['lib/server/table.coffee'], 'server');

  api.add_files(['lib/common/reactiveTable.coffee'], ['server','client']);

  
});


Package.on_test(function (api) {

});
