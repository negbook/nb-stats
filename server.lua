local LoadGamebaseStats = config.LoadGamebaseStats
local stats_csv,stats_csv_gamebase,stats_all; 

stats_all = {}
stats_csv = ReadCSV("data/stats.csv")


if LoadGamebaseStats then 
    stats_csv_gamebase = ReadCSV("data/gamebase.csv") 
    for i=1,#stats_csv_gamebase do 
        local stats = stats_csv_gamebase[i]
        stats_all[stats.stat] = stats
    end 
end

for i=1,#stats_csv do 
    local stats = stats_csv[i]
    stats_all[stats.stat] = stats
end 

local GetMinMax = function(stat)
    local stat = stat:lower()
    local d = stats_all[stat] or error(stat,2)
    return d.min,d.max
end 

local acceptedcolumn = {}
CreateThread(function() 
    if LoadGamebaseStats then 
        for i=1,#stats_csv_gamebase do 
            local stats = stats_csv_gamebase[i]
            local tempType = "INT(200)"
            local tempDefault = "0"
            if stats.type == "int" then 
                tempType = "INT(200)"
                tempDefault = "0"
            elseif stats.type == "float" then 
                tempType = "DECIMAL(10,6)"
                tempDefault = "0.000000"
            elseif stats.type == "string" then 
                tempType = "VARCHAR(200)"
                tempDefault = ""
            end 
            table.insert(acceptedcolumn,stats.stat)
            local result = exports.oxmysql:query_async([[SHOW COLUMNS FROM `stats` LIKE ?]],{stats.stat})
            if #result == 0 then 
                exports.oxmysql:query_async([[ALTER TABLE stats ADD COLUMN ]]..stats.stat..[[ ]]..tempType..[[ NOT NULL DEFAULT ?]], {tempDefault})
            end 
        end 
    end 
    for i=1,#stats_csv do 
        local stats = stats_csv[i]
        local tempType = "INT(200)"
        local tempDefault = "0"
        if stats.type == "int" then 
            tempType = "INT(200)"
            tempDefault = "0"
        elseif stats.type == "float" then 
            tempType = "DECIMAL(10,6)"
            tempDefault = "0.000000"
        elseif stats.type == "string" then 
            tempType = "VARCHAR(200)"
            tempDefault = ""
        end 
        table.insert(acceptedcolumn,stats.stat)
        local result = exports.oxmysql:query_async([[SHOW COLUMNS FROM `stats` LIKE ?]],{stats.stat})
        if #result == 0 then 
            exports.oxmysql:query_async([[ALTER TABLE stats ADD COLUMN ]]..stats.stat..[[ ]]..tempType..[[ NOT NULL DEFAULT ?]], {tempDefault})
        end 
    end 
end)

local GetPlayerLicense = function(type, player)
    for k,v in pairs(GetPlayerIdentifiers(player))do
        if string.sub(v, 1, string.len(type..":")) == type..":" then 
            return v 
        end 
    end
end 

local RegisterDatabaseTable = function(t,datas,cb)
    local keys = {}
    local values = {} 
    local valuestxt = {}
    for i,v in pairs(datas) do 
        table.insert(keys,i)
        table.insert(values,v)
        table.insert(valuestxt,"?")
    end 
    exports.oxmysql:query("INSERT INTO "..t.." ("..table.concat(keys,",")..") VALUES ("..table.concat(valuestxt,",")..")", values,
    cb)
end 

local GetStatData = function(player,type,cb,isnumber)
    local license = GetPlayerLicense("license", player)
    exports.oxmysql:query("SELECT "..type.." FROM stats WHERE license = ?", {license}, function(result)
        if result and result[1] then
            local r = isnumber and tonumber(result[1][type]) or result[1][type]
            if cb then cb(r) end 
        end
    end)
end

local StatLog = function(player,amount,reason)

    local amount = tonumber(amount)
    local license = GetPlayerLicense("license", player)
    
    local f,err = io.open(GetResourcePath(GetCurrentResourceName())..'/log/'..license:gsub(":","-") ..'.log','a+')
    
	if not f then return print(err) end
    
    local timestamp = os.time(os.date("*t"))
    local data = {amount=amount,reason=reason or "Undescription",date=os.date("%x %X",timestamp),timestamp=timestamp}
    local line = json.encode(data).."\n"
    
	f:write(line)
	f:close()
end

local GetStatsLog = function(player,cb)
    local license = GetPlayerLicense("license", player)
    local result = {}
    for line in io.lines(GetResourcePath(GetCurrentResourceName()).."/log/"..license:gsub(":","-") ..'.log') do
        local temp = json.decode(line)
        
        table.insert(result,temp)
    end
    table.sort(result,function(A,B)
        return A.timestamp > B.timestamp
    end)
    cb(result)
end 

