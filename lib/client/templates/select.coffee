
DEBUG = false

Template.reactiveTableSelect.onCreated ->
  @active = new ReactiveVar(false)


Template.reactiveTableSelectSelect.onRendered ->
  console.log("reactiveTableSelectSelect: init select")
  @$('select').formSelect()


Template.reactiveTableSelect.helpers
  doEdit: ->
    @column?.contenteditable #and Template.instance().active?.get()

  getValue: ->
    @select?[@value] or @value


Template.reactiveTableOptions.helpers
  options: ->
    if @select?
      rtn = []
      if @placeholder
        rtn.push
          key: ''
          val: @placeholder
          disabled: 'disabled'
          
      if _.isFunction(@select)
        select = @select()
      else
        select = @select

      console.log("select:", select, @select) if DEBUG
      if _.isArray(select)
        for elm in select
          if _.isObject(elm)
            rtn.push
              key: elm.key
              val: elm.val
              selected: if @value is elm.val then 'selected'
              disabled: "disabled" if elm.disabled
          else
            rtn.push
              key: elm
              val: elm
              selected: if @value is elm then 'selected'
              disabled: "disabled" if elm.disabled
      else if _.isObject(select)
        for key, val of select
          rtn.push
            key: key
            val: val
            selected: if @value is key then 'selected'
            #disabled: elm.disabled
      rtn


Template.reactiveTableSelect.events

  "click .select-view": (e, tmpl) ->
    if Template.parentData(1).editOk
      console.log('select clicked', @record._id, e, tmpl)
      tmpl.active.set(true)
      
  "mouseenter .select": (e, tmpl) ->
    #console.log('mouseenter')

  "mouseleave .select": (e, tmpl) ->
    tmpl.active.set(false)
    
  "mouseleave .select-div": (e, tmpl) ->
    tmpl.active.set(false)
    
  "change select": (e, tmpl) ->
    e.preventDefault()
    e.stopImmediatePropagation()
    # if Template.parentData(1).editOk and Router.current?()?.classID is "reactiveTableController"
    #   console.log("Submit Value Change", @dataKey, @value, '->', $(e.target).val())
    #   data = {}
    #   data[@dataKey] = $(e.target).val()
    #   Router.current().updateThisRecord?(@record._id, data, 'inlineUpdate')



