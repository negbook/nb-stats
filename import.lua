if GetCurrentResourceName() == "nb-stats" then 

else 
    if IsDuplicityVersion() then 
        RemovePlayerStat = function(...)
            return exports["nb-stats"]:RemovePlayerStat(...)
        end 
        AddPlayerStat = function(...)
            return exports["nb-stats"]:AddPlayerStat(...)
        end 
        SetPlayerStat = function(...)
            return exports["nb-stats"]:SetPlayerStat(...)
        end 
        GetStatsLog = function(...)
            return exports["nb-stats"]:GetStatsLog(...)
        end 
        GetPlayerStats = function(...)
            return exports["nb-stats"]:GetPlayerStats(...)
        end 
        LoadStatsDataFile = function(...)
            return exports["nb-stats"]:LoadStatsDataFile(...)
        end 
        
    else 

        UpdatePlayerStats = function(...)
            return exports["nb-stats"]:UpdatePlayerStats(...)
        end 
        GetPlayerStat = function(...)
            return exports["nb-stats"]:GetPlayerStat(...)
        end 
        SetPlayerStat = function(...)
            return exports["nb-stats"]:SetPlayerStat(...)
        end 
        LoadClientTempStatsDataFile = function(...)
            return exports["nb-stats"]:LoadClientTempStatsDataFile(...)
        end 
    end 
end 