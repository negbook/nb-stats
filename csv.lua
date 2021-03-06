--http://lua-users.org/wiki/CsvUtils
local function fromLine(s) -- Convert from CSV string to table (converts a single line of a CSV file)
  s = s .. ','        -- ending comma
  local t = {}        -- table to collect fields
  local fieldstart = 1
  repeat
    -- next field is quoted? (start with `"'?)
    if string.find(s, '^"', fieldstart) then
      local a, c
      local i  = fieldstart
      repeat
        -- find closing quote
        a, i, c = string.find(s, '"("?)', i+1)
      until c ~= '"'    -- quote not followed by quote?
      if not i then error('unmatched "') end
      local f = string.sub(s, fieldstart+1, i-1)
      table.insert(t, (string.gsub(f, '""', '"')))
      fieldstart = string.find(s, ',', i) + 1
    else                -- unquoted; find next comma
      local nexti = string.find(s, ',', fieldstart)
      table.insert(t, string.sub(s, fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > string.len(s)
  return t
end

local function split (inputstr, delimiter)
   if delimiter == nil then
           delimiter = "%s"
   end
   local t={}
   for match in (inputstr..delimiter):gmatch('(.-)'..delimiter) do
                    table.insert(t, match);
    end
   return t
end


ReadCSV = function(path,translationkeys)
    local ln = 1
    local keys = translationkeys or {}
    local k = 1 
    local data = {}
    local rawdata = LoadResourceFile(GetCurrentResourceName(),path)
    local rawdata = rawdata:gsub("\r","")
    local delimiter = "\n"
    for line in (rawdata..delimiter):gmatch('(.-)'..delimiter) do
        local isdescription = line:sub(1,1) == "#"

        local delimiter = ","
        if ln == 1 then 
            local s = isdescription and line:gsub("#","") or line 
            if not translationkeys then
                for match in (s..delimiter):gmatch('(.-)'..delimiter) do
                    table.insert(keys, match);
                end
            end 
            ln = ln + 1
        elseif not isdescription then  
            k = 1
            local linedata = fromLine(line)
            for i=1,#linedata do
                local v = linedata[i]
                if not data[ln-1] then data[ln-1] = {} end 
                local isNumber = tostring(tonumber(v)) == v 
                data[ln-1][keys[k]] = isNumber and tonumber(v) or v 
                k = k + 1
            end
            ln = ln + 1
        end 
        
    end
    --for line in io.lines(GetResourcePath(GetCurrentResourceName()).."/"..path) do
        
    --end
    ln = 1
    return data
end 

ReadCSVRaw = function(raw,translationkeys)
    local ln = 1
    local keys = translationkeys or {}
    local k = 1 
    local data = {}
    local rawdata = raw
    local rawdata = rawdata:gsub("\r","")
    local delimiter = "\n"
    for line in (rawdata..delimiter):gmatch('(.-)'..delimiter) do
        local isdescription = line:sub(1,1) == "#"
        local delimiter = ","
        if ln == 1 then 
            local s = isdescription and line:gsub("#","") or line 
            if not translationkeys then
                for match in (s..delimiter):gmatch('(.-)'..delimiter) do
                    table.insert(keys, match);
                end
            end 
            ln = ln + 1
        elseif not isdescription then  
            k = 1
            local linedata = fromLine(line)
            for i=1,#linedata do
                local v = linedata[i]
                if not data[ln-1] then data[ln-1] = {} end 
                local isNumber = tostring(tonumber(v)) == v 
                data[ln-1][keys[k]] = isNumber and tonumber(v) or v 
                k = k + 1
            end
            ln = ln + 1
        end 

    end
    --for line in io.lines(GetResourcePath(GetCurrentResourceName()).."/"..path) do
        
    --end
    ln = 1
    return data
end 

-- Used to escape "'s by toCSV
function escapeCSV(s)
  if string.find(s, '[,"]') then
    s = '"' .. string.gsub(s, '"', '""') .. '"'
  end
  return s
end
-- Convert from table to CSV string
table.ToCSVLine = function (tt)
  local s = ""
-- ChM 23.02.2014: changed pairs to ipairs 
-- assumption is that fromCSV and toCSV maintain data as ordered array
  for _,p in ipairs(tt) do  
    s = s .. "," .. escapeCSV(p)
  end
  return string.sub(s, 2)      -- remove first comma
end