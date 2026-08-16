sub init()
    m.top.functionName = "post"
end sub

function post()
    response = invalid
    m.api = CreateObject("roUrlTransfer")
    m.api.SetCertificatesFile("common:/certs/ca-bundle.crt")
    m.api.AddHeader("X-Roku-Reserved-Dev-Id", "")
    m.api.InitClientCertificates()
    m.api.AddHeader("Content-Type", "application/json")
    m.api.AddHeader("Authorization", "Bearer " + m.top.token)
    m.apiUrl = m.top.url
    m.api.SetUrl(m.apiUrl)
    m.apiData = {"entity_id": m.top.entity_id}
    m.apiDataJsonString = FormatJson(m.apiData)
    if m.top.entity_id <> invalid then
        response = m.api.PostFromString(m.apiDataJsonString)
    end if
    m.top.response = response
end function