local Request = {}
Request.__index = Request

function Request.new(url:string, method:string)
    local self = {}
    self.Url = url
    self.Method = method
    self.Headers = {
        ['Content-Type'] = 'application/json',
    }
    return setmetatable(self, Request)
end

function Request:setHeaders(header)
    self.Header = header
end

function Request:setBody(body)
    self.Body = body
end

function Request:setQuery(query)
    self.Query = query
end

function Request:setAuthorization(authorization:string)
    self.Headers['Authorization'] = authorization
end

return Request