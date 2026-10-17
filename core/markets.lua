local _, ns = ...
local M = { freshSeconds = 600 }
ns.Markets = M
local indexed = setmetatable({}, { __mode = "k" })
local rebuilding = false
M.routes = ns.tradeRoutes
function M.Name(id)
    local name = ns.Compat.ItemInfo(id)
    if name then return name end
    local stored = ns.Store.DB().items[id]
    if stored then return stored:match("^[^\t]+") end
    local fallback = ns.T("item" .. id)
    return fallback:sub(1, 1) == "[" and ns.T("familyItemID", id) or fallback
end
local function index(scan)
    if indexed[scan] then return indexed[scan] end
    local quotes = {}
    for _, text in ipairs(scan.lots) do
        local lot = ns.Lot.Decode(text)
        if lot then
            local q = quotes[lot.item] or { lots = 0, units = 0, at = scan.t + scan.secs, miss = scan.miss or 0 }
            if lot.count > 0 and lot.buyout > 0 then
                local price = lot.buyout / lot.count
                q.price = q.price and math.min(q.price, price) or price
                q.lots, q.units = q.lots + 1, q.units + lot.count
            end
            quotes[lot.item] = q
        end
    end
    if scan.itemID and not quotes[scan.itemID] then
        quotes[scan.itemID] = { lots = 0, units = 0, at = scan.t + scan.secs, miss = scan.miss or 0 }
    end
    local family = ns.gemByRaw and ns.gemByRaw[scan.family]
    if family then
        for _, id in ipairs(family.members) do
            if not quotes[id] then
                quotes[id] = {lots = 0, units = 0, at = scan.t + scan.secs, miss = scan.miss or 0}
            end
        end
    end
    indexed[scan] = quotes
    for id, q in pairs(quotes) do
        q.since, q.scanID, q.scope = scan.t, scan.id, scan.scope or "market"
        q.complete = (scan.miss or 0) == 0 and scan.complete ~= false
            and not (scan.mode == "all" and (scan.expect or 0) > scan.total)
        if scan.scope == "disenchant" then q.complete = false end
        if scan.query and scan.query ~= "" and not scan.itemID and not scan.family then
            q.complete = q.complete and ((ns.gemByItem and ns.gemByItem[id])
                or (ns.Crafting and ns.Crafting.items[id])
                or (ns.Resale and ns.Resale.byItem[id])
                or (ns.alchemyItems and ns.alchemyItems[id])) and true or false
        end
        if not q.complete then q.miss = math.max(1, q.miss) end
    end
    return quotes
end
local function cache()
    local db = ns.Store.DB()
    if not db.marketCache then
        db.marketCache = {}
        rebuilding = true
        for _, scan in ipairs(db.scans) do M.Remember(scan) end
        rebuilding = false
    end
    if not rebuilding and db.gemFamilyRevision ~= 1 and ns.gemByRaw then
        for _, market in pairs(db.marketCache) do
            for _, raw in ipairs({36929, 36932}) do
                for _, id in ipairs(ns.gemByRaw[raw].members) do
                    local item = market.items[id]
                    if item and item.quote.scope == "family" then
                        item.quote.complete, item.quote.miss = false, math.max(1, item.quote.miss or 0)
                    end
                end
            end
        end
        db.gemFamilyRevision = 1
    end
    return db.marketCache
end
local function marketKey(realm, faction)
    return realm .. "|" .. faction
