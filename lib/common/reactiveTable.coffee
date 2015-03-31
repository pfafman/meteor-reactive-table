
DEBUG = true



class @ReactiveTable
  classID: 'ReactiveTable'
  
  collection      : null
  selfPublish     : true
  recordName      : 'Record'
  colToUseForName : 'name'
  sortColumn      : 'name'
  doRowLink       : true
  schema          : null
  downloadFields  : null
  #methodOnInsert  : 'insertTestDataRecord'
  #methodOnUpdate  : 'updateTestDataRecord'
  #methodOnRemove  : 'removeTestDataRecord'
  
  
  name: ->
    @collection?._name

  
  countName: ->
    @name() + 'Count'

  
  publicationName: ->
    'reactiveTable_publish_' + @name()

  
  constructor: (options = {}) ->
    @setup()


  setup: ->
    collection = @collection
    name = @name()
    if Meteor.isServer
      if @selfPublish
        countName  = @countName()
        publicationName = @publicationName()

        Meteor.publish publicationName, (select, sort, limit, skip) ->
          console.log("publish via ReactiveTable", countName, select, sort, limit, skip) if DEBUG
          check(select, Match.Optional(Match.OneOf(Object, null)))
          check(sort, Match.Optional(Match.OneOf(Object, null)))
          check(skip, Number)
          check(limit, Number)
          
          if countName
            publishCount @, countName, collection.find(select),
              noReady: true

          collection.find select,
            sort: sort
            limit: limit
            skip: skip


    meths = {}
    
    #if true #@doDownloadLink
    meths["reactiveTable_" + name + "_getCSV"] = (select = {}, fields = {}) ->
      csv = []
      fieldKeys = _.keys(fields)
      csv.push fieldKeys.join(',')
      cursor = collection.find? select,
        fields: fields
      if cursor?.forEach?
        cursor.forEach (rec) ->
          row = []
          for fieldKey in fieldKeys
            subElements = fieldKey.split('.')
            value = rec
            for subElement in subElements
              value = value?[subElement]
            row.push value
          csv.push row.join(',')
      csv.join("\n")
            
    Meteor.methods meths


  newTable: (options = {}) ->
    new ReactiveTableInstance(@, options)


  # Overrides ...
  insertOk: (record)->
    false

  deleteAllOk: ->
    false

  deleteOk: (record) ->
    false

  editOk: (record) ->
    false



