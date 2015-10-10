
DEBUG = false


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
  fixedFooter      : false
  
  # methodOnInsert   : 'insertTestDataRecord'
  # methodOnUpdate   : 'updateTestDataRecord'
  # methodOnRemove   : 'removeTestDataRecord'
  
  downLoadPermissionsAndSelect: ->
    throw new Meteor.Error("accessError", "No Access")

  constructor: (@options = {}) ->
    if Meteor.isClient
      @dict = new ReactiveDict(@_dictName())
    
    for key in ['methodOnInsert', 'methodOnUpdate', 'methodOnRemove', 'updateOk', 'insertOk', 'removeOk', 'removeAllOk']
      if @options?[key]?
        @[key] = @options[key]

    @setup()

  
  _dictName: ->
    "reactiveTable_" + @_id()


  _id: ->
    @options.id or @collection?._name


  name: ->
    @_id()


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
    meths["reactiveTable_" + name + "_getCSV"] = (select = {}, fields = {}) =>
      check(select, Object)
      check(fields, Object)
      select = @downLoadPermissionsAndSelect?(select) or select
      console.log("reactiveTable getCSV", name, JSON.stringify(select)) if DEBUG
      csv = []
      fieldKeys = _.keys(fields)
      csv.push fieldKeys.join(',')
      cursor = collection.find? select,
        fields: fields
      console.log("reactiveTable getCSV count", cursor?.count())
      if cursor?.forEach?
        cursor.forEach (rec) ->
          row = []
          for fieldKey in fieldKeys
            subElements = fieldKey.split('.')
            value = rec
            for subElement in subElements
              value = value?[subElement]
            if typeof value is 'object'
              value = JSON.stringify(value)
            if typeof value is 'string'
              value = value.replace(/\"/g, "'")
            row.push '"' + value + '"'
          csv.push row.join(',')
      else
        console.log("eactiveTable getCSV no data", select, collection.find)
      csv.join("\n")
            
    Meteor.methods meths


  newTable: (options = {}) ->
    new ReactiveTableInstance(@, options)


  # Overrides ...
  insertOk: (record)->
    false

  updateOk: (record) ->
    false

  removeAllOk: ->
    false

  removeOk: (record) ->
    false



class @ReactiveTableInstance
  classID: 'ReactiveTableInstance'

  defaults:
    recordName      : 'Record'
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
    @name = tableClass.name()
    
    console.log("ReactiveTable constructor", @, @collection) if DEBUG

    @options = _.defaults(options, _.omit(tableClass, ['setUp', 'newTable']), @defaults)

    throw new Error("ReactiveTable: must specify collection") unless @collection instanceof Mongo.Collection

    optionKeys = [
      'showFilter'
      'formTemplate'
      'methodOnInsert'
      'methodOnUpdate'
      'methodOnRemove'
      'updateOk'
      'insertOk'
      'removeOk'
      'removeAllOk'
      'tableClass'
      'newRecordText'
      'downloadFields'
      'downLoadPermissionsAndSelect'
      'fixedFooter'
    ]

    for key in optionKeys
      if @options?[key]?
        @[key] = @options[key]
      else if tableClass?[key]
        @[key] = tableClass[key]
      else if @collection?[key]
        @[key] = @collection[key]

    @dict = tableClass.dict

    if Router.current().params?.query?.back
      @setDefault("limit", @options.limit)
      @setDefault("skip", 0)
      @setDefault("select", @options.defaultSelect)

      @setDefault("filterColumn", null)
      @setDefault("filterValue", '')
      @setDefault("sortColumn", @options.sortColumn)
      @setDefault("sortDirection", @options.sortDirection)
    else
      @reset()


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
    theColumns = @options.schema or @schema or @collection?.schema
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
      if not col.hide?() #or col.hide)
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
          hide: col.hide?() or col.hide
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
        if not col.hide?() #or col.hide)
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
        updateOk: @updateOk(record)
        removeOk: @removeOk(record)
        #extraControls: @extraControls?(record)
    
    recordsData


  formData: (type, currentRecord = null) ->
    typeCap = type.capitalize()
    if type is 'update' and currentRecord?
      record = currentRecord
    else
      record = null

    if @extraFormData?
      _.extend(record, @extraFormData(type))

    if @formTemplate is 'reactiveTableForm'
      recordData = []

      for key, col of @_cols()
        dataKey = col.dataKey or col.sortKey or key
        localCol = _.clone(col)
        if col[type]?(record) or (col[type] is true) or col["staticOn#{typeCap}"] or col["hiddenOn#{typeCap}"]
          if col["hiddenOn#{typeCap}"]
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

          if col["staticOn#{typeCap}"]
            localCol.static = true
            localCol.value = value
            if col?.valueFunc?
              localCol.realValue = record[key]

          if col["hiddenOn#{typeCap}"]
            localCol.hidden = true
            localCol.value = value
            if col?.valueFunc?
              localCol.realValue = record[key]

          localCol.header = (col.header or key).capitalize()
          localCol.key = key
          localCol.dataKey = dataKey
          localCol.record = record

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
    @options.recordName


  recordsName: ->
    @options.recordsName or @recordName()+'s'

  
  colToUseForName: ->
    @options.colToUseForName or '_id'
  
  
  # CRUD

  checkFields: (rec, type="insert") ->
    @errorMessage = ''
    typeCap = type.capitalize()
    for key, col of @_cols()
      try
        console.log("checkFields", type, typeCap, key, col) if DEBUG
        if key isnt '_id' and (not col[type] or col["staticOn#{typeCap}"]) and not col["on#{typeCap}"]?
          delete rec[key]
        else
          dataKey = col.dataKey or col.sortKey or key
          console.log("checkFields", dataKey, rec[dataKey], col) if DEBUG
          if type isnt "inlineUpdate" and col.required and (not rec[dataKey]? or rec[dataKey] is '')
            col.header = (col.header || key).capitalize()
            @errorMessage = ':' + "#{col.header} is required"
            return false
          else if col["on#{typeCap}"]?
            rec[dataKey] = col["on#{typeCap}"](rec)
          else if type in ['update', 'inlineUpdate'] and col.onUpdate?
            rec[dataKey] = col.onUpdate(rec)
      catch error
        @errorMessage = ':' + error.reason or error
        return false
    true


  onInsertRecord: ->
    if @options.onInsertRecord?  and typeof @options.onInsertRecord is 'function'
      @options.onInsertRecord()
    else
      if @newRecordRoute?
        Router.go(@newRecordPath)  # Should already be handled
      else
        console.log("formData", @formTemplate, @formData('insert')) if DEBUG
        title =  @newRecordText or 'New ' + @recordsName().capitalize()
        MaterializeModal.form
          bodyTemplate: @formTemplate
          title: title
          columns: @formData('insert').columns
          callback: @insertRecord
          fullscreen: Meteor.isCordova
          fixedFooter: @fixedFooter
          #fixedFooter: true
  

  insertRecord: (error, rtn) =>
    if error
      Materialize.toast("Error could not save " + @recordName() + " " + @errorMessage, 3000, 'toast-error')
    else if rtn?.submit
      @errorMessage = ''
      rec = rtn.value
      console.log("insertRecord", @methodOnInsert, rec) if DEBUG
      if @insertOk(rec) and @checkFields(rec, 'insert')
        if @methodOnInsert
          Meteor.call @methodOnInsert, rec, (error, rtn) =>
            if error
              console.log("Error saving " + @recordName(), error)
              Materialize.toast("Error saving " + @recordName() + " : #{error.reason}", 3000, 'toast-error')
            else
              Materialize.toast(@recordName() + " created", 3000, 'green')
              @insertRecordCallback?(rtn or rec)
        else
          @collection.insert rec, (error, effectedCount) =>
            if error
              console.log("Error saving " + @recordName(), error)
              Materialize.toast("Error saving " + @recordName() + " : #{error.reason}", 3000, 'toast-error')
            else
              Materialize.toast(@recordName() + " created", 3000, 'green')
              @insertRecordCallback?(rec)
      else
        Materialize.toast("Error could not save " + @recordName() + " " + @errorMessage, 3000, 'toast-error')


  updateRecordTitle: ->
    T9n.get('edit').capitalize() + ' ' + @recordName().capitalize()


  onUpdateRecord: (rec) ->
    #@currentRecordId = rec._id
    console.log("onUpdateRecord", rec, @) if DEBUG
    throw new Metoer.eror("badData", "No record Id") if not rec?._id
    @currentRecord = @collection.findOne
      _id: rec._id
    throw new Metoer.eror("badData", "No record found to update") if not rec?._id
    if @options?.onUpdateRecord? and typeof @options.onUpdateRecord is 'function'
      @options.onUpdateRecord(rec, @currentRecord)
    else
      MaterializeModal.form
        bodyTemplate: @formTemplate
        title: @updateRecordTitle()
        columns: @formData('update', @currentRecord).columns
        callback: @updateRecord
        fullscreen: Meteor.isCordova
        fixedFooter: @fixedFooter
        #fixedFooter: true


  updateRecord: (error, rtn) =>
    if error
      Materialize.toast("Error updating " + @recordName() + " " + error.reason, 3000, 'toast-error')
    else if rtn.submit
      @errorMessage = ''
      rec = {} unless rtn.value
      rec._id = @currentRecord._id #unless rec._id?
      if @updateOk(@currentRecord)   # Do Check on current record not what record will become !!!
        _.extend(@currentRecord, rec)
        @updateThisRecord(@currentRecord._id, rec)
      else
        Materialize.toast("Error updating " + @recordName() + " : Insufficient permissions", 3000, 'toast-error')
    @currentRecord = null


  updateThisRecord: (recId, rec, type="update") =>
    console.log("updateThisRecord", recId, rec) if DEBUG
    if @checkFields(rec, type)
      if @methodOnUpdate
        Meteor.call @methodOnUpdate, recId, rec, (error, rtn) =>
          if error
            console.log("Error updating " + @recordName(), error)
            Materialize.toast("Error updating " + @recordName() + " : #{error.reason}", 3000, 'toast-error')
          else if type isnt "inlineUpdate"
            Materialize.toast(@recordName() + " saved", 3000, 'green')
            @updateRecordCallback?(rtn or rec)
      else
        delete rec._id
        @collection.update recId,
          $set: rec
        , (error, effectedCount) =>
          if error
            console.log("Error updating " + @recordName(), error)
            Materialize.toast("Error updating " + @recordName() + " : #{error.reason}", 3000, 'toast-error')
          else
            if type isnt "inlineUpdate"
              Materialize.toast(@recordName() + " updated", 3000, 'green')
              @updateRecordCallback?(rec)
    else
      Materialize.toast("Error could not update " + @recordName() + " " + @errorMessage, 3000, 'toast-error')


  onRemoveRecord: (rec) ->
    if @options.onRemoveRecord?  and typeof @options.onRemoveRecord is 'function'
      @options.onRemoveRecord(rec)
    else
      if rec.recordName?
        recName = " <i>#{rec.recordName}</i>?"
      else
        recName = "?"
      MaterializeModal.confirm
        title: "Delete #{@recordName()}"
        message: "Are you sure you want to delete #{@recordName()}#{recName}"
        callback: (error, rtn) =>
          if error
            Materialize.toast("Error on delete: #{error.reason}", 4000, 'toast-error')
          else if rtn?.submit
            Meteor.call @methodOnRemove, rec._id, (error, result) ->
              if error
                Materialize.toast("Error on delete: #{error.reason}", 4000, 'toast-error')
                @removeRecordCallback?()


  downloadRecords: (callback, select, downloadFields) =>
    
    select = @select() unless select

    fields = {}
    if downloadFields
      fields = downloadFields
    else if @downloadFields?
      fields = @downloadFields
    else
      for key, col of @_cols()
        dataKey = col.dataKey or col.sortKey or key
        fields[dataKey] = 1

    console.log("downloadRecords", @name, select, fields) if DEBUG
    
    Meteor.call "reactiveTable_" + @name + "_getCSV", select, fields, callback
