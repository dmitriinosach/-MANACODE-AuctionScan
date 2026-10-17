local _, ns = ...
local D = {}
ns.Disenchant = D
D.priceSeconds = 1800
D.RARE = 0.05
D.groups = {
    {key = "wrathArmor", labelKey = "deWrathArmor", expansion = "wrath", classIndex = 2, minLevel = 68, maxLevel = 80},
    {key = "wrathWeapon", labelKey = "deWrathWeapon", expansion = "wrath", classIndex = 1, minLevel = 68, maxLevel = 80},
    {key = "bcArmor", labelKey = "deBCArmor", expansion = "bc", classIndex = 2, minLevel = 57, maxLevel = 70},
    {key = "bcWeapon", labelKey = "deBCWeapon", expansion = "bc", classIndex = 1, minLevel = 57, maxLevel = 70},
}
for i = 1, 4 do
    local base = D.groups[i]
    base.quality = 2
    for quality = 3, 4 do
        D.groups[#D.groups + 1] = {key = base.key .. "_" .. quality, base = base.key,
            labelKey = base.labelKey, expansion = base.expansion, classIndex = base.classIndex,
            minLevel = base.minLevel, maxLevel = base.maxLevel, quality = quality}
    end
end
function D.Group(key)
    if D.targetGroups and D.targetGroups[key] then return D.targetGroups[key] end
    for _, group in ipairs(D.groups) do if group.key == key then return group end end
    local target, targetMask = key:match("^target(%d+)_(%d+)$")
    if target then
        local id, qualities, minimum, maximum, found = tonumber(target), {}, 4, 0, false
        for digit in targetMask:gmatch("%d") do
            local quality = tonumber(digit)
            if quality < 2 or quality > 4 then return nil end
            qualities[quality], minimum = true, math.min(minimum, quality)
        end
        local group = {key = key, base = "target" .. target, labelKey = "deTargetMode",
            targetID = id, qualities = qualities, quality = minimum, minLevel = 0, maxLevel = 80}
        for _, band in ipairs(ns.disenchantBands) do
            if D.Matches(group, band) then
                found = true; maximum = math.max(maximum, band.maxRequiredLevel or 80)
                group.minItemLevel = math.min(group.minItemLevel or math.huge, band.minLevel)
                group.maxItemLevel = math.max(group.maxItemLevel or 0, band.maxLevel)
            end
        end
        if not found then
            local valid = false
            for _, material in ipairs(ns.disenchantMaterials) do if id == material then valid = true end end
            if not valid then return nil end
        end
        group.maxLevel = found and maximum or 80
        D.targetGroups = D.targetGroups or {}
        D.targetGroups[key] = group
        return group
    end
    local base, mask = key:match("^(%a+)_(%d+)$")
    if not base then return nil end
    local source = D.Group(base)
    if not source then return nil end
    local qualities, minimum = {}, 4
    for digit in mask:gmatch("%d") do
        local quality = tonumber(digit)
        if quality < 2 or quality > 4 then return nil end
        qualities[quality], minimum = true, math.min(minimum, quality)
    end
    return {key = key, base = base, labelKey = source.labelKey, expansion = source.expansion,
        classIndex = source.classIndex, minLevel = source.minLevel, maxLevel = source.maxLevel,
        qualities = qualities, quality = minimum}
end
function D.HasQuality(group, quality)
    return group.qualities and group.qualities[quality] or (not group.qualities and group.quality == quality)
end
function D.Selection(base, qualities)
    local mask = ""
    for quality = 2, 4 do if qualities[quality] then mask = mask .. quality end end
    if mask == "" then return nil end
    if base:match("^target%d+$") then return base .. "_" .. mask end
    return mask == "2" and base or base .. "_" .. mask
end
function D.Matches(group, band)
    if group.targetID then
        return D.HasQuality(group, band.quality or 2) and D.Output(band, group.targetID) ~= nil
    end
    local kind = group.classIndex == 1 and "weapon" or "armor"
    return band.expansion == group.expansion and D.HasQuality(group, band.quality or 2)
        and (band.kind == kind or band.kind == "any" or (group.classIndex == 2 and (band.quality or 2) == 2))