local BadLog = function(player,reason,...)
    
    local license = GetPlayerLicense("license", player)
    local opts = {...}
    if opts[1] then 
        reason = reason.." "..table.concat(opts," ")
    end 
    local f,err = io.open(GetResourcePath(GetCurrentResourceName())..'/log/bad.log','a+')
    
	if not f then return print(err) end
    local data = {license=license, reason=reason or "Undescription",date=os.date("%x %X",timestamp)}
    local line = json.encode(data).."\n"
    
	f:write(line)
	f:close()
end 

local UpdateStatData = function(player,type,amount,cb,reason)
    local license = GetPlayerLicense("license", player)
    local found = false 
    for i=1,#acceptedcolumn do 
        if type == acceptedcolumn[i] then 
            found = true 
            break 
        end 
    end 
    if not found then 
        BadLog(player, "bad type requested , invoking by "..(GetInvokingResource() or GetCurrentResourceName()))
        return 
    end 
    exports.oxmysql:query("UPDATE stats SET "..type.." = "..type.." + ? WHERE license = ?", {amount, license},function(result)
        
        if cb then 
            if result.changedRows>0 then 
                cb(true) 
                StatLog(player,amount,reason or "Undescription")
                
            else 
                cb(false)
            end 
        end 
    end)
end

local SetStatData = function(player,type,amount,cb,reason)
    local license = GetPlayerLicense("license", player)
    local found = false 
    for i=1,#acceptedcolumn do 
        if type == acceptedcolumn[i] then 
            found = true 
            break 
        end 
    end 
    if not found then 
        BadLog(player, "bad type requested , invoking by"..(GetInvokingResource() or GetCurrentResourceName()))
        return 
    end 
    exports.oxmysql:query("UPDATE stats SET "..type.." = ? WHERE license = ?", {amount, license},function(result)
        if cb then 
            if result.changedRows>0 then 
                cb(true) 
                StatLog(player,amount,"(Set)".. (reason or "Undescription"))
            else 
                cb(false)
            end 
        end 
    end)
end

RemovePlayerStat = function(player,type,amount,cb,reason)
    local amount = tonumber(amount)
    GetStatData(player,type,function(data)
        if data then
            if amount < 0 then
                if cb then cb(false) end 
            else
                if amount == 0 then 
                    if cb then cb(true) end 
                else 
                    UpdateStatData(player,type,-amount,cb,reason)
                end 
            end
        end
    end,true)
end 

AddPlayerStat = function(player,type,amount,cb,reason)
    local amount = tonumber(amount)
    GetStatData(player,type,function(data)
        if data then
            if amount < 0 then
                if cb then cb(false) end 
            else
                if amount == 0 then 
                    if cb then cb(true) end 
                else 
                    UpdateStatData(player,type,amount,cb,reason)
                end 
            end
        end 
    end,true)
    
end

SetPlayerStat = function(player,type,amount,cb,reason)
    local amount = amount
    GetStatData(player,type,function(data)
        if data then
            SetStatData(player,type,amount,cb,reason)
        end 
    end,true)
    
end

local GetPlayerStats = function(player,cb)
    local player = tonumber(player)
    local license = GetPlayerLicense("license", player)
    local result = exports.oxmysql:query_async("SELECT "..table.concat(acceptedcolumn,",").." FROM stats WHERE license = ? LIMIT 1", {license})
    local Stat_account = result and result[1]
    local Stat_account_numbered
    if Stat_account then 
        for i,v in pairs(Stat_account) do 
            if tonumber(tostring(tonumber(v))) == tonumber(v) then 
                result[1][i] = tonumber(v)
            end 
        end 
        Stat_account_numbered = result[1]
        cb(Stat_account_numbered)
    else 
        local datas = {
            license = license
        }
        RegisterDatabaseTable("stats",datas,function()
            local result2 = exports.oxmysql:query_async("SELECT "..table.concat(acceptedcolumn,",").." FROM stats WHERE license = ? LIMIT 1", {license})
            local Stat_account = assert(result2 and result2[1], "Error getting Stat datas")
            local Stat_account_numbered
            if Stat_account then 
                for i,v in pairs(Stat_account) do 
                    if tonumber(tostring(tonumber(v))) == tonumber(v) then 
                        result2[1][i] = tonumber(v)
                    end 
                end 
                Stat_account_numbered = result2[1]
                cb(Stat_account_numbered)
            else 
                cb({}) -- error
            end
            
        end)
    end 
    
end
RegisterServerCallback("GetPlayerStats", GetPlayerStats )



exports("RemovePlayerStat",RemovePlayerStat)
exports("AddPlayerStat",AddPlayerStat)
exports("SetPlayerStat",SetPlayerStat)
exports("GetStatsLog",GetStatsLog)
exports("GetPlayerStats",GetPlayerStats)