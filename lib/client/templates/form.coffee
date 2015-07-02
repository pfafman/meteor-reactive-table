
DEBUG = false


capitalize = (string) ->
  string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()
  

Template.reactiveTableFormItem.onRendered ->
  #console.log("reactiveTableFormItem rendered")
  @$('[rel="tooltip"]').tooltip()
  @$('select').material_select()
  @$('.datepicker')?.pickadate
    selectMonths: false
    selectYears: false
  #$('.timepicker')?.pickatime()


Template.reactiveTableFormItem.helpers
  textArea: ->
    @displayType is 'textarea'

  forKey: ->
    if @displayType isnt 'select'
      @key


  inputTemplate: ->
    rtn = 'reactiveTableFormInput'
    switch @displayType
      when 'textarea', 'select', 'checkbox', 'date'
        type = capitalize(@displayType)
        rtn = "reactiveTableForm#{type}"
      else
        rtn = 'reactiveTableFormInput'
    rtn

  showHelpText: ->
    @helpText? and not @static?