end
function D.Output(band, id)
    for _, output in ipairs(band and band.outputs or {}) do
        if output.itemID == id and output.chance > 0 then return output end
    end
end
function D.Accepts(group, meta)
    if not group or not meta or not D.HasQuality(group, meta.quality or 2) then return false end
    local band = D.Band(meta.band)
    if group.targetID then return D.Output(band, group.targetID) ~= nil end
    return band and band.expansion == group.expansion and meta.classIndex == group.classIndex
end
function D.WithinLevels(meta, minimum, maximum)
    return meta.level >= (minimum or 0) and (not maximum or maximum == 0 or meta.level <= maximum)
end
function D.RequiredRange(key, classIndex, options)
    options = options or {}
    local group, minimum, maximum = D.Group(key), 81, 0
    if options.includeNoLevel then return 0, group.maxLevel end
    for _, band in ipairs(ns.disenchantBands) do
        local levels = ns.disenchantRequiredLevels[band.key]
        levels = levels and levels[classIndex]
        if levels and D.Matches(group, band) then
            for level, range in pairs(levels) do
                if D.WithinLevels({level = level}, options.minItemLevel, options.maxItemLevel) and range[2] > 0 then
                    minimum, maximum = math.min(minimum, range[1]), math.max(maximum, range[2])
                end
            end
        end
    end
    if maximum == 0 then return math.max(1, group.minLevel), group.maxLevel end
    return minimum, maximum
