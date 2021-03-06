jraphical = require 'jraphical'

module.exports = class JStorage extends jraphical.Module

  { secure } = require 'bongo'

  @share()

  @set
    indexes       :
      username    : 'name'
    sharedEvents  :
      static      : []
      instance    : []
    schema        :
      name        : String
      content     :
        type      : Object
        default   : -> {}
