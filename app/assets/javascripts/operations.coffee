# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
@rule_selected = (select) ->
  if select.selectedOptions.length > 0
    selected = select.selectedOptions[0]
    if selected.getAttribute('data-has-second-class') == 'true'
      $('form').submit()
    else
      $('#p_fc2').remove()

@expand_or_collapse = (id, operation_id = null) ->
  $('#' + id).collapse('toggle')
  cookie_name = "expanded_#{operation_id}_#{id}"
  unless operation_id == null
    if getCookie(cookie_name) == 'expanded'
      document.cookie = "#{cookie_name}=collaped"
    else
      document.cookie = "#{cookie_name}=expanded"


@getCookie = (cname) ->
  name = cname + '='
  ca = document.cookie.split(';')
  for c in ca
    c = c.substring(1) while c.charAt(0) == ' '
    if c.indexOf(name) == 0
      return c.substring(name.length, c.length)
  return ''

@checkBoxShowsOrHidesElement = (checkbox_id, element_id) ->
  checked = $("##{checkbox_id}").is(':checked')
  if checked
    value = 'inline'
  else
    value = 'none'
  $("##{element_id}").css('display', value)