end
function M.Trim()
    local markets, observations, marketList = cache(), {}, {}
    for key, market in pairs(markets) do
        local items = {}
        marketList[#marketList + 1] = {key = key, at = market.at}
        for id, item in pairs(market.items) do
            if item.quote.at < time() - 30 * 86400 then
                market.items[id] = nil
            else
                items[#items + 1] = {id = id, at = item.quote.at,
                    priority = (ns.gemByItem and ns.gemByItem[id]) or (ns.Crafting and ns.Crafting.items[id])}
            end
        end
        table.sort(items, function(a, b)
            if a.at ~= b.at then return a.at > b.at end
            if not not a.priority ~= not not b.priority then return not not a.priority end
            return a.id < b.id
        end)
        for i = 2049, #items do market.items[items[i].id] = nil end
    end
    table.sort(marketList, function(a, b) return a.at > b.at end)
    for i = 5, #marketList do markets[marketList[i].key] = nil end
    for _, market in pairs(markets) do
        for _, item in pairs(market.items) do
            for _, scanID in ipairs(item.order) do
                local observation = item.observations[scanID]
                observations[#observations + 1] = {item = item, id = scanID, at = observation.at, count = #observation.lots}
            end
        end
    end
    table.sort(observations, function(a, b) return a.at > b.at end)
    local lots = 0
    for _, entry in ipairs(observations) do
        lots = lots + entry.count
        if lots > 12000 then
            entry.item.observations[entry.id] = nil
            for i = #entry.item.order, 1, -1 do
                if entry.item.order[i] == entry.id then table.remove(entry.item.order, i) end
            end
        end
    end
end
function M.Remember(scan)
    local markets = cache()
    local key = marketKey(scan.realm, scan.faction)
    local market = markets[key] or {items = {}, at = 0}
    markets[key] = market
    local quotes, lots, counts = index(scan), {}, {}
    for _, text in ipairs(scan.lots) do
        local lot = ns.Lot.Decode(text)
        if lot and not (ns.vendorPrices and ns.vendorPrices[lot.item]) then
            local list = lots[lot.item] or {}
            counts[lot.item] = (counts[lot.item] or 0) + 1
            if #list < 500 then list[#list + 1] = text end
            lots[lot.item] = list
        end
    end
    local at = scan.t + scan.secs
    market.at = math.max(market.at, at)
    local full = scan.scope ~= "disenchant" and not scan.itemID and not scan.family and (not scan.query or scan.query == "")
        and (scan.miss or 0) == 0 and scan.complete ~= false
        and not (scan.mode == "all" and (scan.expect or 0) > scan.total)
    if full and (not market.full or market.full.at <= at) then
        local present = {}
        for id in pairs(quotes) do present[id] = true end
        market.full = {at = at, since = scan.t, scanID = scan.id, complete = true, miss = 0,
            units = 0, lots = 0, scope = "market", present = present}
        for id, item in pairs(market.items) do
            if not quotes[id] and item.quote.at <= at then
                quotes[id] = {at = at, since = scan.t, scanID = scan.id, complete = true, miss = 0, units = 0, lots = 0, scope = "market"}
            end
        end
    end
    for id, q in pairs(quotes) do
        if not (ns.vendorPrices and ns.vendorPrices[id]) then
            local item = market.items[id] or {observations = {}, order = {}}
            market.items[id] = item
            if not item.quote or item.quote.at <= q.at then item.quote = q end
            if not item.observations[scan.id] then item.order[#item.order + 1] = scan.id end
            item.observations[scan.id] = {at = q.at, since = q.since, complete = q.complete,
                price = q.price, units = q.units, lots = lots[id] or {}, scope = q.scope,
                truncated = #(lots[id] or {}) < (counts[id] or 0)}
            item.observations[scan.id].scanID, item.observations[scan.id].count = scan.id, q.lots
            if ns.Activity then ns.Activity.Record(id, item.observations[scan.id], scan.realm, scan.faction, item) end
            local rank = {}
            for i, scanID in ipairs(item.order) do rank[scanID] = i end
            table.sort(item.order, function(a, b)
                local left, right = item.observations[a].at, item.observations[b].at
                return left < right or (left == right and rank[a] < rank[b])
            end)
            while #item.order > 5 do item.observations[table.remove(item.order, 1)] = nil end
        end
    end
    M.Trim()
end
function M.Item(id)
    local key = marketKey(GetRealmName() or "", UnitFactionGroup("player") or "")
    local market = cache()[key]
    return market and market.items[id]
end
function M.Quote(id)
    if ns.vendorPrices and ns.vendorPrices[id] then
        return {price = ns.vendorPrices[id], units = 0, lots = 0, miss = 0, vendor = true, complete = true}
    end
    local key = marketKey(GetRealmName() or "", UnitFactionGroup("player") or "")
    local market = cache()[key]
    local own
    if market then
        if market.items[id] then own = market.items[id].quote
        elseif market.full and not market.full.present[id] then own = market.full end
    end
    return ns.Shared and ns.Shared.Quote(id, own) or own
end
function M.Fresh(id, seconds)
    local q = M.Quote(id)
    if not q or not q.complete or (q.miss or 0) > 0 then return false end
    if q.vendor then return true end
    local age = time() - (q.since or q.at)
    return age >= 0 and age < (seconds or M.freshSeconds)
end
function M.Offers(id, scanID)
    local item = M.Item(id)
    local observation = item and item.observations[scanID or item.quote.scanID]
    local offers = {}
    if not observation then return offers end
    local texts = observation.lots
    if observation.truncated then
        local scans = ns.Store.DB().scans
        for i = #scans, 1, -1 do
            if scans[i].id == observation.scanID then texts = scans[i].lots; break end
        end
    end
    for _, text in ipairs(texts) do
        local lot = ns.Lot.Decode(text)
        if lot and lot.item == id then
            local ranges = {{0, 1800}, {1800, 7200}, {7200, 43200}, {43200}}
            local range = ranges[lot.timeLeft]
            lot.price = lot.buyout > 0 and lot.count > 0 and lot.buyout / lot.count or nil
            lot.seenAt, lot.seenSince = observation.at, observation.since
            lot.expiresMin = range and observation.since + range[1] or nil
            lot.expiresMax = range and range[2] and observation.at + range[2] or nil
            offers[#offers + 1] = lot
        end
    end
    table.sort(offers, function(a, b) return (a.price or math.huge) < (b.price or math.huge) end)
    return offers
end
function M.Depth(id, scanID)
    local result, byPrice = {levels = {}, units = 0, lots = 0, quote = M.Quote(id)}, {}
    local item = M.Item(id)
    local observation = item and item.observations[scanID or item.quote.scanID]
    if observation then result.quote = {at = observation.at, units = observation.units, lots = observation.count} end
    result.partial = not observation or observation.complete == false
    for _, offer in ipairs(M.Offers(id, scanID)) do
        if offer.price then
            local price = math.floor(offer.price + 0.5)
            local level = byPrice[price]
            if not level then
                level = {price = price, units = 0, lots = 0, sellers = {}, bySeller = {}, owners = {}}
                byPrice[price] = level; result.levels[#result.levels + 1] = level
            end
            local key = offer.owner .. ":" .. offer.count
            local seller = level.bySeller[key]
            if not seller then
                seller = {owner = offer.owner, stack = offer.count, lots = 0, units = 0}
                level.bySeller[key] = seller; level.sellers[#level.sellers + 1] = seller
            end
            seller.lots, seller.units = seller.lots + 1, seller.units + offer.count
            level.units, level.lots = level.units + offer.count, level.lots + 1
            level.owners[offer.owner] = true
            result.units, result.lots = result.units + offer.count, result.lots + 1
        end
    end
    table.sort(result.levels, function(a, b) return a.price < b.price end)
    local cumulative = 0
    for _, level in ipairs(result.levels) do
        cumulative, level.sellerCount = cumulative + level.units, 0
        level.cumulative = cumulative
        for _ in pairs(level.owners) do level.sellerCount = level.sellerCount + 1 end
        table.sort(level.sellers, function(a, b)
            if a.units ~= b.units then return a.units > b.units end
            return a.owner < b.owner
        end)
    end
    if observation and result.lots < (observation.count or 0) then result.partial = true end
    return result
end
function M.Sources(id)
    local item, sources = M.Item(id), {}
    for rank, scanID in ipairs(item and item.order or {}) do
        local observation = item.observations[scanID]
        if observation then sources[#sources + 1] = {id = scanID, at = observation.at, rank = rank} end
    end
    table.sort(sources, function(a, b) if a.at ~= b.at then return a.at > b.at end; return a.rank > b.rank end)
    return sources
end
function M.Estimate(route, quotes, fee)
    local cost = 0
    for _, input in ipairs(route.inputs) do
        local q = quotes[input[1]]
        if not q or not q.price or q.miss > 0 then return nil, nil end
        cost = cost + q.price * input[2]
    end
    if route.random then return cost, nil end
    local output = quotes[route.outputs[1]]
    if not output or not output.price or output.miss > 0 then return cost, nil end
    return cost, output.price * (1 - fee) - cost
end
function M.Scan(id)
    if ns.vendorPrices and ns.vendorPrices[id] then ns.say(ns.T("cacheVendor")); return false end
    local name = ns.Compat.ItemInfo(id)
    if not name or name:sub(1, 1) == "[" then
        ns.say(ns.T("tradeUnknownItem"))
        return false
    end
    if not ns.Scan.ResetPace(true) then return false end
    return ns.Scan.Start("pages", { itemID = id, query = name })
end
