# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


jQuery ->
  # Trigger maximage
  jQuery('#maximage').maximage
    cycleOptions:
      fx: 'fade'
      speed: 5000
      timeout: 100
