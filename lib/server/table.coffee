###
DEBUG = false

Meteor.publish "reactiveTable", (tableName, selector={}, sort={}, skip=0, limit=10) ->
  

  check(tableName, String)
  check(selector, Match.Optional(Match.OneOf(Object, null)))
  check(sort, Match.Optional(Match.OneOf(Array, null)))
  check(skip, Number)
  check(limit, Number)

  table = Mongo.Collection.get(tableName)
  throw new Error("Could not find table #{tableName}") unless table

  if limit is 0
    limit = 1

  # TODO: Security.  For now require they override this.

  if table.deny?(@userId)
    console.log("User not allowed access")
    @ready()
    return
###