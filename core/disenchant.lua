local _, ns = ...
local D = {}
ns.Disenchant = D
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
    for _, group in ipairs(D.groups) do if group.key == key then return group end end
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
    return mask == "2" and base or base .. "_" .. mask
end
function D.Matches(group, band)
    local kind = group.classIndex == 1 and "weapon" or "armor"
    return band.expansion == group.expansion and D.HasQuality(group, band.quality or 2)
        and (band.kind == kind or band.kind == "any" or (group.classIndex == 2 and (band.quality or 2) == 2))
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
function D.Candidate(id, link)
    local name, _, quality, level, required, class, _, _, equip = ns.Compat.ItemInfo(link or id)
    if not name or not quality or not level or not class then return nil end
    if quality < 2 or quality > 4 or not GetAuctionItemClasses then return false end
    local classes = {GetAuctionItemClasses()}
    local kind = class == classes[1] and "weapon" or (class == classes[2] and "armor")
    if not kind or equip == "INVTYPE_BAG" or equip == "INVTYPE_BODY" or equip == "INVTYPE_TABARD"
        or equip == "INVTYPE_QUIVER" or equip == "" then return false end
    local override = quality == 2 and ns.disenchantOverrides[id] or nil
    if equip == "INVTYPE_SHIELD" or equip == "INVTYPE_HOLDABLE" then
        if quality == 2 and not override then return false end
        if override then kind = override.kind end
    end
    for _, band in ipairs(ns.disenchantBands) do
        if (band.quality or 2) == quality and (band.kind == kind or band.kind == "any")
            and level >= band.minLevel and level <= band.maxLevel
            and (not override or override.lootId == band.lootId) then
            return {band = band.key, level = level, skill = override and override.skill or band.skill,
                classIndex = class == classes[1] and 1 or 2, required = required, quality = quality}
        end
    end
    return false
end
function D.Band(key)
    for _, band in ipairs(ns.disenchantBands) do if band.key == key then return band end end
