
DEBUG = false


Template.reactiveTableFilter.onCreated ->
  # ...


Template.reactiveTableFilter.onRendered ->
  console.log("reactiveTableFilter onRendered") if DEBUG
  elems = document.querySelectorAll('select')
  console.log("Issue with findAll and form init", elems, @findAll('select')) if DEBUG
  @selectInstances = M.FormSelect.init(elems) #@findAll('select'))
  

Template.reactiveTableFilter.onDestroyed ->
  # ...


Template.reactiveTableFilter.helpers

  isBool: ->
    @filterType() is 'checkbox'


  checked: ->
    if @filterType() is 'checkbox' and @filterValue()
      'checked'


Template.reactiveTableFilter.events
  "change #filter-column": (e, tmpl) ->
    #e.preventDefault()
    console.log("change filter column", e.target.value) if DEBUG
    @setFilterColumn(e.target.value)


  "keyup, change #filter-value": (e, tmpl) ->
    #e.preventDefault()
    console.log("filter-value", $(e.target).is(':checked'), e.target.value) if DEBUG
    value = e.target.value
    if @filterType() is 'checkbox'
      value = $(e.target).is(':checked')

    #Meteor.defer =>
    @setFilterValue(value)