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
    local known = F.Known(id)
    if known then return ns.T("familyKnown") end
    return ns.T(known == false and "craftRecipeUnknown" or "familyUnknownRecipe")
end
function F.Groups()
    local byKey, order = {}, {}
    for _, family in ipairs(ns.gemFamilies) do
        local expansion = family.expansion or "wrath"
        local key = expansion .. family.quality
        if not byKey[key] then
            byKey[key] = {key = key, expansion = expansion, quality = family.quality, families = {}}
            order[#order + 1] = byKey[key]
        end
        table.insert(byKey[key].families, family)
    end
    table.sort(order, function(a, b)
        if a.expansion ~= b.expansion then return a.expansion == "wrath" end
        return a.quality > b.quality
    end)
    return order
end
function F.Group(key)
    for _, group in ipairs(F.Groups()) do if group.key == key then return group end end
end
function F.GroupMembers(key)
    local ids, group = {}, key and F.Group(key)
    for _, family in ipairs(group and group.families or {}) do
        for _, id in ipairs(family.members) do ids[#ids + 1] = id end
    end
    return ids
end
function F.CompleteGroup(key, force)
    local group = F.Group(key)
    if not group then return false end
    local classIndex = ns.Compat.AuctionFilter(group.families[1].raw)
    local sources = {}
    if classIndex then
        local covered = {}
        for _, family in ipairs(group.families) do
            if not ns.Hidden.Is(family.raw) then
                for _, id in ipairs(family.members) do covered[#covered + 1] = id end
            end
        end
        sources[1] = {target = {scope = "gems", gemGroup = key, query = "", classIndex = classIndex,
            minQuality = group.quality}, covered = covered}
    else
        for _, family in ipairs(group.families) do
            if not ns.Hidden.Is(family.raw) then sources[#sources + 1] = {family = family.raw} end
        end
    end
    return ns.Batch.Complete(sources, force, true)
end
function F.CompleteAll(expansions, force)
    local sources = {}
    for _, group in ipairs(F.Groups()) do
        if expansions[group.expansion] and not ns.Hidden.IsGroup(group.key) then
            for _, family in ipairs(group.families) do
                if not ns.Hidden.Is(family.raw) then sources[#sources + 1] = {family = family.raw} end
            end
        end
    end
    return ns.Batch.Complete(sources, force, true)
end
function F.Change(id)
    local item = ns.Markets.Item(id)
    if not item then return nil end
    local current, previous
    for i = #item.order, 1, -1 do
        local observation = item.observations[item.order[i]]
        if observation and observation.price and observation.complete then
            if not current then current = observation
            elseif observation.at < current.at then previous = observation; break end
        end
    end
    if current and previous and previous.price > 0 then return (current.price / previous.price - 1) * 100 end
    return nil
end
function F.Known(id)
    local family = ns.gemByItem[id]
    local spell = family and family.spells[id]
    if not spell then return nil end
    return ns.Recipes.Known(spell, ns.T("jewelrySection"))
end
function F.Learned(family)
    local known, total = 0, 0
    for _, id in ipairs(family.members) do
        if id ~= family.raw then
            total = total + 1
            if F.Known(id) then known = known + 1 end
        end
    end
    return known, total
end
function F.Margin(id, fee)
    local family = ns.gemByItem[id]
    if not family or id == family.raw then return nil end
    local q, base = ns.Markets.Quote(id), ns.Markets.Quote(family.raw)
    if base and base.price and q and q.price and base.miss == 0 and q.miss == 0 then
        return q.price * (1 - fee) - base.price
    end
    return nil
end
function F.Best(family, fee)
    local bestID, bestMargin
    for _, id in ipairs(family.members) do
        if id ~= family.raw and F.Known(id) ~= false and not ns.Hidden.Is(id) then
            local margin = F.Margin(id, fee)
            if margin and (not bestMargin or margin > bestMargin) then bestID, bestMargin = id, margin end
        end
    end
    if not bestID then
        for _, id in ipairs(family.members) do
            if id ~= family.raw then
                local margin = F.Margin(id, fee)
                if margin and (not bestMargin or margin > bestMargin) then bestID, bestMargin = id, margin end
            end
        end
    end
    return bestID, bestMargin
end
function F.GroupAge(group)
    local latest
    for _, family in ipairs(group.families) do
        for _, id in ipairs(family.members) do
            local q = ns.Markets.Quote(id)
            if q and q.at and not q.vendor then latest = math.max(latest or 0, q.at) end
        end
    end
    return latest and math.max(0, time() - latest) or nil
end