end
function D.Estimate(band, cost, fee, fixedPrices, selling)
    local result = {cost = cost, outputs = {}, gross = 0, fresh = true, deposit = 0}
    for _, output in ipairs(band.outputs) do
        local quote = fixedPrices and fixedPrices[output.itemID] or D.Quote(output.itemID)
        local quantity = output.chance * (output.minCount + output.maxCount) / 2
        local price = quote and quote.miss == 0 and quote.complete ~= false and quote.price
        result.outputs[#result.outputs + 1] = {id = output.itemID, quantity = quantity, price = price}
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
        result.fresh = result.fresh and (quote and quote.manual or ns.Markets.Fresh(output.itemID))
        if price and result.gross then result.gross = result.gross + quantity * price else result.gross = nil end
    end
    if result.gross then
        result.reserve = selling and result.deposit and result.deposit * (selling.losses or 0) or 0
        if selling and not result.deposit and (selling.losses or 0) > 0 then return result end
        result.net = result.gross * (1 - fee) - result.reserve
        result.margin = result.net - cost
        result.percent = cost > 0 and result.margin / cost * 100 or nil
    end
    return result
end
function D.Snapshot(key)
    local scans = ns.Store.DB().scans
    for i = #scans, 1, -1 do if scans[i].deGroup == key then return scans[i] end end
end
function D.Progress(key)
    local state, job = ns.Scan.state, ns.Batch.job
    local scan = state.scan
    if scan and scan.deGroup == key then
        return {stage = "equipment", paused = state.phase == "paused", page = state.page + 1,
            pages = state.pages, lots = #scan.lots, scan = scan}
    end
    if not job or not scan then return nil end
    local matches, total, index = false, 0, 0
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
function D.Rows(key, fee, selling)
    local progress = D.Progress(key)
    local scan, entries = progress and progress.scan or D.Snapshot(key), {}
    for _, text in ipairs(scan and scan.lots or {}) do
        local lot = ns.Lot.Decode(text)
        local meta = lot and scan.disenchantItems[lot.item]
        if meta and lot.count > 0 and lot.buyout > 0 and lot.owner ~= "" and lot.owner ~= UnitName("player") then
            local row = entries[lot.item] or {id = lot.item, units = 0, lots = 0, meta = meta}
            row.cost = math.min(row.cost or math.huge, lot.buyout / lot.count)
            row.units, row.lots = row.units + lot.count, row.lots + 1
            entries[lot.item] = row
        end
    end
    local result = {}
    for _, row in pairs(entries) do
        row.estimate = D.Estimate(D.Band(row.meta.band), row.cost, fee, nil, selling)
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
function D.Scan(key, force, options)
    local group, sources = D.Group(key), {}
    if not group or not GetAuctionItemClasses or not ({GetAuctionItemClasses()})[group.classIndex] then
        ns.say(ns.T("deNoClasses")); return false
    end
    for _, id in ipairs(D.Materials(key)) do
        if not (D.Quote(id) and D.Quote(id).manual) then sources[#sources + 1] = id end
    end
    sources[#sources + 1] = {target = {scope = "disenchant", deGroup = key, query = "",
        classIndex = group.classIndex, minLevel = group.minLevel, maxLevel = group.maxLevel,
        minQuality = group.quality, deOptions = options}, covered = {}}
    return ns.Batch.Complete(sources, force, true)
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
        if D.Matches(group, band) then
            local estimate = D.Estimate(band, 0, options.fee or 0.05, scan.dePrices, options.selling)
            if not estimate.net then scan.deCutDisabled, scan.deCutMissing = "prices", band.key; return end
            scan.deLimit = math.max(scan.deLimit, estimate.net / (1 + percent / 100))
        end
    end
    scan.dePercent = percent
end
function D.Sort(scan)
    if not scan.deLimit or scan.deCutDisabled then return end
    if type(SortAuctionClearSort) ~= "function" or type(SortAuctionSetSort) ~= "function"
        or type(GetAuctionSort) ~= "function" then scan.deCutDisabled = "sort"; return end
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
        if not count or count ~= 1 or not buyout or buyout < previous or (buyout == 0 and previous > 0) then
            scan.deCutDisabled = "order"; return false
        end
        previous = buyout
        minimum = math.min(minimum, buyout)
    end
    scan.deLastPrice = previous
    if (scan.miss or 0) > 0 then scan.deCutDisabled = "missing"; return false end
    scan.deTailPages = minimum > scan.deLimit and (scan.deTailPages or 0) + 1 or 0
    return scan.deTailPages >= 2
end
function D.PurchasePlan(key, options)
    local scan, lots = D.Snapshot(key), {}
    for _, text in ipairs(scan and scan.lots or {}) do
        local lot = ns.Lot.Decode(text)
        local meta = lot and scan.disenchantItems[lot.item]
        if meta and lot.buyout > 0 and lot.count > 0 and lot.owner ~= "" and lot.owner ~= UnitName("player") then
            local e = D.Estimate(D.Band(meta.band), lot.buyout / lot.count, options.fee, nil, options.selling)
            if e.fresh and e.percent and e.percent > options.percent then
                lots[#lots + 1] = {lot = lot, percent = e.percent}
            end
        end
    end
    table.sort(lots, function(a, b)
        if a.percent ~= b.percent then return a.percent > b.percent end
        return a.lot.buyout < b.lot.buyout
    end)
    local result, byID, money = {items = {}, count = 0, cost = 0}, {}, GetMoney()
    for _, entry in ipairs(lots) do
        local lot = entry.lot
        if lot.buyout <= money then
            local item = byID[lot.item]
            if not item then
                item = {id = lot.item, name = ns.Markets.Name(lot.item), plan = {kind = "manual", picks = {}, need = 0}}
                byID[lot.item] = item; result.items[#result.items + 1] = item
            end
            local offer = {stack = lot.count, buyout = lot.buyout, count = 1, page = 0}
            item.plan.picks[#item.plan.picks + 1] = {offer = offer, lots = 1}
            item.plan.need = item.plan.need + lot.count
            result.count, result.cost, money = result.count + 1, result.cost + lot.buyout, money - lot.buyout
        end
    end
    for _, item in ipairs(result.items) do ns.Plan.Recount(item.plan) end
    return result
end
function D.CancelBuy()
    D.purchase = nil
    ns.Buy.Stop()
end
local function nextPurchase()
    local job = D.purchase
    local item = job and job.plan.items[job.index]
    if not item then D.purchase = nil; return false end
    local options, group = job.options, D.Group(job.key)
    local function guard(index)
        local id = ns.Lot.FromLink(GetAuctionItemLink("list", index))
        local _, _, count, _, _, _, _, _, buyout, _, _, owner = GetAuctionItemInfo("list", index)
        local meta = id and D.Candidate(id, GetAuctionItemLink("list", index))
        if not meta or not D.HasQuality(group, meta.quality or 2) or meta.classIndex ~= group.classIndex
            or D.Band(meta.band).expansion ~= group.expansion or not count or count <= 0
            or not buyout or buyout <= 0 or not owner or owner == "" or owner == UnitName("player") then return false end
        local estimate = D.Estimate(D.Band(meta.band), buyout / count, options.fee, nil, options.selling)
        return estimate.fresh and estimate.percent and estimate.percent > options.percent
    end
    job.starting = true
    local ok = ns.Buy.Start(item.name, item.plan, item.id, guard)
    job.starting = false
    if not ok then D.purchase = nil end
    return ok
end
function D.Purchase(key, options)
    if D.purchase then return ns.Buy.Confirm() end
    if ns.Buy.Active() or ns.Scan.state.phase ~= "idle" then return false end
    local plan = D.PurchasePlan(key, options)
    if #plan.items == 0 then ns.say(ns.T("deBuyEmpty")); return false end
    D.purchase = {key = key, options = options, plan = plan, index = 1}
    return nextPurchase()
end
function D.BuyChanged()
    local job = D.purchase
    if job and not job.starting then
        if (ns.Buy.state.refused or 0) > 0 then D.CancelBuy()
        elseif not ns.Buy.Active() then
            if ns.Buy.state.stopKey == "sayBuyDone" then
                job.index = job.index + 1; nextPurchase()
            else D.purchase = nil end
        end
    end
    if ns.Trader and ns.Trader.section == "disenchant" and ns.Trader.frame then ns.Trader.Refresh() end
end
