sub init()
    ' OverhangPanelSetScene Settings
    m.top.backgroundURI = ""
    m.top.backgroundColor = "#181818ff"
    m.top.overhang.logoUri = "pkg:/images/ha_wordmark_660x64.png"
    m.top.overhang.title = ""

    ' Globals
    m.baseurl = ""
    m.token = ""
    m.auth = CreateObject("roRegistrySection", "Auth")
    m.response = invalid
    m.domain = invalid
    m.lastSecondPanelIndex = invalid

    ' Authentication
    if m.auth.Exists("BaseURL")
        m.baseurl = m.auth.Read("BaseURL")
    end if
    if m.auth.Exists("Token")
        m.token = m.auth.Read("Token")
    end if

    ' Create API Get Request for Switch States
    m.getStates = CreateObject("roSGNode", "GetRequest")
    m.getStates.url = m.baseurl + "states"
    m.getStates.token = m.token
    m.getStates.observeField("response", "UpdateSecondPanelContent")

    ' Create API Post Request for Toggling Switches
    m.postRequestToggleSwitch = CreateObject("roSGNode", "PostRequest")
    m.postRequestToggleSwitch.url = m.baseurl + "services/switch/toggle"
    m.postRequestToggleSwitch.token = m.token
    m.postRequestToggleSwitch.observeField("response", "UpdateSwitchStates")

    ' Delay Timer (for momentary switches we temporarily update the local icon,
    ' wait for this delay, then poll the state again to provide some feedback
    ' to the user the switch was clicked)
    m.delayTimer = CreateObject("roSGNode", "Timer")
    m.delayTimer.id = "DelayTimer"
    m.delayTimer.duration = 0.75
    m.delayTimer.observeField("fire", "RequestStates")

    ' Create List of Domains as First Panel
    ' The "createChild" method adds the domain list to the UI
    m.domainListPanel = m.top.panelset.createChild("ListPanel")
    m.domainListPanel.id = "DomainListPanel"
    m.domainListPanel.panelSize = "narrow"
    m.domainListPanel.hasNextPanel = true
    m.domainListPanel.leftOnly = true
    m.domainListPanel.selectButtonMovesPanelForward = true
    m.domainListPanel.observeField("createNextPanelIndex", "UpdateSecondPanel")
    m.domainList = m.domainListPanel.createChild("LabelList")
    m.domainList.id = "DomainList"
    m.domainList.observeField("itemSelected", "ShowKeyboard")
    m.domainContent = CreateObject("roSGNode", "ContentNode")
    binary_sensor = m.domainContent.createChild("ContentNode")
    binary_sensor.id = "binary_sensor"
    binary_sensor.setField("title", "Binary Sensors")
    switch = m.domainContent.createChild("ContentNode")
    switch.id = "switch"
    switch.setField("title", "Switches")
    server = m.domainContent.createChild("ContentNode")
    server.id = "server"
    server.setField("title", "Server")
    token = m.domainContent.createChild("ContentNode")
    token.id = "token"
    token.setField("title", "Token")
    m.domainList.content = m.domainContent
    m.domainListPanel.list = m.domainList

    ' Create Second Panels (added to UI by <panel>.nextPanel = <panel> in UpdateSecondPanel())
    ' binary_sensor
    m.binary_sensorListPanel = CreateObject("roSGNode", "ListPanel")
    m.binary_sensorListPanel.id = "binary_sensorListPanel"
    m.binary_sensorListPanel.hasNextPanel = false
    m.binary_sensorListPanel.panelSize = "wide"
    m.binary_sensorList = m.binary_sensorListPanel.createChild("MarkupList")
    m.binary_sensorList.id = "binary_sensorList"
    m.binary_sensorList.itemComponentName = "Item"
    m.binary_sensorListPanel.list = m.binary_sensorList
    ' switch
    m.switchListPanel = CreateObject("roSGNode", "ListPanel")
    m.switchListPanel.id = "switchListPanel"
    m.switchListPanel.hasNextPanel = false
    m.switchListPanel.panelSize = "wide"
    m.switchList = m.switchListPanel.createChild("MarkupList")
    m.switchList.id = "switchList"
    m.switchList.itemComponentName = "Item"
    m.switchList.observeField("itemFocused", "UpdateFocusedEntityId")
    m.switchList.observeField("itemSelected", "RunPostRequestToggleSwitch")
    m.switchListPanel.list = m.switchList

    ' Create Server Keyboard
    m.serverKeyboard = CreateObject("roSGNode", "StandardKeyboardDialog")
    m.serverKeyboard.id = "ServerKeyboard"
    m.serverKeyboard.buttons = ["Save", "Close"]
    m.serverKeyboard.observeFieldScoped("buttonSelected", "ServerButtonSelected")

    ' Create Token Keyboard
    m.tokenKeyboard = CreateObject("roSGNode", "StandardKeyboardDialog")
    m.tokenKeyboard.id = "TokenKeyboard"
    m.tokenKeyboard.textEditBox.maxTextLength = 255
    m.tokenKeyboard.buttons = ["Save", "Close"]
    m.tokenKeyboard.observeFieldScoped("buttonSelected", "TokenButtonSelected")

    m.domainList.setFocus(true)
