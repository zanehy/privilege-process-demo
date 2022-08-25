local _M = {
    _VERSION = "0.0.1",
}

function _M.enabled()
    local process = require("ngx.process")

    local ok, err = process.enable_privileged_agent()

    if not ok then
        return nil, "enable privileged agent failed error: " .. err
    end

    return ok, nil
end

function write_log()
    local process = require("ngx.process")
    ngx.log(ngx.ERR, "this is init_worker, say function. process type: [" .. process.type() .. "] worker id: [", ngx.worker.id(), "]")
end

function sync_config(premature, url)
    write_log()
    local httpc = require("resty.http").new()

    local res, err = httpc:request_uri(url, {
        method = "GET",
    })
    if not res then
        ngx.log(ngx.ERR, "request failed: ", err)
        return
    end

    local status = res.status
    local length = res.headers["Content-Length"]
    local body = res.body

    ngx.log(ngx.ERR, "privileged agent sync_config! status:[", status, "], length:[", length, "], body:[", body, "]")
end

function _M.time_every(url, interval)
    ngx.log(ngx.ERR, "time_every url:[", url, "], interval:[", interval, "]")
    if not url or type(url) ~= "string" then
        return nil, "url (string) required"
    end
    if not interval or interval <= 0 then
        return nil, "interval (int) required"
    end

    local process = require("ngx.process")
    if process.type() == "privileged agent" then
        local ok, err = ngx.timer.every(interval, sync_config, url)
        if not ok then
            return nil, "privileged agent ngx.timer.every sync_config failed error: " .. err
        end
    end
    return nil, nil
end

return _M

