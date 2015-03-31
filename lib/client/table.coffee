
DEBUG = true

Template.reactiveTable.onCreated ->
  console.log('reactiveTable onCreated') if DEBUG
  table = @data
  
  if table?.publicationName?()?
    @autorun =>
      console.log("subscribe", table.publicationName?()) if DEBUG
      @subscribe(table.publicationName(), table.select(), table.sort(), table.limit(), table.skip())
      

Template.reactiveTable.onRendered ->
  # ...


Template.reactiveTable.helpers
  haveData: ->
    @recordCount() > 0

  style: ->
    @options.style


Template.reactiveTableNav.helpers
  
  pageUpSymbol: ->
    @pageUpSymbol or '&#10095;'

  
  pageDownSymbol: ->
    @pageDownSymbol or '&#10094;'

  
  pageDownDisable: ->
    @skip()is 0
      

  
  pageUpDisable: ->
    @skip() + @increment() > @recordCount()
      


Template.reactiveTableNav.events

  'click .page-up': (event, tmpl) ->
    console.log("page up") if DEBUG
    @pageUp()


  'click .page-down': (event, tmpl) ->
    console.log("page down") if DEBUG
    @pageDown()



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

  'click .reactive-table-delete-record': (event, tmpl) ->
    console.log("delete", @,  Template.parentData(1)) if DEBUG
    Template.parentData(1).options.onDelete?(@)


  'click .reactive-table-edit-record': (event, tmpl) ->
    console.log("edit: TODO: Enable Modal Edit", @) if DEBUG
    Template.parentData(1).options.onEdit?(@)



