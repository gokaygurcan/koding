kd             = require 'kd'
hljs           = require 'highlight.js'
dateFormat     = require 'dateformat'

JView          = require 'app/jview'
curryIn        = require 'app/util/curryIn'
objectToString = require 'app/util/objectToString'


module.exports = class OutputView extends kd.ScrollView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'output has-markdown'

    super options, data

    @container = new kd.CustomHTMLView
      tagName  : 'pre'
      cssClass : 'output-view'

    @code = @container.addSubView new kd.CustomHTMLView
      tagName  : 'code'

    @highlight = (@getOption 'highlight') or 'profile'


  raise : -> @setClass   'raise'

  fall  : -> @unsetClass 'raise'

  clear : ->

    @code.updatePartial ''
    return this

  stringify = (content) ->

    for item,i in content
      content[i] = if typeof item is 'object' \
                   then objectToString item else item

    content = content.join ' '


  add: (content...) ->

    content = stringify content
    content = "[#{dateFormat Date.now(), 'HH:MM:ss'}] #{content}\n"
    @code.setPartial hljs.highlight(@highlight, content).value
    @scrollToBottom()

    return this


  set: (content...) ->

    content = stringify content
    @code.updatePartial hljs.highlight(@highlight, content).value
    @scrollToBottom()

    return this


  handleError: (err) ->
    return no  unless err

    kd.warn '[outputView]', err
    @add 'An error occured:', err.message or err


  pistachio: ->
    """{{> @container}}"""