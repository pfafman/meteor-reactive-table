
DEBUG = true


class @ReactiveTable
  classID: 'ReactiveTable'
  
  collection       : null
  selfPublish      : true
  recordName       : 'Record'
  colToUseForName  : 'name'
  sortColumn       : 'name'
  schema           : null
  downloadFields   : null
  rowLink          : null
  tableCreateError : 'Error creating Table'
  newRecordText    : "New Record"
  # methodOnInsert   : 'insertTestDataRecord'
  # methodOnUpdate   : 'updateTestDataRecord'
  # methodOnRemove   : 'removeTestDataRecord'
  

  constructor: (@options = {}) ->
    if Meteor.isClient
      @dict = new ReactiveDict(@_dictName())
    @setup()

  
  _dictName: ->
    "reactiveTable_" + @_id()


  _id: ->
    @options.id or @collection?._name


  name: ->
    @collection?._name


  countName: ->
    @name() + 'Count'

  
  publicationName: ->
    'reactiveTable_publish_' + @name()

  
  pubSelectFilter: (select, pub) ->
    select


  # Can overwrite
  publishser: (pub, select, sort, limit, skip) =>
    select = @pubSelectFilter(select, pub)
    if select?
      if @countName()
        publishCount pub, @countName(), @collection.find(select),
          noReady: true
      @collection.find select,
        sort: sort
        limit: limit
        skip: skip
    else
      pub.ready()


  setup: ->
    collection = @collection
    name = @name()
    if Meteor.isServer
      if @selfPublish
        publishFunc = @publishser
    
        Meteor.publish @publicationName(), (select, sort, limit, skip) ->
          console.log("publish via ReactiveTable", name, select, sort, limit, skip) if DEBUG
          check(select, Match.Optional(Match.OneOf(Object, null)))
          check(sort, Match.Optional(Match.OneOf(Object, null)))
          check(skip, Match.Optional(Match.OneOf(Number, null)))
          check(limit, Match.Optional(Match.OneOf(Number, null)))
          
          publishFunc(@, select, sort, limit, skip)


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