end
function D.TargetItems()
    local out = {}
    for _, id in ipairs(ns.disenchantMaterials) do out[#out + 1] = {raw = id} end
    return out
end
function D.Materials(key)
    local ids, seen, group = {}, {}, D.Group(key)
    for _, band in ipairs(ns.disenchantBands) do
        if D.Matches(group, band) then
            for _, output in ipairs(band.outputs) do
                if not seen[output.itemID] then ids[#ids + 1] = output.itemID; seen[output.itemID] = true end
            end
        end
    end
    table.sort(ids)
    return ids
end
local function prices()
    local db = ns.Store.DB()
    local key = (GetRealmName() or "") .. "|" .. (UnitFactionGroup("player") or "")
    db.disenchantPrices = db.disenchantPrices or {}
    db.disenchantPrices[key] = db.disenchantPrices[key] or {}
    return db.disenchantPrices[key]
end
function D.SetPrice(id, copper)
    local valid = false
    for _, material in ipairs(ns.disenchantMaterials) do if material == id then valid = true end end
    if not valid or (copper and (copper ~= copper or copper < 0 or copper > 1000000000)) then return false end
    prices()[id] = copper and math.floor(copper + 0.5) or nil
    return true
end
function D.Quote(id)
    local q, value = ns.Markets.Quote(id), prices()[id]
    if value == nil then return q end
    return {price = value, miss = 0, complete = true, manual = true, at = time()}
end
function D.Fresh(id)
    local quote = D.Quote(id)
    return quote and quote.manual or ns.Markets.Fresh(id, D.priceSeconds)
end
function D.Candidate(id, link)
    if ns.disenchantExcluded and ns.disenchantExcluded[id] then return false end
    local name, _, quality, level, required, class, _, _, equip = ns.Compat.ItemInfo(link or id)
    if not name or not quality or not level or not class then return nil end
    if quality < 2 or quality > 4 or not GetAuctionItemClasses then return false end
    local classes = {GetAuctionItemClasses()}
    local kind = class == classes[1] and "weapon" or (class == classes[2] and "armor")
    if not kind or equip == "INVTYPE_BAG" or equip == "INVTYPE_BODY" or equip == "INVTYPE_TABARD"
        or equip == "INVTYPE_QUIVER" or equip == "" then return false end
    local override = ns.disenchantOverrides[id]
    if override and override.band then
        if level ~= override.level or quality ~= override.quality then return false end
        return {band = override.band, level = level, skill = override.skill,
            classIndex = class == classes[1] and 1 or 2, required = required, quality = quality}
    end
    if equip == "INVTYPE_SHIELD" or equip == "INVTYPE_HOLDABLE" then
        if quality == 2 and not override then return false end
        if override then kind = override.kind end
    end
    for _, band in ipairs(ns.disenchantBands) do
        if not band.exactOnly and (band.quality or 2) == quality and (band.kind == kind or band.kind == "any")
            and level >= band.minLevel and level <= band.maxLevel
            and (not override or override.lootId == band.lootId) then
            return {band = band.key, level = level, skill = override and override.skill or band.skill,
                classIndex = class == classes[1] and 1 or 2, required = required, quality = quality}
        end
    end
    return false
end
function D.Band(key)
    if not D.byBand then
        D.byBand = {}
        for _, band in ipairs(ns.disenchantBands) do D.byBand[band.key] = band end
    end
    return D.byBand[key]
end
function D.Spread(result, fee, cost)
    local low, high
    for pass = 1, 2 do
        for _, output in ipairs(result.outputs) do
            if output.price and (pass == 2 or output.chance >= D.RARE) then
                local least, most = output.minCount * output.price, output.maxCount * output.price
                low = low and math.min(low, least) or least
                high = high and math.max(high, most) or most
            end
        end
        if low then break end
    end
    if not low then return end
    result.low = low * (1 - fee) - result.reserve - cost
    result.high = high * (1 - fee) - result.reserve - cost
    if cost > 0 then result.lowPercent, result.highPercent = result.low / cost * 100, result.high / cost * 100 end
end
function D.Estimate(band, cost, fee, fixedPrices, selling)
    local result = {cost = cost, outputs = {}, gross = 0, fresh = true, deposit = 0}
    for _, output in ipairs(band.outputs) do
        local quote = fixedPrices and fixedPrices[output.itemID] or D.Quote(output.itemID)
        local quantity = output.chance * (output.minCount + output.maxCount) / 2
        local price = quote and quote.miss == 0 and quote.complete ~= false and quote.price
        result.outputs[#result.outputs + 1] = {id = output.itemID, quantity = quantity, price = price,
            chance = output.chance, minCount = output.minCount, maxCount = output.maxCount}
        if selling then
            local _, _, _, _, _, _, _, stack, _, _, vendor = ns.Compat.ItemInfo(output.itemID)
            local deposit = 0
            for amount = output.minCount, output.maxCount do
                local rate = fee == 0.15 and 0.75 or 0.15
                local value = selling.base and selling.base * amount * (selling.hours or 12) / 12
                    or (vendor and math.max(100, math.floor(vendor * amount * rate * (selling.hours or 12) / 12)))
                if not value or not stack or stack < amount then deposit = nil; break end
                deposit = deposit + value
            end
            if result.deposit and deposit then
                result.deposit = result.deposit + output.chance * deposit / (output.maxCount - output.minCount + 1)
            else result.deposit = nil end
        end
        result.fresh = result.fresh and D.Fresh(output.itemID)
        if price and result.gross then result.gross = result.gross + quantity * price else result.gross = nil end
    end
    if result.gross then
        result.reserve = selling and result.deposit and result.deposit * (selling.losses or 0) or 0
        if selling and not result.deposit and (selling.losses or 0) > 0 then return result end
        result.net = result.gross * (1 - fee) - result.reserve
        result.margin = result.net - cost
        D.Spread(result, fee, cost)
        result.percent = cost > 0 and result.margin / cost * 100 or nil
    end
    return result
end
function D.Snapshot(key)
    local scans = ns.Store.DB().scans
    local draft = ns.Store.DB().disenchantDrafts and ns.Store.DB().disenchantDrafts[key]
    for i = #scans, 1, -1 do
        if scans[i].deGroup == key then
            return draft and draft.t >= scans[i].t and draft or scans[i]
        end
    end
    return draft
end
function D.Progress(key)
    local state, job = ns.Scan.state, ns.Batch.job
    local scan = state.scan
    if scan and scan.deGroup == key then
        return {stage = "equipment", paused = state.phase == "paused", page = state.page + 1, classIndex = scan.classIndex,
            minLevel = scan.minLevel, maxLevel = scan.maxLevel,
            pages = state.pages, lots = #scan.lots, scan = scan}
    end
    if not job or not scan then return nil end
    local matches, total, index = job.deGroup == key, 0, 0
    for i, task in ipairs(job.items) do
        if task.target.deGroup == key then matches = true end
        if task.target.itemID then
            total = total + 1
            if i <= job.index then index = index + 1 end
        end
    end
    if matches and scan.itemID then
        return {stage = "materials", paused = state.phase == "paused", index = index, total = total,
            name = ns.Markets.Name(scan.itemID), page = state.page + 1, pages = state.pages}
    end
    return nil
end
function D.Rows(key, fee, selling, minItemLevel, minPercent, maxItemLevel, includeNoLevel)
    local progress = D.Progress(key)
    local scan, entries = progress and progress.scan or D.Snapshot(key), {}
    for _, text in ipairs(scan and scan.lots or {}) do
        local lot = ns.Lot.Decode(text)
        local meta = lot and scan.disenchantItems[lot.item]
        local eligible = meta and D.Accepts(D.Group(key), meta) and D.WithinLevels(meta, minItemLevel, maxItemLevel)
            and (includeNoLevel ~= false or meta.required ~= 0)
            and lot.count > 0 and lot.buyout > 0 and lot.owner ~= "" and lot.owner ~= UnitName("player")
        if eligible and minPercent ~= nil then
            local estimate = D.Estimate(D.Band(meta.band), lot.buyout / lot.count, fee, nil, selling)
            eligible = estimate.percent ~= nil and estimate.percent >= minPercent - 0.000001
        end
        if eligible then
            local row = entries[lot.item] or {id = lot.item, units = 0, lots = 0, meta = meta}
            row.cost = math.min(row.cost or math.huge, lot.buyout / lot.count)
            row.units, row.lots = row.units + lot.count, row.lots + 1
            entries[lot.item] = row
        end
    end
    local result = {}
    for _, row in pairs(entries) do
        row.estimate = D.Estimate(D.Band(row.meta.band), row.cost, fee, nil, selling)
        local group = D.Group(key)
        row.target = group.targetID and D.Output(D.Band(row.meta.band), group.targetID) or nil
        result[#result + 1] = row
    end
    table.sort(result, function(a, b)
        local left, right = a.estimate.margin, b.estimate.margin
        if left ~= right then
            if left == nil then return false end
            if right == nil then return true end
            return left > right
        end
        return a.id < b.id
    end)
    return result
end
function D.Scan(key, force, options, part)
    part = part or "smart"
    force = force or part == "materials" or part == "all"
    local group, sources = D.Group(key), {}
    if not group or not GetAuctionItemClasses or (not group.targetID and not ({GetAuctionItemClasses()})[group.classIndex]) then
        ns.say(ns.T("deNoClasses")); return false
    end
    if group.targetID and #D.Materials(key) == 0 then ns.say(ns.T("deTargetNoBands")); return false end
    if part ~= "equipment" then
        for _, id in ipairs(D.Materials(key)) do
            if not (D.Quote(id) and D.Quote(id).manual) and (force or not D.Fresh(id)) then
                sources[#sources + 1] = id
            end
        end
    end
    if part ~= "materials" then
        local ranges = {}
        for _, class in ipairs(group.targetID and {2, 1} or {group.classIndex}) do
            local low, high = D.RequiredRange(key, class, options)
            ranges[class] = {minLevel = low, maxLevel = high}
        end
        sources[#sources + 1] = {target = {scope = "disenchant", deGroup = key, query = "",
            classIndex = group.classIndex, deClasses = group.targetID and {2, 1} or nil,
            deRanges = ranges,
            minLevel = group.minLevel, maxLevel = group.maxLevel,
            minQuality = group.quality, deOptions = options}, covered = {}}
    end
    local started = ns.Batch.Complete(sources, force, true)
    if started and ns.Batch.job then ns.Batch.job.deGroup = key end
    return started
end
function D.Prepare(scan)
    local options, group = scan.deOptions, D.Group(scan.deGroup)
    if not options or not options.cut then return end
    local percent = tonumber(options.percent)
    if not percent or percent <= -100 or percent > 1000 then return end
    scan.dePrices, scan.deLimit = {}, 0
    for _, id in ipairs(D.Materials(scan.deGroup)) do
        local q = D.Quote(id)
        if not q or not q.price or q.miss > 0 or q.complete == false then
            scan.deCutDisabled, scan.deCutMissing = "prices", id; return
        end
        scan.dePrices[id] = {price = q.price, miss = 0, complete = true, manual = q.manual}
    end
    for _, band in ipairs(ns.disenchantBands) do
        if D.Matches(group, band) and band.maxLevel >= (options.minItemLevel or 0)
            and (not options.maxItemLevel or options.maxItemLevel == 0 or band.minLevel <= options.maxItemLevel) then
            local estimate = D.Estimate(band, 0, options.fee or 0.05, scan.dePrices, options.selling)
            if not estimate.net then scan.deCutDisabled, scan.deCutMissing = "prices", band.key; return end
            scan.deLimit = math.max(scan.deLimit, estimate.net / (1 + percent / 100))
        end
    end
    scan.dePercent = percent
end
function D.Sort(scan)
    if type(SortAuctionClearSort) ~= "function" or type(SortAuctionSetSort) ~= "function"
        or type(GetAuctionSort) ~= "function" then
        if scan.deOptions and scan.deOptions.cut then scan.deCutDisabled = scan.deCutDisabled or "sort" end
        return
    end
    if not scan.deOriginalSort then
        scan.deOriginalSort = {}
        for i = 1, 10 do
            local key, reverse = GetAuctionSort("list", i)
            if not key then break end
            scan.deOriginalSort[#scan.deOriginalSort + 1] = {key, reverse}
        end
    end
    SortAuctionClearSort("list")
    SortAuctionSetSort("list", "buyout", false)
end
function D.RestoreSort(scan)
    if not scan or not scan.deOriginalSort then return end
    local key, reverse = GetAuctionSort("list", 1)
    if key == "buyout" and not reverse then
        SortAuctionClearSort("list")
        for i = #scan.deOriginalSort, 1, -1 do
            local rule = scan.deOriginalSort[i]
            SortAuctionSetSort("list", rule[1], rule[2])
        end
    end
    scan.deOriginalSort = nil
end
function D.CheckTail(scan, batch)
    if not scan.deLimit or scan.deCutDisabled or batch == 0 then return false end
    if type(GetAuctionSort) ~= "function" then scan.deCutDisabled = "sort"; return false end
    local sort, reverse = GetAuctionSort("list", 1)
    if sort ~= "buyout" or reverse then scan.deCutDisabled = "sort"; return false end
    local minimum, previous = math.huge, scan.deLastPrice or 0
    for i = 1, batch do
        local _, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo("list", i)
        if not count or count <= 0 or not buyout then scan.deCutDisabled = "missing"; return false end
        if buyout > 0 then
            if buyout < previous then scan.deCutDisabled = "order"; return false end
            if count ~= 1 then
                local id = ns.Lot.FromLink(GetAuctionItemLink("list", i))
                local meta = id and ns.Disenchant.Candidate(id, GetAuctionItemLink("list", i))
                if meta == nil then scan.deCutDisabled = "missing"; return false end
                if D.Accepts(D.Group(scan.deGroup), meta) then scan.deCutDisabled = "stack"; return false end
            end
            previous = buyout
            minimum = math.min(minimum, buyout)
        end
    end
    scan.deLastPrice = previous
    if (scan.miss or 0) > 0 then scan.deCutDisabled = "missing"; return false end
    scan.deTailPages = minimum < math.huge and minimum > scan.deLimit and (scan.deTailPages or 0) + 1 or 0
    return scan.deTailPages >= 2
end
function D.PurchasePlan(key, options)
    local progress = D.Progress(key)
    local scan, lots = progress and progress.scan or D.Snapshot(key), {}
    local ordered, rejected, stale = {}, {unknown = 0, threshold = 0, money = 0}, 0
    for _, basket in ipairs(D.orders and scan and D.orders[scan.id] or {}) do
        for _, pick in ipairs(basket.picks) do
            local signature = pick.offer.key
            ordered[signature] = (ordered[signature] or 0) + pick.lots - pick.offer.count
        end
    end
    for _, text in ipairs(scan and scan.lots or {}) do
        local lot = ns.Lot.Decode(text)
        local meta = lot and scan.disenchantItems[lot.item]
        if meta and (not options.itemID or lot.item == options.itemID) and D.Accepts(D.Group(key), meta)
            and D.WithinLevels(meta, options.minItemLevel, options.maxItemLevel)
            and (options.includeNoLevel ~= false or meta.required ~= 0)
            and lot.buyout > 0 and lot.count > 0 and lot.owner ~= "" and lot.owner ~= UnitName("player") then
            local e = D.Estimate(D.Band(meta.band), lot.buyout / lot.count, options.fee, nil, options.selling)
            if e.percent ~= nil and not e.fresh then stale = stale + 1 end
            if not e.percent then rejected.unknown = rejected.unknown + 1
            elseif not options.itemID and e.percent <= options.percent then rejected.threshold = rejected.threshold + 1
            else
                lots[#lots + 1] = {lot = lot, percent = e.percent,
                    classIndex = meta.classIndex, key = ns.Lot.Key(lot.item, lot.suffix, lot.count, lot.buyout, lot.owner)}
            end
        end
    end
    table.sort(lots, function(a, b)
        if a.percent ~= b.percent then return a.percent > b.percent end
        return a.lot.buyout < b.lot.buyout
    end)
    local result, byID, money = {items = {}, count = 0, cost = 0, map = {},
        basket = {kind = "manual", picks = {}, need = 0}, scanID = scan and scan.id,
        rejected = rejected, stale = stale}, {}, GetMoney()
    for _, entry in ipairs(lots) do
        if options.itemID and result.count > 0 then break end
        local lot = entry.lot
        if (ordered[entry.key] or 0) > 0 then
            ordered[entry.key] = ordered[entry.key] - 1
        elseif lot.buyout <= money then
            local item = byID[lot.item]
            if not item then
                item = {id = lot.item, name = ns.Markets.Name(lot.item), plan = {kind = "manual", picks = {}, need = 0}}
                byID[lot.item] = item; result.items[#result.items + 1] = item
            end
            local offer = {stack = lot.count, buyout = lot.buyout, count = 1, page = 0}
            item.plan.picks[#item.plan.picks + 1] = {offer = offer, lots = 1}
            item.plan.need = item.plan.need + lot.count
            local saved = result.map[entry.key]
            if not saved then
                local offer = {key = entry.key, item = lot.item, suffix = lot.suffix, owner = lot.owner,
                    classIndex = entry.classIndex, percent = entry.percent,
                    stack = lot.count, buyout = lot.buyout, count = 0, page = 0}
                saved = {offer = offer, lots = 0}
                result.map[entry.key] = saved
                result.basket.picks[#result.basket.picks + 1] = saved
            end
            saved.lots, saved.offer.count = saved.lots + 1, saved.offer.count + 1
            result.basket.need = result.basket.need + lot.count
            result.count, result.cost, money = result.count + 1, result.cost + lot.buyout, money - lot.buyout
        else
            rejected.money = rejected.money + 1
        end
    end
    for _, item in ipairs(result.items) do ns.Plan.Recount(item.plan) end
    ns.Plan.Recount(result.basket)
    return result
end
function D.CancelBuy()
    D.purchase = nil
    ns.Scan.purchaseRequest = nil
    ns.Buy.Stop()
end
local function startPurchase()
    local job = D.purchase
    local options, group = job.options, D.Group(job.key)
    local function guard(index)
        local id = ns.Lot.FromLink(GetAuctionItemLink("list", index))
        local _, _, count, _, _, _, _, _, buyout, _, _, owner = GetAuctionItemInfo("list", index)
        local meta = id and D.Candidate(id, GetAuctionItemLink("list", index))
        if not meta or not D.WithinLevels(meta, options.minItemLevel, options.maxItemLevel)
            or options.includeNoLevel == false and meta.required == 0
            or not D.Accepts(group, meta) or not count or count <= 0
            or not buyout or buyout <= 0 or not owner or owner == "" or owner == UnitName("player") then return false end
        local estimate = D.Estimate(D.Band(meta.band), buyout / count, options.fee, nil, options.selling)
        return estimate.percent ~= nil and (options.itemID ~= nil or estimate.percent > options.percent)
    end
    job.starting = true
    local ok = ns.Buy.StartCategory(job.plan.basket, job.filter, guard)
    job.starting = false
    if ok then
        D.orders = D.orders or {}
        D.orders[job.plan.scanID] = D.orders[job.plan.scanID] or {}
        table.insert(D.orders[job.plan.scanID], job.plan.basket)
    else D.purchase = nil end
    return ok
end
function D.Purchase(key, options)
    if D.purchase then
        if D.purchase.key ~= key or D.purchase.options.itemID ~= options.itemID then
            D.CancelBuy(); ns.say(ns.T("deBuyContextChanged")); return false
        end
        return ns.Buy.Confirm()
    end
    if ns.Buy.Active() or not ns.Scan.state.open then return false end
    if ns.Scan.state.phase ~= "idle" then
        return ns.Scan.SnapshotForPurchase(key, function() D.Purchase(key, options) end)
    end
    local plan = D.PurchasePlan(key, options)
    if #plan.items == 0 then ns.say(ns.T("deBuyEmpty")); return false end
    local group, scan = D.Group(key), D.Snapshot(key)
    local frozen = {fee = options.fee, percent = options.percent, minItemLevel = options.minItemLevel,
        maxItemLevel = options.maxItemLevel, includeNoLevel = options.includeNoLevel, itemID = options.itemID}
    if options.selling then
        frozen.selling = {hours = options.selling.hours, losses = options.selling.losses, base = options.selling.base}
    end
    D.purchase = {key = key, options = frozen, plan = plan,
        filter = {scope = "disenchant", deGroup = key, deTarget = group.targetID,
            classIndex = group.classIndex, minLevel = group.minLevel,
            maxLevel = group.maxLevel, minQuality = group.quality,
            maxPages = math.max(1, scan.deReadPages or math.ceil((scan.expect or 0) / 50))}}
    local firstClass = group.classIndex or 2
    local range = scan.deRanges and scan.deRanges[firstClass]
    local low, high = D.RequiredRange(key, firstClass, options)
    D.purchase.filter.minLevel, D.purchase.filter.maxLevel = range and range.minLevel or low,
        range and range.maxLevel or high
    if group.targetID then
        local routes = {}
        for _, pick in ipairs(plan.basket.picks) do
            local class = pick.offer.classIndex
            local low, high = D.RequiredRange(key, class, options)
            routes[class] = routes[class] or {classIndex = class,
                minLevel = scan.deRanges and scan.deRanges[class] and scan.deRanges[class].minLevel or low,
                maxLevel = scan.deRanges and scan.deRanges[class] and scan.deRanges[class].maxLevel or high,
                maxPages = math.max(1, scan.deRoutePages and scan.deRoutePages[class] or D.purchase.filter.maxPages), score = -math.huge}
            routes[class].score = math.max(routes[class].score, pick.offer.percent)
        end
        D.purchase.filter.routes = {}
        for _, route in pairs(routes) do table.insert(D.purchase.filter.routes, route) end
        table.sort(D.purchase.filter.routes, function(a, b) return a.score > b.score end)
    end
    return startPurchase()
end
function D.BuyChanged()
    local job = D.purchase
    if job and not job.starting then
        if (ns.Buy.state.refused or 0) > 0 then D.CancelBuy()
        elseif not ns.Buy.Active() then
            D.purchase = nil
        end
    end
    if ns.Trader and ns.Trader.section == "disenchant" and ns.Trader.frame then ns.Trader.Refresh() end
end
