whoami                   = require 'app/util/whoami'
actions                  = require '../actions/actiontypes'
toImmutable              = require 'app/util/toImmutable'
KodingFluxStore          = require 'app/flux/store'
MessageCollectionHelpers = require '../helpers/messagecollection'


###*
 * Immutable version of a social message. see toImmutable util.
 *
 * @typedef IMSocialMessage
###

###*
 * MessagesStore state represents a IMMessageCollection, in which keys are
 * messageIds and values are immutable version of associated SocialMessage
 * instances.
 *
 * @typedef {Immutable.Map<string, IMSocialMessage>} IMMessageCollection
###

module.exports = class MessagesStore extends KodingFluxStore

  @getterPath = 'MessagesStore'

  getInitialState: -> toImmutable {}


  initialize: ->

    @on actions.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actions.CREATE_MESSAGE_SUCCESS, @handleCreateMessageSuccess
    @on actions.CREATE_MESSAGE_FAIL, @handleCreateMessageFail

    @on actions.REMOVE_MESSAGE_BEGIN, @handleRemoveMessageBegin
    @on actions.REMOVE_MESSAGE_SUCCESS, @handleRemoveMessageSuccess
    @on actions.REMOVE_MESSAGE_FAIL, @handleRemoveMessageFail

    @on actions.LIKE_MESSAGE_BEGIN, @handleLikeMessageBegin
    @on actions.LIKE_MESSAGE_SUCCESS, @handleLikeMessageSuccess
    @on actions.LIKE_MESSAGE_FAIL, @handleLikeMessageFail

    @on actions.UNLIKE_MESSAGE_BEGIN, @handleUnlikeMessageBegin
    @on actions.UNLIKE_MESSAGE_SUCCESS, @handleUnlikeMessageSuccess
    @on actions.UNLIKE_MESSAGE_FAIL, @handleUnlikeMessageFail


  ###*
   * Handler for `CREATE_MESSAGE_BEGIN` action.
   * It creates a fake message and pushes it to given channel's thread.
   * Latency compensation first step.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.body
   * @param {string} payload.clientRequestId
   * @return {IMMessageCollection} nextState
  ###
  handleCreateMessageBegin: (messages, { body, clientRequestId }) ->

    { createFakeMessage, addMessage } = MessageCollectionHelpers

    message = createFakeMessage clientRequestId, body

    return addMessage messages, toImmutable message


  ###*
   * Handler for `CREATE_MESSAGE_SUCCESS` action.
   * It first removes fake message if it exists, and then pushes given message
   * from payload.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @param {SocialMessage} payload.message
   * @return {IMMessageCollection} nextState
  ###
  handleCreateMessageSuccess: (messages, { clientRequestId, message }) ->

    { addMessage, removeFakeMessage } = MessageCollectionHelpers

    if clientRequestId
      messages = removeFakeMessage messages, clientRequestId

    return addMessage messages, toImmutable message


  ###*
   * Handler for `CREATE_MESSAGE_FAIL` action.
   * It removes fake message associated with given clientRequestId.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @return {IMMessageCollection} nextState
  ###
  handleCreateMessageFail: (messages, { channelId, clientRequestId }) ->

    { removeFakeMessage } = MessageCollectionHelpers

    return removeFakeMessage messages, clientRequestId


  ###*
   * Handler for `REMOVE_MESSAGE_BEGIN` action.
   * It marks message with given messageId as removed, so that views/components
   * can have a way to differentiate.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleRemoveMessageBegin: (messages, { messageId }) ->

    { markMessageRemoved } = MessageCollectionHelpers

    return markMessageRemoved messages, messageId


  ###*
   * Handler for `REMOVE_MESSAGE_FAIL` action.
   * It unmarks removed flag from the message with given messageId.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleRemoveMessageFail: (messages, { messageId }) ->

    { unmarkMessageRemoved } = MessageCollectionHelpers

    return unmarkMessageRemoved messages, messageId


  ###*
   * Handler for `REMOVE_MESSAGE_SUCCESS` action.
   * It removes message with given messageId.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleRemoveMessageSuccess: (messages, { messageId }) ->

    { removeMessage } = MessageCollectionHelpers

    return removeMessage messages, messageId


  ###*
   * Handler for `LIKE_MESSAGE_BEGIN` action.
   * It optimistically adds a like from logged in user.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleLikeMessageBegin: (messages, { messageId }) ->

    { setIsLiked, addLiker } = MessageCollectionHelpers

    return messages.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, yes
        message = addLiker message, whoami()._id


  ###*
   * Handler for `LIKE_MESSAGE_SUCCESS` action.
   * It updates the message with message id with given message.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @param {SocialMessage} payload.message
   * @return {IMMessageCollection} nextState
  ###
  handleLikeMessageSuccess: (messages, { messageId, message }) ->

    { addMessage } = MessageCollectionHelpers

    return addMessage messages, toImmutable message


  ###*
   * Handler for `LIKE_MESSAGE_FAIL` action.
   * It removes optimistically added like in `LIKE_MESSAGE_BEGIN` action.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleLikeMessageFail: (messages, { messageId }) ->

    { setIsLiked, removeLiker } = MessageCollectionHelpers

    return messages.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, no
        message = removeLiker message, whoami()._id


  ###*
   * Handler for `UNLIKE_MESSAGE_BEGIN` action.
   * It optimistically removes a like from message.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleUnlikeMessageBegin: (messages, { messageId }) ->

    { setIsLiked, removeLiker } = MessageCollectionHelpers

    return messages.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, no
        message = removeLiker message, whoami()._id


  ###*
   * Handler for `UNLIKE_MESSAGE_SUCCESS` action.
   * It updates the message with message id with given message.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @param {SocialMessage} payload.message
   * @return {IMMessageCollection} nextState
  ###
  handleUnlikeMessageSuccess: (messages, { messageId, message }) ->

    { addMessage } = MessageCollectionHelpers

    return addMessage messages, toImmutable message


  ###*
   * Handler for `UNLIKE_MESSAGE_FAIL` action.
   * It adds back optimistically removed like in `UNLIKE_MESSAGE_BEGIN` action.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleUnlikeMessageFail: (messages, { messageId }) ->

    { setIsLiked, addLiker } = MessageCollectionHelpers

    return messages.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, yes
        message = addLiker message, whoami()._id

