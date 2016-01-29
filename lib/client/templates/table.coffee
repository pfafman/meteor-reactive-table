
DEBUG = false


#########################
# reactiveTable template
#

Template.reactiveTable.onCreated ->
  console.log('reactiveTable onCreated', @data) if DEBUG
  table = @data

  @firstReady = new ReactiveVar(false)
  
  if table?.publicationName?()?
    @autorun =>
      console.log("subscribe", table.publicationName?()) if DEBUG
      @subscribe table.publicationName(), table.select(), table.sort(), table.limit(), table.skip(), =>
        @firstReady.set(true)

      

Template.reactiveTable.onRendered ->
  console.log('reactiveTable onRendered') if DEBUG
  @$('[rel="tooltip"]').tooltip()


Template.reactiveTable.onDestroyed ->
  @$('[rel="tooltip"]').tooltip('remove')


Template.reactiveTable.helpers

  firstReady: ->
    Template.instance().firstReady.get()


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



############################
# reactiveTableNav template
#

Template.reactiveTableNav.helpers
  
  pageUpSymbol: ->
    @pageUpSymbol or '&#10095;'

  
  pageDownSymbol: ->
    @pageDownSymbol or '&#10094;'

  
  pageDownDisable: ->
    @skip() is 0

      
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



################################
# reactiveTableHeading template
#

Template.reactiveTableHeading.onRendered ->
  console.log("reactiveTableHeading onRendered", @data) if DEBUG


Template.reactiveTableHeading.helpers
  
  showNewButton: ->
    @insertOk() and (@options.newRecordRoute or @options.showNewButton)


  newRecordButtonText: ->
    @options.newRecordText or "New " + @recordName()


Template.reactiveTableHeading.events
  
  'click #new-record': (event, tmpl) ->
    console.log("New Record") if DEBUG
    @onInsertRecord()


  'click #download-records': (event, tmpl) ->
    console.log("Download Records", tmpl, @) #if DEBUG

    tableTitle = @tableTitle or @name or 'records'
    filename = tableTitle + '.csv'
    @downloadRecords (error, csv) ->
      if error
        Materialize.toast("Error getting CSV to download", 3000, 'toast-error')
        console.log("Error getting CSV", error)
      else if csv
        console.log("Doing saveAs for CSV") if DEBUG
        blob = new Blob [csv],
          type: "text/csv"
        saveAs?(blob, filename)
        Materialize.toast("Records Downloaded", 3000, 'toast-success')
      else
        Materialize.toast("No data to download", 3000, 'toast-error')


################################
# reactiveTableHeader template
#

Template.reactiveTableHeader.onRendered ->
  @$('[rel="tooltip"]').tooltip()


Template.reactiveTableHeader.onDestroyed ->
  @$('[rel="tooltip"]').tooltip('remove')


Template.reactiveTableHeader.helpers
  # headers: ->
  #   console.log("headers", Template.parentData(1).headers()) if DEBUG
  #   Template.parentData(1).headers()

  sortArrow: ->
    if @desc
      @upArrow or "<i class='material-icons caret'>&#xE5C5;</i>"  #  (&#9650;) and ▼ (&#9660;)
    else
      @downArrow or "<i class='material-icons caret'>&#xE5C7;</i>"


Template.reactiveTableHeader.events
  'click .table-col-head': (e, tmpl) ->
    e.preventDefault()
    tmpl.$('[rel="tooltip"]').tooltip('remove')
    tmpl.$('[rel="tooltip"]').tooltip()
    Template.parentData(1).setSort(@dataKey)



################################
# reactiveTableBody template
#

Template.reactiveTableBody.helpers
  records: ->
    @recordsData()



################################
# reactiveTableRow template
#

Template.reactiveTableRow.onRendered ->
  @$('.modal-trigger').leanModal()
  @$('[rel="tooltip"]').tooltip()
  

Template.reactiveTableRow.onDestroyed ->
  @$('[rel="tooltip"]').tooltip('remove')
  

Template.reactiveTableRow.helpers
  json: ->
    if @colData?[0]?.record?
      '<pre>' + JSON.stringify(@colData[0].record, null, 2) + '</pre>'

  rowLinkSkip: ->
    if @aLink
      "rowlink-skip"


Template.reactiveTableRow.events

  'click td': (event, tmpl) ->
    if Template.parentData(1).options.rowLink? and not $(event.currentTarget).hasClass('rowlink-skip')
      Template.parentData(1).options.rowLink(@.record)
    

  'click .reactive-table-delete-record': (event, tmpl) ->
    console.log("delete", @,  Template.parentData(1)) if DEBUG
    tmpl.$('[rel="tooltip"]').tooltip('remove')
    tmpl.$('[rel="tooltip"]').tooltip('')
    Template.parentData(1).onRemoveRecord?(@)
    tmpl.$('[rel="tooltip"]').tooltip('')


  'click .reactive-table-edit-record': (event, tmpl) ->
    console.log("edit: TODO: Enable Modal Edit?", @,  Template.parentData(1)) #if DEBUG
    tmpl.$('[rel="tooltip"]').tooltip('remove')
    tmpl.$('[rel="tooltip"]').tooltip('')
    Template.parentData(1).onUpdateRecord?(@)
    tmpl.$('[rel="tooltip"]').tooltip('')



