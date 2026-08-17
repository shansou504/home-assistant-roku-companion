sub init()
    m.top.functionName = "Get"
end sub

sub Get()
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    urlTransfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
    urlTransfer.AddHeader("Authorization", "Bearer " + m.top.token)
    urlTransfer.InitClientCertificates()
    urlTransfer.setUrl(m.top.url)
    response = urlTransfer.GetToString()
    m.top.response = response
end sub