class @ReactiveTableInstance
  classID: 'ReactiveTableInstance'

  defaults:
    recordName: 'record'
    colToUseForName : '_id'
    limit           : 10
    sortColumn      : '_id'
    sortDirection   : 1

    defaultSelect   : {}
    showFilter      : false
    formTemplate    : 'reactiveTableForm'
    errorMessage    : ''
    cursor          : null
    
    _subscriptionComplete: false


  constructor: (tableClass, options = {}) ->
    @collection = tableClass.collection
    console.log("ReactiveTable constructor", @, @collection) if DEBUG

    @options = _.defaults(options, _.omit(tableClass, ['setUp', 'newTable']), @defaults)

    throw new Error("ReactiveTable: must specify collection") unless @collection instanceof Mongo.Collection

    for key in ['showFilter', 'formTemplate', 'methodOnInsert', 'methodOnUpdate', 'methodOnRemove']
      if @options?[key]?
        @[key] = @options[key]
      else if tableClass?[key]
        @[key] = tableClass?[key]

    @dict = tableClass.dict

    @setDefault("limit", @options.limit)
    @setDefault("skip", 0)
    @setDefault("select", @options.defaultSelect)

    @setDefault("filterColumn", null)
    @setDefault("filterValue", '')
    @setDefault("sortColumn", @options.sortColumn)
    @setDefault("sortDirection", @options.sortDirection)
    

  reset: ->
    @set("limit", @options.limit)
    @set("skip", 0)
    @set("select", @options.defaultSelect)

    @set("filterColumn", null)
    @set("filterValue", '')
    @set("sortColumn", @options.sortColumn)
    @set("sortDirection", @options.sortDirection)


  setDefault: (key, val) ->
    @dict.setDefault(@options?.id + key, val)


  set: (key, val) ->
    @dict.set(@options?.id + key, val)


  get: (key) ->
    @dict.get(@options?.id + key)


  publicationName: ->
    @options.publicationName()


  sort: ->
    sort = {}
    sort[@get('sortColumn')] = @get('sortDirection')
    sort


  select: ->
    select = _.extend({}, @get('select'))
    filterColumn = @get('filterColumn')
    filterValue = @get('filterValue')
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
    @get('limit')


  skip: ->
    @get('skip')


  increment: ->
    @options.limit


  pageUp: ->
    next = @get('skip') + @options.limit
    if next < @recordCount()
      @set('skip', next)


  pageDown: ->
    next = @get('skip') - @options.limit
    if next > 0
      @set('skip', next)
    else
      @set('skip', 0)


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
      colName = col.header or key
      if T9n?
        colName = T9n.get(colName, false)
      rtn.push
        key: key
        dataKey: dataKey
        colName: colName
        column: col
        noSort: col.noSort
        sort: dataKey is @get('sortColumn')
        desc: @get('sortDirection') is -1
        filterOnThisCol: dataKey is @get('filterColumn')
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


  formData: (type, id = null) ->
    if type is 'edit' and id?
      record = @collection.findOne(id)
    else
      record = null

    if @extraFormData?
      _.extend(record, @extraFormData(type))

    if @formTemplate is 'reactiveTableForm'
      recordData = []

      for key, col of @_cols()
        dataKey = col.dataKey or col.sortKey or key
        localCol = _.clone(col)
        if col[type]?(record) or (col[type] is true) or col["staticOn_#{type}"] or col["hiddenOn_#{type}"]
          if col["hiddenOn_#{type}"]
            col.type = 'hidden'
          if not col.type?
            col.type = 'text'
          localCol.displayType = col.type
          localCol.checkbox = false
          localCol.checked = false
          value = @valueFromRecord(key, col, record)
          if col.type is 'boolean'
            localCol.displayType = 'checkbox'
            localCol.checkbox = true
            if record?[dataKey]?
              if record[dataKey]
                localCol.checked = true
            else if col.default
              localCol.checked = true
          else if value?
            localCol.value = value
          else if col.default?
            localCol.value = col.default

          localCol.realValue = value

          if col["staticOn_#{type}"]
            localCol.static = true
            localCol.value = value
            if col?.valueFunc?
              localCol.realValue = record[key]

          if col["hiddenOn_#{type}"]
            localCol.hidden = true
            localCol.value = value
            if col?.valueFunc?
              localCol.realValue = record[key]

          localCol.header = (col.header or key).capitalize()
          localCol.key = key
          localCol.dataKey = dataKey

          recordData.push localCol
      columns: recordData
    else
      record


  setSort: (dataKey) ->
    if dataKey is @get('sortColumn')
      @set('sortDirection', -@get('sortDirection'))
    else
      @set('sortColumn', dataKey)
      @set('sortDirection', @options.sortDirection)
    @set('skip', 0)


  setFilterColumn: (col) ->
    if @get('filterColumn') isnt col
      @set('filterColumn', col)
      @set('filterValue', '')
      @set('skip', 0)
      


  setFilterValue: (value) ->
    console.log("setFilterValue", value) if DEBUG
    if @get('filterValue') isnt value
      @set('filterValue', value)
      @set('skip', 0)
      

  filterValue: ->
    @get('filterValue')

    
  filterType: ->
    filterColumn = @get('filterColumn')
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
    @options.recordName or @name()


  recordsName: ->
    @options.recordsName or @recordName()+'s'

  
  colToUseForName: ->
    @options.colToUseForName or '_id'
  
  
  editRecordTitle: ->
    T9n.get('Edit') + ' ' + @recordName().capitalize()


  editRecord: (_id) ->
    @_sess("currentRecordId", _id)
    MaterializeModal.form
      bodyTemplate: @formTemplate
      title: @editRecordTitle()
      columns: @formData('edit', _id).columns
      callback: @updateRecord
      fullscreen: Meteor.isCordova
      fixedFooter: true


  updateRecord: (yesNo, rec) =>
    @errorMessage = ''
    if yesNo
      rec = {} unless rec
      rec._id = @_sess("currentRecordId") unless rec._id?
      if @collection().editOk(rec)
        @updateThisRecord(@_sess("currentRecordId"), rec)


  updateThisRecord: (recId, rec, type="update") =>
    console.log("updateThisRecord", recId, rec)
    if @checkFields(rec, type)
      if @collection().methodOnUpdate
        Meteor.call @collection().methodOnUpdate, recId, rec, (error) =>
          if error
            console.log("Error updating " + @_recordName(), error)
            Materialize.toast("Error updating " + @_recordName() + " : #{error.reason}", 3000, 'red')
          else if type isnt "inlineUpdate"
            Materialize.toast(@_recordName() + " saved", 3000, 'green')
            @fetchRecordCount()
      else
        delete rec._id
        @collection().update recId,
          $set: rec
        , (error, effectedCount) =>
          if error
            console.log("Error updating " + @_recordName(), error)
            Materialize.toast("Error updating " + @_recordName() + " : #{error.reason}", 3000, 'red')
          else
            if type isnt "inlineUpdate"
              Materialize.toast(@_recordName() + " updated", 3000, 'green')
            @fetchRecordCount()
    else
      Materialize.toast("Error could not update " + @_recordName() + " " + @errorMessage, 3000, 'red')


  newRecord: ->
    if @newRecordRoute?
      Router.go(@newRecordPath)  # Should already be handled
    else
      console.log("formData", @formTemplate, @formData('insert')) if DEBUG
      MaterializeModal.form
        bodyTemplate: @formTemplate
        title: 'New ' + @recordsName().capitalize()
        columns: @formData('insert').columns
        callback: @insertRecord
        fullscreen: Meteor.isCordova
        fixedFooter: true
  

  insertRecord: (yesNo, rec) =>
    @errorMessage = ''
    if yesNo
      if @collection.insertOk(rec) and @checkFields(rec, 'insert')
        if @collection.methodOnInsert
          Meteor.call @collection().methodOnInsert, rec, (error) =>
            if error
              console.log("Error saving " + @_recordName(), error)
              Materialize.toast("Error saving " + @_recordName() + " : #{error.reason}", 3000, 'red')
            else
              Materialize.toast(@_recordName() + " created", 3000, 'green')
              @fetchRecordCount()
              @newRecordCallback?(rec)
        else
          @collection().insert rec, (error, effectedCount) =>
            if error
              console.log("Error saving " + @_recordName(), error)
              Materialize.toast("Error saving " + @_recordName() + " : #{error.reason}", 3000, 'red')
            else
              Materialize.toast(@_recordName() + " created", 3000, 'green')
              @fetchRecordCount()
              @newRecordCallback?(effectedCount)
      else
        Materialize.toast("Error could not save " + @_recordName() + " " + @errorMessage, 3000, 'red')


