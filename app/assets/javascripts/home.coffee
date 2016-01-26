# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@render_wiki = (text, elem_id) ->
  ajax_query = () ->
    $.ajax({
      type: 'post',
      url: '/home/render_wiki',
      data: {
        text: text
      },
      success: (data) ->
        $("##{elem_id}")[0].innerHTML = data['wiki']
        return
      error: (err) ->
        console.log err.toString()
        return
    })
    return
  if window.render_timer?
    window.clearTimeout window.render_timer
  window.render_timer = window.setTimeout(ajax_query, 500)
  return
