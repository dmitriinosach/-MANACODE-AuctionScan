local _, ns = ...
local S = {}
ns.Shared = S
local function integer(value, maximum)
    return type(value) == "number" and value >= 0 and value <= maximum and value == math.floor(value)
end
local function valid(point)
    return type(point) == "table" and type(point.sourceID) == "string" and #point.sourceID <= 128
        and type(point.scanID) == "string" and #point.scanID <= 256 and integer(point.itemID, 2147483647)
        and point.itemID > 0 and integer(point.at, 4102444800) and integer(point.since, point.at)
        and integer(point.lots, 10000000) and integer(point.units, 1000000000)
        and (point.price == nil or (type(point.price) == "number" and point.price >= 0 and point.price <= 1e12))
        and point.at <= time() and point.complete == true
        and (point.clockStatus == "unverified" or point.clockStatus == "verified")
end
function S.Data()
    local inbox, db = ns.SharedInbox, ns.Store.DB()
    if type(inbox) ~= "table" or inbox.v ~= 1 or type(inbox.market) ~= "table" then return nil end
    local market = inbox.market
    if market.realm ~= (GetRealmName() or "") or market.faction ~= (UnitFactionGroup("player") or "")
        or type(market.serverID) ~= "string" or type(market.pool) ~= "string" then return nil end
    local key = table.concat({market.serverID, market.realm, market.faction, market.pool}, "|")
    db.sharedHistory = db.sharedHistory or {}
    local data = db.sharedHistory[key]
    if not data then data = {items = {}, seen = {}}; db.sharedHistory[key] = data end
    if data.version ~= inbox.version and type(inbox.version) == "string" then
        for _, point in ipairs(inbox.observations or {}) do
            if valid(point) then
                local identity = #point.sourceID .. ":" .. point.sourceID .. point.scanID .. ":" .. point.itemID
                if not data.seen[identity] then
                    local list = data.items[point.itemID] or {}; data.items[point.itemID] = list
                    list[#list + 1] = point; data.seen[identity] = true
                end
            end
        end
        for _, list in pairs(data.items) do
            table.sort(list, function(a, b)
                if a.at ~= b.at then return a.at < b.at end
                return a.sourceID .. a.scanID < b.sourceID .. b.scanID
            end)
        end
        data.version = inbox.version
    end
    return data
end
function S.Quote(id, own)
    local data = S.Data()
    local list = data and data.items[id]
    local point = list and list[#list]
    if not point or point.at > time() or (own and own.at >= point.at) then return own end
    return {price = point.price, at = point.at, since = point.since, units = point.units, lots = point.lots,
        complete = true, miss = 0, shared = true, sourceID = point.sourceID, scanID = point.scanID,
        clockStatus = point.clockStatus}
end
function S.Merge(id, points, days, volume)
    local data, result, times = S.Data(), {}, {}
    local ownSource = ns.SharedInbox and ns.SharedInbox.localSourceID
    local localScans = {}
    for _, scan in ipairs(ns.Store.DB().scans) do localScans[scan.id] = true end
    for _, point in ipairs(data and data.items[id] or {}) do
        local importedOwn = point.sourceID == ownSource and localScans[point.scanID]
        if not importedOwn and point.at >= time() - days * 86400 and point.at <= time()
            and (volume or point.price) then
            times[point.at] = {at = point.at, price = volume and point.lots or point.price,
                quartile = volume and point.units or (point.p25 or point.price), shared = true,
                sourceID = point.sourceID, scanID = point.scanID}
        end
    end
    for _, point in ipairs(points) do times[point.at] = point end
    for _, point in pairs(times) do result[#result + 1] = point end
    table.sort(result, function(a, b) return a.at < b.at end)
    return result
end
