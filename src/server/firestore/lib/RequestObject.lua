local RequestObject = {}
RequestObject.__index = RequestObject

function RequestObject.new(url:string, method:string)
    local self = {}
    self.Url = url
    self.Method = method
    self.Headers = {
        ['Content-Type'] = 'application/json',
    }
    return setmetatable(self, RequestObject)
end

function RequestObject:setHeaders(header)
    self.Header = header
end

function RequestObject:setBody(body)
    self.Body = body
end

function RequestObject:setQuery(query)
    self.Query = query
end

function RequestObject:setAuthorization(authorization:string)
    self.Headers['Authorization'] = authorization
end

return RequestObject