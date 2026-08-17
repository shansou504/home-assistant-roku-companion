sub init()
    m.top.id = "Item"
    m.label = m.top.findNode("label")
    m.poster = m.top.findNode("poster")
end sub
sub updateContent()
    m.label.text = m.top.itemContent.title
    if m.top.itemContent.state = "on"
        m.poster.uri = "pkg:/images/toggle-switch-outline_48x48.png"
    else if m.top.itemContent.state = "off"
        m.poster.uri = "pkg:/images/toggle-switch-off-outline_48x48.png"
    end if
    ' Updating the content causes the UI to scroll back to index 0.
    ' If it's already on 0 it doesn't register a change so the updateFocus()
    ' won't run. For this case we'll call it manually.
    if m.top.index = 0
        updateFocus()
    end if
end sub
sub updateFocus()
    if m.top.focusPercent > 0.5
        if m.poster.uri = "pkg:/images/toggle-switch-outline_48x48.png"
            m.poster.uri = "pkg:/images/toggle-switch-outline_focused_48x48.png"
        elseif m.poster.uri = "pkg:/images/toggle-switch-off-outline_48x48.png"
            m.poster.uri = "pkg:/images/toggle-switch-off-outline_focused_48x48.png"
        end if
        m.label.color = "#000000ff"
    else
        if m.poster.uri = "pkg:/images/toggle-switch-outline_focused_48x48.png"
            m.poster.uri = "pkg:/images/toggle-switch-outline_48x48.png"
        elseif m.poster.uri = "pkg:/images/toggle-switch-off-outline_focused_48x48.png"
            m.poster.uri = "pkg:/images/toggle-switch-off-outline_48x48.png"
        end if
        m.label.color = "#ffffffff"
    end if
end sub
