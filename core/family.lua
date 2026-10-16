local _, ns = ...
local F = {}
ns.Family = F
local function marketKey()
    return (GetRealmName() or "") .. "|" .. (UnitFactionGroup("player") or "")
end
function F.Scan(raw)
    local family = ns.gemByRaw[raw or 36919]
    if not family then return false end
    local name = ns.Compat.ItemInfo(family.raw)
    if not name then ns.say(ns.T("tradeUnknownItem")); return false end
    return ns.Scan.Start("pages", {query = name, family = family.raw})
end
function F.Complete(raw, force)
    if not ns.gemByRaw[raw] then return false end
    return ns.Batch.Complete({{family = raw}}, force)
end
function F.Summarize(scan)
    local result, allowed = {}, {}
    for id in pairs(ns.gemByItem) do allowed[id] = true end
    for _, text in ipairs(scan.lots) do
        local lot = ns.Lot.Decode(text)
        if lot and allowed[lot.item] and lot.count > 0 and lot.buyout > 0 then
            local q = result[lot.item] or {units = 0, lots = 0, prices = {}}
            local price = lot.buyout / lot.count
            q.price = math.min(q.price or price, price)
            q.units, q.lots = q.units + lot.count, q.lots + 1
            q.prices[#q.prices + 1] = {price, lot.count}
            result[lot.item] = q
        end
    end
    for _, q in pairs(result) do
        table.sort(q.prices, function(a, b) return a[1] < b[1] end)
        local units = 0
        for _, p in ipairs(q.prices) do
            units = units + p[2]
            if units >= q.units * 0.25 then q.quartile = p[1]; break end
        end
        q.prices = nil
    end
    return result
end
function F.Record(scan)
    local family = ns.gemByRaw[scan.family]
    if family then
        scan.expectedItems, scan.observedItems = {}, {}
        for _, id in ipairs(family.members) do scan.expectedItems[#scan.expectedItems + 1] = id end
        for id in pairs(F.Summarize(scan)) do scan.observedItems[#scan.observedItems + 1] = id end
        table.sort(scan.observedItems)
        scan.coverage = "name-query"
        scan.complete = (scan.miss or 0) == 0
    end
    if (scan.miss or 0) > 0 or (scan.mode == "all" and (scan.expect or 0) > scan.total) then return end
    local db = ns.Store.DB()
    if not db.gemHistory then
        db.gemHistory = {}
        for _, old in ipairs(db.scans) do F.Record(old) end
    end
    local key = scan.realm .. "|" .. scan.faction
    local history = db.gemHistory[key] or {}
    db.gemHistory[key] = history
    local at = scan.t + scan.secs
    if at < time() - 30 * 86400 then return end
    for _, series in pairs(history) do
        while #series > 0 and series[1].at < time() - 30 * 86400 do table.remove(series, 1) end
    end
    for id, q in pairs(F.Summarize(scan)) do
        local series = history[id] or {}
        history[id] = series
        local bucket = math.floor(at / 3600)
        local previous = series[#series]
        q.at, q.bucket, q.scan = at, bucket, scan.id
        if previous and previous.scan == scan.id then
        elseif previous and previous.bucket == bucket then
            if previous.at <= at then series[#series] = q end
        else
            series[#series + 1] = q
        end
        while #series > 720 or (#series > 0 and series[1].at < time() - 30 * 86400) do table.remove(series, 1) end
    end
end
function F.History(id, days)
    local db = ns.Store.DB()
    if not db.gemHistory then
        db.gemHistory = {}
        for _, scan in ipairs(db.scans) do F.Record(scan) end
    end
    local history = db.gemHistory[marketKey()] or {}
    local points, prices, daily = {}, {}, {}
    for _, q in ipairs(history[id] or {}) do
        if q.at >= time() - days * 86400 then
            points[#points + 1], prices[#prices + 1] = q, q.price
            daily[math.floor(q.at / 86400)] = q.price
        end
    end
    if ns.Shared then
        points = ns.Shared.Merge(id, points, days)
        prices, daily = {}, {}
        for _, q in ipairs(points) do
            prices[#prices + 1] = q.price; daily[math.floor(q.at / 86400)] = q.price
        end
    end
    table.sort(prices)
    local n = #prices
    local result = {points = points, count = n}
    if n == 0 then return result end
    result.low, result.high = prices[1], prices[n]
    result.median = (prices[math.floor((n + 1) / 2)] + prices[math.ceil((n + 1) / 2)]) / 2
    local returns, sum = {}, 0
    for day, price in pairs(daily) do
        if daily[day - 1] and daily[day - 1] > 0 then
            local r = price / daily[day - 1] - 1
            returns[#returns + 1], sum = r, sum + r
        end
    end
    if #returns >= 3 then
        local variance = 0
        for _, r in ipairs(returns) do variance = variance + (r - sum / #returns) ^ 2 end
        result.volatility = math.sqrt(variance / (#returns - 1)) * 100
    end
    return result
end
function F.Recipe(id)
    local family = ns.gemByItem[id]
    if family and id == family.raw then return ns.T("familyRaw") end
    local spell = family and family.spells[id]
    if spell and IsSpellKnown and IsSpellKnown(spell) then return ns.T("familyKnown") end
    return ns.T("familyUnknownRecipe")
end
