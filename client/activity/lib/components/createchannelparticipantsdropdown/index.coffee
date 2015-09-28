kd                                    = require 'kd'
React                                 = require 'kd-react'
immutable                             = require 'immutable'
Dropbox                               = require 'activity/components/dropbox'
DropboxWrapperMixin                   = require 'activity/components/dropbox/dropboxwrappermixin'
CreateChannelFlux                     = require 'activity/flux/createchannel'
CreateChannelParticipantsDropdownItem = require './createchannelparticipantsdropdownitem'

module.exports = class CreateChannelParticipantsDropdown extends React.Component

  @include [DropboxWrapperMixin]

  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null

  moveToPrevAction     : CreateChannelFlux.actions.user.moveToPrevIndex

  moveToNextAction     : CreateChannelFlux.actions.user.moveToNextIndex

  onItemSelectedAction : CreateChannelFlux.actions.user.setSelectedIndex

  closeAction          : CreateChannelFlux.actions.user.setDropdownVisibility


  # this method overrides DropboxWrapperMixin-componentDidUpdate handler.
  # In this component, we use dropdown keyword. In DropboxWrapperMixin/componentDidUpdate handler
  # expects dropbox component so it occurs an error. Also this component doesn't need any action when
  # componentDidUpdate event fired.
  componentDidUpdate: ->


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <CreateChannelParticipantsDropdownItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    <Dropbox
      className      = "ChannelParticipantsDropdown CreateChannel-dropbox"
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      ref            = 'dropbox'
      top            = '100px'
    >
      <div className="Dropdown-innerContainer">
        <div className="ChannelParticipantsDropdown-list">
          {@renderList()}
        </div>
      </div>
    </Dropbox>
