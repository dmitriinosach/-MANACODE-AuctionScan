local _, ns = ...
local A = {}
ns.Activity = A
function A.Record(id, observation, realm, faction)
    if not observation.complete then return end
    if observation.scope ~= "item" and not ns.gemByItem[id] and not (ns.Crafting and ns.Crafting.items[id]) then return end
    local db, key = ns.Store.DB(), realm .. "|" .. faction
    db.activityHistory = db.activityHistory or {}
    local markets = db.activityHistory
    local market = markets[key]
    if not market then
        local count, oldest, stamp = 0, nil, math.huge
        for name, value in pairs(markets) do
            count = count + 1
            if value.at < stamp then oldest, stamp = name, value.at end
        end
        if count >= 4 then markets[oldest] = nil end
        market = {items = {}, at = observation.at}; markets[key] = market
    end
    local points = market.items[id]
    if not points then
        local count, oldest, stamp = 0, nil, math.huge
        for itemID, list in pairs(market.items) do
            count = count + 1
            if list[#list].at < stamp then oldest, stamp = itemID, list[#list].at end
        end
        if count >= 2048 then market.items[oldest] = nil end
        points = {}; market.items[id] = points
    end
    if points[#points] and points[#points].at > observation.at then return end
    for _, point in ipairs(points) do if point.scanID == observation.scanID then return end end
    local count = observation.count
    if not count and not observation.truncated then
        count = 0
        for _, text in ipairs(observation.lots) do
            local lot = ns.Lot.Decode(text)
            if lot and lot.count > 0 and lot.buyout > 0 then count = count + 1 end
        end
    end
    if not count then
        if #points == 0 then market.items[id] = nil end
        return
    end
    points[#points + 1] = {at = observation.at, scanID = observation.scanID, price = observation.price,
        lots = count, units = observation.units}
    market.at = math.max(market.at, observation.at)
    while #points > 720 or (#points > 0 and points[1].at < time() - 30 * 86400) do table.remove(points, 1) end
    if #points == 0 then market.items[id] = nil end
end
function A.History(id, days, volume)
    local item = ns.Markets.Item(id)
    for _, scanID in ipairs(item and item.order or {}) do
        local observation = item.observations[scanID]
        observation.scanID = scanID
        A.Record(id, observation, GetRealmName() or "", UnitFactionGroup("player") or "")
    end
    local key = (GetRealmName() or "") .. "|" .. (UnitFactionGroup("player") or "")
    local market = (ns.Store.DB().activityHistory or {})[key]
    local result = {points = {}, volume = volume}
    for _, point in ipairs(market and market.items[id] or {}) do
        if point.at >= time() - days * 86400 and (volume or point.price) then
            result.points[#result.points + 1] = {at = point.at, price = volume and point.lots or point.price,
                quartile = volume and point.units or point.price}
        end
    end
    if ns.Shared then result.points = ns.Shared.Merge(id, result.points, days, volume) end
    return result
end
local function groups(observation)
    local result = {}
    for _, text in ipairs(observation.lots) do
        local lot = ns.Lot.Decode(text)
        if not lot then return nil end
        if lot.buyout > 0 and lot.count > 0 then
            if lot.owner == "" then return nil end
            local key = table.concat({lot.item, lot.suffix, lot.count, lot.minBid, lot.buyout, lot.owner}, ":")
            local entry = result[key] or {lots = 0, stack = lot.count, earliest = math.huge}
            local minimum = ({0, 1800, 7200, 43200})[lot.timeLeft] or 0
            entry.earliest = math.min(entry.earliest, (observation.since or observation.at) + minimum)
            entry.lots = entry.lots + 1
            result[key] = entry
        end
    end
    return result
end
function A.Compare(previous, current)
    if not previous or not current or not previous.complete or not current.complete
        or previous.truncated or current.truncated or #previous.lots >= 500 or #current.lots >= 500
        or previous.scope ~= current.scope or previous.at > (current.since or current.at) then return nil end
    if current.scope ~= "item" and current.scope ~= "family" and current.scope ~= "market" then return nil end
    local before, after = groups(previous), groups(current)
    if not before or not after then return nil end
    local result = {from = previous.at, at = current.at, added = 0, gone = 0, beforeExpiry = 0,
        expiryPossible = 0, addedUnits = 0, goneUnits = 0, oldUnits = previous.units, units = current.units}
    for key, old in pairs(before) do
        local missing = math.max(0, old.lots - (after[key] and after[key].lots or 0))
        result.gone, result.goneUnits = result.gone + missing, result.goneUnits + missing * old.stack
        local reason = current.at < old.earliest and "beforeExpiry" or "expiryPossible"
        result[reason] = result[reason] + missing
    end
    for key, entry in pairs(after) do
        local added = math.max(0, entry.lots - (before[key] and before[key].lots or 0))
        result.added, result.addedUnits = result.added + added, result.addedUnits + added * entry.stack
    end
    return result
end
function A.Recent(id)
    local item = ns.Markets.Item(id)
    local current = item and item.observations[item.quote.scanID]
    if not current then return nil end
    for i = #item.order, 1, -1 do
        local scanID = item.order[i]
        if scanID ~= item.quote.scanID then
            local result = A.Compare(item.observations[scanID], current)
            if result then return result end
        end
    end
    return nil
end
