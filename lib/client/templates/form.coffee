
DEBUG = false

capitalize = (string) ->
  string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()
  

Template.reactiveTableFormItem.onRendered ->
  #console.log("reactiveTableFormItem rendered")
  @$('[rel="tooltip"]').tooltip()
  @$('.datepicker')?.pickadate
    selectMonths: false
    selectYears: false
    hiddenName: true
    formatSubmit: 'yyyy-mm-dd'
  #$('.timepicker')?.pickatime()


Template.reactiveTableFormItem.onDestroyed ->
  @$('[rel="tooltip"]').tooltip('remove')


Template.reactiveTableFormItem.helpers

  textArea: ->
    @displayType is 'textarea'


  patternValue: ->
    if @pattern
      @pattern
    else if @displayType is 'number'
      "[0-9]*"


  forKey: ->
    if @displayType isnt 'select'
      @key


  inputTemplate: ->
    rtn = ""
    if @inputFormTemplate
      rtn = @inputFormTemplate
    else
      switch @displayType
        when 'textarea', 'select', 'checkbox', 'date', 'range'
          type = capitalize(@displayType)
          rtn = "reactiveTableForm#{type}"
        else
          rtn = "reactiveTableFormInput"
    console.log("inputTemplate", rtn) if DEBUG
    rtn


  showHelpText: ->
    @helpText? and not @static?


Template.reactiveTableFormSelect.onRendered ->
  @$('select').material_select()


Template.reactiveTableFormDate.helpers
  dateValue: ->
    moment(@value).format('D MMMM, YYYY')
