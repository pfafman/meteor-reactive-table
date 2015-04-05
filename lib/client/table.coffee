
DEBUG = true

# Capitalize first letter in string
String::capitalize = ->
  @charAt(0).toUpperCase() + @slice(1)

Template.reactiveTable.onCreated ->
  console.log('reactiveTable onCreated', @data) if DEBUG
  table = @data
  
  if table?.publicationName?()?
    @autorun =>
      console.log("subscribe", table.publicationName?()) if DEBUG
      @subscribe(table.publicationName(), table.select(), table.sort(), table.limit(), table.skip())
      

Template.reactiveTable.onRendered ->
  console.log('reactiveTable onRendered') if DEBUG


Template.reactiveTable.helpers
  haveTable: ->
    @ instanceof ReactiveTableInstance

  haveData: ->
    console.log("haveData", @recordCount()) if DEBUG
    @recordCount() > 0

  style: ->
    @options.style

  moreTableClasses: ->
    if @options.rowLink?
      "hoverable rowlink"

  noRecordsText: ->
    @options.noRecordsText or "No #{@recordsName().capitalize()}"


Template.reactiveTableNav.helpers
  
  pageUpSymbol: ->
    @pageUpSymbol or '&#10095;'

  
  pageDownSymbol: ->
    @pageDownSymbol or '&#10094;'

  
  pageDownDisable: ->
    @skip()is 0
      
  showNavCount: ->
    @recordCount() > @increment()
  
  pageUpDisable: ->
    @skip() + @increment() > @recordCount()

  recordCountStart: ->
    @skip() + 1

  recordCountEnd: ->
    Math.min(@skip() + @limit(), @recordCount())

  recordCountDisplay: ->
    @recordCount() + " " + @recordsName()
      


Template.reactiveTableNav.events

  'click .page-up': (event, tmpl) ->
    console.log("page up") if DEBUG
    @pageUp()


  'click .page-down': (event, tmpl) ->
    console.log("page down") if DEBUG
    @pageDown()


Template.reactiveTableHeading.onRendered ->
  console.log("reactiveTableHeading onRendered", @data) if DEBUG

Template.reactiveTableHeading.helpers
  
  showNewButton: ->
    @options.newRecordRoute or @options.showNewButton


  newRecordButtonText: ->
    @options.newRecordButtonText or "New " + @recordName()


Template.reactiveTableHeader.helpers
  # headers: ->
  #   console.log("headers", Template.parentData(1).headers()) if DEBUG
  #   Template.parentData(1).headers()

  sortArrow: ->
    if @desc
      @upArrow or "&#8593;"
    else
      @downArrow or "&#8595;"


Template.reactiveTableHeader.events
  'click .table-col-head': (e, tmpl) ->
    e.preventDefault()
    Template.parentData(1).setSort(@dataKey)


Template.reactiveTableBody.helpers
  records: ->
    @recordsData()



Template.reactiveTableRow.events

  'click td': (event, tmpl) ->
    if Template.parentData(1).options.rowLink? and not $(event.target).hasClass('rowlink-skip')
      Template.parentData(1).options.rowLink(@.record)
    

  'click .reactive-table-delete-record': (event, tmpl) ->
    console.log("delete", @,  Template.parentData(1)) if DEBUG
    Template.parentData(1).options?.onDelete?(@) or Template.parentData(1).onDelete?(@)


  'click .reactive-table-edit-record': (event, tmpl) ->
    console.log("edit: TODO: Enable Modal Edit?", @,  Template.parentData(1)) if DEBUG
    Template.parentData(1).options?.onEdit?(@) or Template.parentData(1).onEdit?(@)


