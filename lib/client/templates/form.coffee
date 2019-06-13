
DEBUG = false

capitalize = (string) ->
  string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()


Template.reactiveTableForm.onRendered ->
  console.log("reactiveTableForm rendered") if DEBUG


Template.reactiveTableFormItem.onRendered ->
  #console.log("reactiveTableFormItem rendered")
  @$('[rel="tooltip"]').tooltip()


Template.reactiveTableFormItem.onDestroyed ->
  @$('[rel="tooltip"]')?.destroy?()


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


Template.reactiveTableFormInput.helpers
  valueNotNull: ->
    @value?


Template.reactiveTableFormRange.helpers
  valueNotNull: ->
    @value?


Template.reactiveTableFormSelect.onRendered ->
  console.log("reactiveTableFormSelect: init select") if DEBUG
  @$('select').formSelect()
  # instance = M.FormSelect.init @find('select'),
  #   dropdownOptions:
  #     coverTrigger: false


Template.reactiveTableFormDate.onRendered ->
  console.log("reactiveTableFormDate onRendered", @) if DEBUG
  @$('.datepicker')?.datepicker
    selectMonths: false
    selectYears: false
    hiddenName: true
    format: 'yyyy-mm-dd'
    #onOpen: ->
    #  console.log("datepicker is open")


Template.reactiveTableFormDate.helpers
  dateValue: ->
    console.log("reactiveTableFormDate #{moment(@value).format('YYYY-MM-DD')}", @value) if DEBUG
    if @value
      moment(@value).format('YYYY-MM-DD')

