
DEBUG        = false
DEBUG_TIMING = false


initTooltip = (tmpl) ->
  tmpl.$('[rel="tooltip"]')?.tooltip()
  #tmpl.toolTips = M.Tooltip.init(tmpl.findAll('[rel="tooltip"]'))


destroyTooltip = (tmpl) ->
  tmpl.$('[rel="tooltip"]')?.destroy?()
  #tmpl.toolTips?.forEach? (tip) ->
  #    tip.destroy?()


closeTooltip =  (tmpl) ->
  tmpl.$('[rel="tooltip"]')?.close?()



#########################
# reactiveTable template
#

Template.reactiveTable.onCreated ->
  console.log('reactiveTable onCreated', @data) if DEBUG or DEBUG_TIMING
  table = @data

  @firstReady = new ReactiveVar(false)
  
  if table?.publicationName?()?
    if table.noSub
      console.log("NO SUB", @) if DEBUG
      @firstReady.set(true)
    else
      console.log("DO SUB", @) if DEBUG
      @autorun =>
        timer = moment()
        console.log("reactiveTable: subscribe #{table.publicationName?()}", table.select(), table.sort(), table.limit(), table.skip()) if DEBUG or DEBUG_TIMING
        
        @sub = @subscribe table.publicationName(), table.select(), table.sort(), table.limit(), table.skip(), =>
          @firstReady.set(true)
          console.log("reactiveTable: subscription ready #{table.publicationName?()}, #{(moment().diff(timer)/1000).toFixed(2)}") if DEBUG or DEBUG_TIMING


Template.reactiveTable.onRendered ->
  initTooltip(@)


Template.reactiveTable.onDestroyed ->
  console.log('reactiveTable tooltips', @toolTips) if DEBUG
  destroyTooltip(@)
  

Template.reactiveTable.helpers

  firstReady: ->
    Template.instance().firstReady.get()


  haveTable: ->
    @ instanceof ReactiveTableInstance


  haveData: ->
    console.log("haveData #{@recordCount()} #{@records().length}", @recordCount() > 0 or @records()?.length > 0) if DEBUG
    @recordCount() > 0 or @records()?.length > 0


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
    @skip() + @increment() >= @recordCount()


  recordCountStart: ->
    (@skip() + 1).toLocaleString()


  recordCountEnd: ->
    Math.min(@skip() + @limit(), @recordCount()).toLocaleString()


  recordCountDisplay: ->
    @recordCount().toLocaleString() + " " + @recordsName()



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
    console.log("Download Records", tmpl, @) if DEBUG

    tableTitle = @tableTitle or @name or 'records'
    filename = tableTitle + '.csv'
    @downloadRecords (error, csv) ->
      if error
        Materialize.toast("Error getting CSV to download", 3000, 'toast-error')
        console.log("Error getting CSV", error)
      else if csv
        console.log("Doing saveAs for CSV", saveAs, csv) if DEBUG
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
  initTooltip(@)
  

Template.reactiveTableHeader.onDestroyed ->
  console.log('reactiveTableHeader tooltips', @toolTips) if DEBUG
  destroyTooltip(@)


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
    closeTooltip(tmpl)
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
  #M.Modal.init(@findAll('.modal'))
  M.Modal.init(@$('.modal'))
  initTooltip(@)
  

Template.reactiveTableRow.onDestroyed ->
  console.log("reactiveTableRow toolTips", @toolTips) if DEBUG
  destroyTooltip(@)


Template.reactiveTableRow.helpers
  json: (options) ->
    if @colData?[0]?.record?
      # Omit some fields?
      fullRec = @colData[0].record
      if options.omitShowJSON?.length >= 1
        console.log("json",options.omitShowJSON) if DEBUG
        fullRec = _.omit(fullRec, options.omitShowJSON)
      '<pre>' + JSON.stringify(fullRec, null, 2) + '</pre>'

  rowLinkSkip: ->
    if @aLink
      "rowlink-skip"


Template.reactiveTableRow.events

  'click td': (event, tmpl) ->
    if Template.parentData(1).options.rowLink? and not $(event.currentTarget).hasClass('rowlink-skip')
      Template.parentData(1).options.rowLink(@.record)


  'click .reactive-table-delete-record': (event, tmpl) ->
    console.log("delete", @,  Template.parentData(1)) if DEBUG
    closeTooltip(tmpl)
    Template.parentData(1).onRemoveRecord?(@)
    closeTooltip(tmpl)


  'click .reactive-table-edit-record': (event, tmpl) ->
    console.log("edit: TODO: Enable Modal Edit?", @,  Template.parentData(1)) if DEBUG
    closeTooltip(tmpl)
    Template.parentData(1).onUpdateRecord?(@)
    closeTooltip(tmpl)



Template.reactiveTableCell.onRendered ->
  #M.Modal.init(@findAll('.modal'))
  M.Modal.init(@$('.modal'))
  initTooltip(@)
  

Template.reactiveTableCell.onDestroyed ->
  console.log("reactiveTableCell toolTips", @toolTips) if DEBUG
  destroyTooltip(@)

