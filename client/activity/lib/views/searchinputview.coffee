kd = require 'kd'
KDHitEnterInputView = kd.HitEnterInputView
module.exports = class SearchInputView extends KDHitEnterInputView

  constructor: (options = {}, data) ->

    options.cssClass     = kd.utils.curry 'search-input', options.cssClass
    options.placeholder ?= 'Search'
    options.type        ?= 'input'
    options.stayFocused ?= yes

    super options, data

    @lastValue = null
    {router}   = kd.singletons

    @on 'EnterPerformed', =>

      value = @getValue().trim()

      if value is ''
        router.handleRoute "/Activity/Public/Recent"
        @lastValue = value
        @setBlur()
        return

      return  if value is @lastValue

      router.handleRoute "/Activity/Public/Search?q=#{value}"

      @setFocus()

    @on 'EscapePerformed', =>
      router.handleRoute "/Activity/Public/Recent"
      @setValue ''
      @lastValue = ''
      @setBlur()


  clear: ->

    @setValue ""

    super
