kd                    = require 'kd'
isKoding              = require 'app/util/isKoding'
TeamMembersCommonView = require './teammemberscommonview'
GroupsBlockedUserView = require './groupsblockeduserview'
BlockedMemberItemView = require './blockedmemberitemview'


module.exports = class AdminMembersView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()

    kd.singletons.notificationController.on 'NewMemberJoinedToGroup', @bound 'refreshAllTabs'


  createTabView: ->

    data    = @getData()
    tabView = new kd.TabView { hideHandleCloseIcons: yes }

    tabView.addPane all     = new kd.TabPaneView { name: 'All Members' }
    tabView.addPane admins  = new kd.TabPaneView { name: 'Admins' }
    tabView.addPane mods    = new kd.TabPaneView { name: 'Moderators' }
    tabView.addPane blocked = new kd.TabPaneView { name: 'Disabled' }

    all.addSubView @allView = new TeamMembersCommonView
      fetcherMethod          : 'fetchMembersWithEmail'
      showSearchFieldAtFirst : yes
      noItemFoundText        : 'No members found!'
    , data

    admins.addSubView @adminsView = new TeamMembersCommonView
      fetcherMethod     : 'fetchAdminsWithEmail'
      defaultMemberRole : 'admin'
      noItemFoundText   : 'No admins found!'
    , data

    mods.addSubView @modsView = new TeamMembersCommonView
      fetcherMethod     : 'fetchModeratorsWithEmail'
      defaultMemberRole : 'moderator'
      noItemFoundText   : 'No moderators found!'
    , data


    if isKoding data
      blocked.addSubView new GroupsBlockedUserView {}, data
    else
      blocked.addSubView @blockedView = new TeamMembersCommonView
        fetcherMethod     : 'fetchBlockedAccountsWithEmail'
        listViewItemClass : BlockedMemberItemView
        noItemFoundText   : 'No disabled user found!'
      , data

      @blockedView.listController.getListView().on 'ItemWasAdded', (item) =>
        item.on 'UserUnblocked', @bound 'refreshAllTabs'

    tabView.showPaneByIndex 0
    @addSubView tabView

    @bindRoleChangeEvent()


  bindRoleChangeEvent: ->

    views = [ @allView, @adminsView, @modsView ]

    views.forEach (view) =>
      view.listController.getListView().on 'ItemWasAdded', (item) =>
        item.on 'MemberRoleChanged', (oldRole, newRole) =>
          @listenForRoleChange item, view, oldRole, newRole

        item.on 'UserKicked', =>
          @blockedView.refresh()
          @listenForRoleChange item, view


  listenForRoleChange: (memberItemView, parentView, oldRole, newRole) ->

    views = [ @allView, @adminsView, @modsView ]

    if oldRole and newRole
      becameMod   = oldRole.slug in [ 'admin', 'member' ]    and newRole.slug is 'moderator'
      becameAdmin = oldRole.slug in [ 'moderator', 'member'] and newRole.slug is 'admin'
      targetView  = if becameMod then @modsView else if becameAdmin then @adminsView

    if parentView is @allView
      views.shift() # don't update view on all members tab, it will update itself.
    else
      parentView.refresh()

    for view in views
      for memberItem in view.listController.getItemsOrdered()
        if memberItem.data.profile.nickname is memberItemView.data.profile.nickname
          # update member view if it's owner or in all members tab
          if view is @allView or newRole?.slug is 'owner'
            memberItem.memberRole = newRole
            memberItem.handleRoleChangeOnUI newRole.label
          else
            # destroy member view, it will be updated and added into new tab.
            memberItem.destroy()

    # change member data and add new one to correct tab
    if targetView
      memberItemView.data.memberRole = newRole
      targetView.listController.addItem memberItemView.data


  refreshAllTabs: ->

    for view in [ @allView, @adminsView, @modsView, @blockedView ]
      view.refresh()
