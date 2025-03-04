
DEBUG = false


t9nIt = (string) ->
  T9n?.get?(string) or string
  

Template.registerHelper 'irtblT9nit', (string) ->
  t9nIt(string)


Template.registerHelper 'capitalize', (str) ->
  str?.charAt?(0).toUpperCase() + str?.slice?(1)

# Capitalize first letter in string
String::capitalize = ->
  @charAt(0).toUpperCase() + @slice(1)

