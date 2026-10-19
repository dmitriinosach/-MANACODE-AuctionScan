local _, ns = ...
local B = {}
ns.Bargain = B
B.MIN_LOTS = 3
B.MIN_SELLERS = 2
B.DEEP_LOTS = 8
B.HISTORY_DAYS = 30
B.PERCENT = {buyout = 30, bid = 40}
B.HOURS = 12
B.TIER = 0.35
B.MAX_ROWS = 400
local RANGES = {{0, 1800}, {1800, 7200}, {7200, 43200}, {43200, 172800}}
B.onChange = nil
local indexed
local cached
function B.IsFull(scan)
    return scan.scope ~= "disenchant" and scan.scope ~= "gems" and not scan.itemID and not scan.family
        and (not scan.query or scan.query == "") and (scan.miss or 0) == 0 and scan.complete ~= false
        and not scan.truncated and not (scan.mode == "all" and (scan.expect or 0) > scan.total)
        and #scan.lots > 0
end
function B.Snapshot()
    local realm, faction = GetRealmName() or "", UnitFactionGroup("player") or ""
    local scans = ns.Store.DB().scans
    for i = #scans, 1, -1 do
        local scan = scans[i]
        if scan.realm == realm and scan.faction == faction and B.IsFull(scan) then return scan end
    end
    return nil
end
function B.Age(scan, now)
    return math.max(0, (now or time()) - (scan.t + (scan.secs or 0)))