class ReactiveTableInstance

  defaults:
    recordName: 'record'
    colToUseForName : '_id'
    limit           : 10
    sortColumn      : '_id'
    sortDirection   : 1

    defaultSelect   : {}
    showFilter      : false
    errorMessage    : ''
    cursor          : null
    
    _subscriptionComplete: false


  constructor: (tableClass, options = {}) ->
    @collection = tableClass.collection
    console.log("ReactiveTable constructor", @, @collection) if DEBUG

    @options = _.defaults(options, _.omit(tableClass, ['setUp', 'newTable']), @defaults)

    throw new Error("ReactiveTable: must specify collection") unless @collection instanceof Mongo.Collection

    @_limit  = new ReactiveVar(@options.limit)
    @_skip   = new ReactiveVar(0)
    @_select = new ReactiveVar(@options.defaultSelect)
    
    @filterColumn  = new ReactiveVar()
    @filterValue   = new ReactiveVar('')
    @sortColumn    = new ReactiveVar(@options.sortColumn)
    @sortDirection = new ReactiveVar(@options.sortDirection)


  publicationName: ->
    @options.publicationName()


  sort: ->
    sort = {}
    sort[@sortColumn.get()] = @sortDirection.get()
    sort


  select: ->
    select = _.extend({}, @_select.get())
    filterColumn = @filterColumn.get()
    filterValue = @filterValue.get()
    col = @_cols()[filterColumn]
    if filterColumn? and filterColumn isnt "_none_"
      dataKey = col.dataKey or col.sortKey or filterColumn
      if col.type is 'boolean'
        if filterValue
          select[dataKey] = filterValue
        else
          select[dataKey] =
            $ne: true
      else if filterValue and col and filterValue isnt ''
        select[dataKey] =
          $regex: ".*#{filterValue}.*"
          $options: 'i'
    select


  limit: ->
    @_limit.get()


  skip: ->
    @_skip.get()


  increment: ->
    @options.limit

  pageUp: ->
    next = @_skip.get() + @options.limit
    if next < @recordCount()
      @_skip.set(next)

  pageDown: ->
    next = @_skip.get() - @options.limit
    if next > 0
      @_skip.set(next)
    else
      @_skip.set(0)


  _cols: ->
    theColumns = @options.schema or @collection?.schema
    if theColumns instanceof Array
      colObj = {}
      for col in theColumns
        colObj[col] = {}
    else
      colObj = theColumns
    colObj


  headers: ->
    rtn = []
    for key, col of @_cols()
      #if not (col.hide?() or col.hide)
      dataKey = col.dataKey or col.sortKey or key
      if col.canFilterOn? and not col.hide?()
        canFilterOn = col.canFilterOn
      else
        canFilterOn = false
      tmpl = Template.instance()
      rtn.push
        key: key
        dataKey: dataKey
        colName: col.header or key
        column: col
        noSort: col.noSort
        sort: dataKey is @sortColumn.get()
        desc: @sortDirection.get() is -1
        filterOnThisCol: dataKey is @filterColumn.get()
        canFilterOn: canFilterOn
        hide: col.hide?()
    console.log("headers", rtn) if DEBUG
    rtn


  recordCount: ->
    Counts.get(@options.countName())


  records: ->
    @collection.find @select(),
      limit: @limit()
      #skip: @skip()
      sort: @sort()
    .fetch()


  recordsData: ->
    console.log('recordsData')
    recordsData = []
    cols = @_cols()
    for record in @records()
      colData = []
      for key, col of cols
        dataKey = col.dataKey or col.sortKey or key
        if not col.hide?()
          value = @valueFromRecord(key, col, record)
          if col.display?
            value = col.display(value, record)
          if col.type is 'boolean' and not col.template?
            col.template = 'reactiveTableCheckbox'
          else if col.type is 'select' and not col.template?
            col.template = 'reactiveTableSelect'
          colData.push
            type         : col.type
            template     : col.template
            record       : record  # Link to full record if we need it
            value        : value
            aLink        : col.link?(value, record)
            title        : col.title?(value, record) or col.title
            column       : col
            dataKey      : dataKey
            select       : col.select


      recordsData.push
        colData: colData
        _id: record._id
        recordName: record[@colToUseForName()]
        recordDisplayName: @recordName() + ' ' + record[@colToUseForName()]
        editOk: @options.editOk(record)
        deleteOk: @options.deleteOk(record)
        #extraControls: @extraControls?(record)
    
    recordsData


  setSort: (dataKey) ->
    if dataKey is @sortColumn.get()
      @sortDirection.set(-@sortDirection.get())
    else
      @sortColumn.set(dataKey)
      @sortDirection.set(@options.sortDirection)
    @_skip.set(0)


  setFilterColumn: (col) ->
    if @filterColumn.get() isnt col
      @filterColumn.set(col)
      @filterValue.set('')
      @_skip.set(0)
      


  setFilterValue: (value) ->
    console.log("setFilterValue", value) if DEBUG
    if @filterValue.get() isnt value
      @filterValue.set(value)
      @skip.set(0)
      


  getSelectedFilterType: ->
    filterColumn = @filterColumn.get()
    if filterColumn?
      switch (@_cols()?[filterColumn]?.type)
        when 'boolean'
          'checkbox'
        else
          'text'
    else
      'text'


  # Helpers
  valueFromRecord: (key, col, record) ->
    if record?
      if col?.valueFunc?
        value = col.valueFunc?(record[key], record)
      else if col?.dataKey?
        subElements = col.dataKey.split('.')
        value = record
        for subElement in subElements
          value = value?[subElement]
        value
      else if record[key]?
        record[key]


  recordName: ->
    @options.recordName or @collection._name


  recordsName: ->
    @options.recordsName or @recordName()+'s'


  colToUseForName: ->
    @options.colToUseForName or '_id'
  

  