end sub

sub ShowKeyboard()
    if m.domain <> invalid
        if m.domain.id = "server"
            m.serverKeyboard.text = ""
            m.top.appendChild(m.serverKeyboard)
            m.serverKeyboard.setFocus(true)
        else if m.domain.id = "token"
            m.tokenKeyboard.text = ""
            m.top.appendChild(m.TokenKeyboard)
            m.TokenKeyboard.setFocus(true)
        end if
    end if
end sub

sub ServerButtonSelected()
    if m.serverKeyboard.buttonSelected = 0
        m.auth.Write("BaseURL", m.serverKeyboard.text + "/api/")
        m.auth.Flush()
        m.baseurl = m.serverKeyboard.text + "/api/"
        m.getStates.url = m.baseurl + "states"
        m.postRequestToggleSwitch.url = m.baseurl + "services/switch/toggle"
    end if
    m.serverKeyboard.close = true
    m.top.removeChild(m.serverKeyboard)
    m.domainList.setFocus(true)
end sub

sub TokenButtonSelected()
    if m.tokenKeyboard.buttonSelected = 0
        m.auth.Write("Token", m.tokenKeyboard.text)
        m.auth.Flush()
        m.token = m.tokenKeyboard.text
        m.getStates.token = m.token
        m.postRequestToggleSwitch.token = m.token
    end if
    m.tokenKeyboard.close = true
    m.top.removeChild(m.tokenKeyboard)
    m.domainList.setFocus(true)
end sub

sub RequestStates()
    m.getStates.control = "run"
end sub

sub UpdateSecondPanel()
    ' AppLaunchComplete -> Roku Certification Requirement
    m.top.signalBeacon("AppLaunchComplete")
    m.pass = false
    m.domain = m.domainList.content.getChild(m.domainListPanel.createNextPanelIndex)
    if m.domain <> invalid
        if m.domain.id = "binary_sensor"
            m.domainListPanel.nextPanel = m.binary_sensorListPanel
            m.pass = true
        else if m.domain.id = "switch"
            m.domainListPanel.nextPanel = m.switchListPanel
            m.pass = true
        end if
    end if
    if m.pass
        RequestStates()
    end if
end sub

sub UpdateSecondPanelContent()
    if m.getStates.response <> invalid and m.getStates.response <> "" and m.domain <> invalid and (m.domain.id = "binary_sensor" or m.domain.id = "switch")
        json = ParseJson(m.getStates.response)
        if json <> invalid
            Dim itemArray[0]
            for each entity in json
                if Left(entity["entity_id"], Instr(1, entity["entity_id"], ".") - 1) = m.domain.id
                    itemArray.Push({"friendly_name": entity["attributes"]["friendly_name"], "entity": entity})
                end if
            end for
            if itemArray.Count() > 0
                itemArray.SortBy("friendly_name")
            end if
            m.content = CreateObject("roSGNode", "ContentNode")
            for each item in itemArray
                node = invalid
                node = CreateObject("roSGNode", "ContentNode")
                node.id = item.entity["entity_id"]
                node.setField("title", item.entity["attributes"]["friendly_name"])
                node.addField("state", "string", false)
                node.setField("state", item.entity["state"])
                m.content.appendChild(node)
            end for
            if m.domain.id = "binary_sensor"
                m.binary_sensorList.content = m.content
                if m.lastSecondPanelIndex <> invalid
                    m.binary_sensorList.jumpToItem = m.lastSecondPanelIndex
                    m.lastSecondPanelIndex = invalid
                end if
            else if m.domain.id = "switch"
                m.switchList.content = m.content
                if m.lastSecondPanelIndex <> invalid
                    m.switchList.jumpToItem = m.lastSecondPanelIndex
                    m.lastSecondPanelIndex = invalid
                end if
            end if
        end if
    end if
end sub

sub UpdateFocusedEntityId()
    if m.switchList.content <> invalid and m.switchList.content.getChildCount() > 0
        if m.switchList.itemFocused <> -1
            m.focusedSwitchItem = m.switchList.content.getChild(m.switchList.itemFocused)
            m.postRequestToggleSwitch.entity_id = m.focusedSwitchItem.id
        end if
    end if
end sub

sub RunPostRequestToggleSwitch()
    m.postRequestToggleSwitch.control = "run"
end sub

sub UpdateSwitchStates()
    if m.postRequestToggleSwitch.response <> invalid and m.postRequestToggleSwitch.response = 200
        if m.switchList.itemFocused <> invalid and m.switchList.itemFocused <> -1
            m.lastSecondPanelIndex = m.switchList.itemFocused
            content = m.switchList.content
            node = content.getChild(m.lastSecondPanelIndex)
            if node.state = "on"
                node.state = "off"
            else if node.state = "off"
                node.state = "on"
            end if
            m.switchList.content = content
            m.switchList.jumpToItem = m.lastSecondPanelIndex
            m.delayTimer.control = "start"
        end if
    end if
end sub