end
local function groups(scan)
    if indexed and indexed.scan == scan and indexed.count == #scan.lots then return indexed.groups end
    local me, result = UnitName("player"), {}
    for i, text in ipairs(scan.lots) do
        local lot = ns.Lot.Decode(text)
        if lot and lot.count > 0 and lot.owner ~= "" and lot.owner ~= me
            and not (ns.vendorPrices and ns.vendorPrices[lot.item]) then
            local key = lot.item .. ":" .. lot.suffix
            local g = result[key]
            if not g then
                g = {item = lot.item, suffix = lot.suffix, offers = {}, lots = {}, sellerLots = {}, sellers = 0}
                result[key] = g
            end
            g.lots[#g.lots + 1] = i
            if lot.buyout > 0 then
                g.offers[#g.offers + 1] = {unit = lot.buyout / lot.count, count = lot.count, owner = lot.owner,
                    buyout = lot.buyout}
                if not g.sellerLots[lot.owner] then g.sellers = g.sellers + 1 end
                g.sellerLots[lot.owner] = (g.sellerLots[lot.owner] or 0) + 1
            end
        end
    end
    for _, g in pairs(result) do
        table.sort(g.offers, function(a, b)
            if a.unit ~= b.unit then return a.unit < b.unit end
            return a.buyout < b.buyout
        end)
        local units = 0
        g.byLot = {}
        for _, o in ipairs(g.offers) do
            o.before, units = units, units + o.count
            local key = o.buyout .. ":" .. o.count .. ":" .. o.owner
            if not g.byLot[key] then g.byLot[key] = o end
        end
        g.tier = units * B.TIER
    end
    indexed = {scan = scan, count = #scan.lots, groups = result}
    return result
end
local function reference(g, skip)
    local list, skipped = {}, skip == nil
    for _, o in ipairs(g.offers) do
        if not skipped and o.buyout == skip.buyout and o.count == skip.count and o.owner == skip.owner then
            skipped = true
        else
            list[#list + 1] = {o.unit, o.count}
        end
    end
    return ns.Markets.MarketPrice(list)
end
local function offerOf(g, lot)
    if lot.buyout <= 0 then return nil end
    return g.byLot[lot.buyout .. ":" .. lot.count .. ":" .. lot.owner]
end
local function hasHistory(id, scan)
    local item = ns.Markets.Item(id)
    for _, scanID in ipairs(item and item.order or {}) do
        local observation = item.observations[scanID]
        if scanID ~= scan.id and observation and observation.complete and observation.at < scan.t
            and observation.at >= scan.t - B.HISTORY_DAYS * 86400 then return true end
    end
    return false
end
local function supported(g, lot, offer, scan)
    local others = #g.offers - (offer and 1 or 0)
    if others < B.MIN_LOTS then return false end
    local sellers = g.sellers - ((offer and g.sellerLots[lot.owner] == 1) and 1 or 0)
    if sellers < B.MIN_SELLERS then return false end
    if others >= B.DEEP_LOTS then return true end
    if g.history == nil then g.history = hasHistory(g.item, scan) end
    return g.history
end
function B.Deposit(id, count, fee)
    local vendor = select(11, ns.Compat.ItemInfo(id))
    local rate = fee == 0.15 and 0.75 or 0.15
    if not vendor then return 100, false end
    return math.max(100, math.floor(vendor * (count * rate * (B.HOURS / 12)))), true
end
function B.Resale(id, ref, count, fee)
    local gross = ref * count
    local commission = gross * fee
    local deposit, known = B.Deposit(id, count, fee)
    return {gross = gross, commission = commission, deposit = deposit, depositKnown = known,
        revenue = gross - commission - deposit}
end
function B.Increment(bid)
    return math.max(1, math.floor(bid / 100) * 5)
end
function B.NextBid(lot)
    if lot.bid > 0 then return lot.bid + B.Increment(lot.bid) end
    return lot.minBid
end
function B.Left(scan, timeLeft, now)
    local range = RANGES[timeLeft]
    if not range then return nil, nil end
    now = now or time()
    local latest = now - (scan.t + (scan.secs or 0))
    local earliest = now - scan.t
    return range[2] - math.max(0, latest), math.max(0, range[1] - math.max(0, earliest))
end
local function rowKey(lot)
    return ns.Lot.Key(lot.item, lot.suffix, lot.count, lot.buyout, lot.owner) .. ":" .. lot.minBid .. ":" .. lot.bid
end
B.placed = {}
B.revision = 0
local function makeRow(kind, key, scan, lot, g, ref, cost, fee)
    local resale = B.Resale(lot.item, ref, lot.count, fee)
    return {
        kind = kind, key = key, buyKey = ns.Lot.Key(lot.item, lot.suffix, lot.count, lot.buyout, lot.owner),
        item = lot.item, suffix = lot.suffix, count = lot.count, owner = lot.owner,
        minBid = lot.minBid, buyout = lot.buyout, bid = lot.bid, timeLeft = lot.timeLeft,
        hasBuyout = lot.buyout > 0, cost = cost, unit = cost / lot.count, ref = ref,
        discount = (1 - (cost / lot.count) / ref) * 100, resale = resale, revenue = resale.revenue,
        profit = resale.revenue - cost, supply = #g.offers, copies = 1, scanID = scan.id, history = g.history,
    }
end
function B.Rows(kind, options)
    local scan = B.Snapshot()
    local info = {scan = scan, hidden = 0, groups = 0, candidates = 0, kind = kind}
    if not scan then return {}, info end
    local now = options.now or time()
    local percent = options.percent or B.PERCENT[kind]
    local fee = options.fee or 0.05
    local sig = table.concat({scan.id, #scan.lots, kind, percent, fee, math.floor(now / 60), B.revision, ns.Store.DB().seq}, "|")
    if cached and cached.sig == sig then return cached.rows, cached.info end
    info.age = B.Age(scan, now)
    local rows, byKey = {}, {}
    local me = UnitName("player")
    for _, g in pairs(groups(scan)) do
        info.groups = info.groups + 1
        local market = #g.offers >= B.MIN_LOTS and (g.full or reference(g, nil)) or nil
        g.full = market
        if market then
            for _, index in ipairs(g.lots) do
                local lot = ns.Lot.Decode(scan.lots[index])
                local cost, unit
                local skip = true
                if kind == "buyout" then
                    if lot.buyout > 0 then cost, skip = lot.buyout, false end
                elseif lot.timeLeft == 1 or lot.timeLeft == 2 then
                    local maximum = B.Left(scan, lot.timeLeft, now)
                    if not maximum or maximum <= 0 then
                        info.hidden = info.hidden + 1
                    else
                        cost = B.NextBid(lot)
                        skip = lot.buyout > 0 and cost >= lot.buyout
                    end
                end
                if not skip and lot.owner ~= me then
                    unit = cost / lot.count
                    local offer = offerOf(g, lot)
                    local ref = market
                    if offer and offer.before < g.tier then ref = reference(g, offer) end
                    if ref and ref > 0 and unit < ref then
                        if (1 - unit / ref) * 100 >= percent and supported(g, lot, offer, scan) then
                            info.candidates = info.candidates + 1
                            local key = rowKey(lot)
                            local row = byKey[key]
                            if row then
                                row.copies = row.copies + 1
                            elseif B.placed[key] ~= scan.id then
                                row = makeRow(kind, key, scan, lot, g, ref, cost, fee)
                                if row.profit > 0 then
                                    byKey[key] = row
                                    rows[#rows + 1] = row
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.profit ~= b.profit then return a.profit > b.profit end
        if a.discount ~= b.discount then return a.discount > b.discount end
        return a.key < b.key
    end)
    info.total = #rows
    for i = #rows, B.MAX_ROWS + 1, -1 do rows[i] = nil end
    for _, row in ipairs(rows) do
        if kind == "bid" then
            row.leftMax, row.leftMin = B.Left(scan, row.timeLeft, now)
        end
    end
    cached = {sig = sig, rows = rows, info = info}
    return rows, info
end
function B.Depth(row, limit)
    local scan = B.Snapshot()
    local levels, summary = {}, {lots = 0, units = 0, sellers = 0}
    if not scan then return levels, summary end
    local g = groups(scan)[row.item .. ":" .. row.suffix]
    if not g then return levels, summary end
    local by = {}
    for _, o in ipairs(g.offers) do
        local price = math.floor(o.unit + 0.5)
        local level = by[price]
        if not level then
            level = {price = price, units = 0, lots = 0}
            by[price] = level; levels[#levels + 1] = level
        end
        level.units, level.lots = level.units + o.count, level.lots + 1
        summary.lots, summary.units = summary.lots + 1, summary.units + o.count
    end
    summary.sellers = g.sellers
    table.sort(levels, function(a, b) return a.price < b.price end)
    local cumulative = 0
    for _, level in ipairs(levels) do
        cumulative = cumulative + level.units
        level.cumulative = cumulative
    end
    for i = #levels, (limit or 6) + 1, -1 do levels[i] = nil end
    return levels, summary
end
local function live(index)
    local name, _, count, _, _, _, minBid, increment, buyout, bidAmount, highBidder, owner =
        GetAuctionItemInfo("list", index)
    if not name or not count then return nil end
    local nextBid = (bidAmount or 0) > 0 and bidAmount + math.max(1, increment or 0) or minBid
    return {count = count, minBid = minBid, buyout = buyout or 0, bid = bidAmount or 0, mine = highBidder and true or false,
        owner = owner, nextBid = nextBid, left = GetAuctionItemTimeLeft and GetAuctionItemTimeLeft("list", index)}
end
local function bidGuard(offer, limit)
    return function(index)
        local lot = live(index)
        if not lot or lot.mine or lot.owner == UnitName("player") or not lot.left or lot.left > 2 then return false end
        if lot.nextBid > limit or (lot.buyout > 0 and lot.nextBid >= lot.buyout) then return false end
        offer.bid = lot.nextBid
        return true
    end
end
local function buyoutGuard(row)
    return function(index)
        local lot = live(index)
        return lot ~= nil and lot.buyout == row.buyout and lot.count == row.count and lot.owner ~= UnitName("player")
    end
end
B.job = nil
function B.Active()
    return B.job ~= nil and ns.Buy.Active()
end
function B.Act(row)
    if ns.Buy.Active() then
        if B.job and B.job.row.key == row.key then return ns.Buy.Confirm() end
        ns.say(ns.T("bargainBusy"))
        return false
    end
    local bid = row.kind == "bid"
    if bid and (not row.cost or row.cost <= 0) then return false end
    local offer = {key = row.buyKey, item = row.item, suffix = row.suffix, owner = row.owner, stack = row.count,
        buyout = row.buyout, count = 1, page = 0}
    local plan = ns.Plan.Recount({kind = "manual", need = row.count, picks = {{offer = offer, lots = 1}}})
    local guard = bid and bidGuard(offer, row.cost) or buyoutGuard(row)
    B.job = {row = row, offer = offer}
    local started = ns.Buy.Start(ns.Markets.Name(row.item), plan, row.item, guard,
        {lookup = {[row.buyKey] = offer}, bid = bid})
    if not started then B.job = nil end
    return started
end
function B.Cancel()
    B.job = nil
    return ns.Buy.Stop()
end
function B.BuyChanged()
    local job = B.job
    if job and not ns.Buy.Active() then
        if job.offer.count == 0 then
            B.placed[job.row.key] = job.row.scanID
            B.revision = B.revision + 1
        end
        B.job = nil
    end
    if B.onChange then B.onChange() end
end
local previous = ns.Buy.onChange
ns.Buy.onChange = function()
    if previous then previous() end
    B.BuyChanged()
end
