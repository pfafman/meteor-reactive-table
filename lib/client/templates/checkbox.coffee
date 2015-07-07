DEBUG = false


Template.reactiveTableCheckbox.onCreated ->
  @active = new ReactiveVar(false)
  

Template.reactiveTableCheckbox.helpers
  doEdit: ->
    @column?.contenteditable #and Template.instance().active?.get()

  checkedMark: ->
    @column?.checkedMark or 'done'

  notCheckMark: ->
    if not @column?.blankOnNotChecked
      @column?.notCheckMark or 'check_box_outline_blank'


Template.reactiveTableCheckbox.events

  "click .check-mark": (e, tmpl) ->
    if Template.parentData(1).editOk
      tmpl.active.set(true)


  "mouseenter .check-mark": (e, tmpl) ->
    #console.log('mouseenter')


  "mouseleave .check-mark": (e, tmpl) ->
    #console.log('mouseleave')
    tmpl.active.set(false)


  "mouseleave .check-mark-checkbox": (e, tmpl) ->
    #console.log('mouseleave checkbox')
    tmpl.active.set(false)


  "click .check-mark-checkbox": (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()
    if Template.parentData(1).editOk
      console.log("change checkbox value", @value)
      if @value
        newValue = false
      else
        newValue = true

      #if Router.current?()?.classID is "reactiveTableController"
      #  console.log("Submit Value Change", @dataKey, @value, '->', newValue)
      #  data = {}
      #  data[@dataKey] = newValue
      #  Router.current().updateThisRecord?(@record._id, data, 'inlineUpdate')

        
