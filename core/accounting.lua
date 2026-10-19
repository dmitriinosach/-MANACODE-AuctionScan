local _, ns = ...
local A = {}
ns.Accounting = A
A.PENDING = 30
local function integer(value, minimum, maximum)
    return type(value) == "number" and value == math.floor(value) and value >= minimum and value <= (maximum or 1000000000000)
end
function A.Text(value)
    local text = tostring(value or ""):gsub("[%c|]", "")
    local cut = math.min(#text, 240)
    while cut > 0 do
        local byte = text:byte(cut + 1)
        if not byte or byte < 128 or byte >= 192 then break end
        cut = cut - 1
    end
    return text:sub(1, cut)
end
function A.Price(text)
    local value = tostring(text or ""):match("^%s*(.-)%s*$"):gsub(",", ".")
    if not value:match("^%d+%.?%d*$") then return nil end
    local decimals = value:match("%.(%d*)$")
    if decimals and #decimals > 4 then return nil end
    local number = tonumber(value)
    if not number or number > 100000000 then return nil end
    return math.floor(number * 10000 + 0.5)
end
function A.Book()
    local db = ns.Store.DB()
    db.ledger = db.ledger or {version = 1, seq = 0, characters = {}}
    local root = db.ledger
    local key = (GetRealmName() or "") .. "|" .. (UnitFactionGroup("player") or "") .. "|" .. (UnitName("player") or "")
    root.characters[key] = root.characters[key] or {events = {}, fee = 0.05}
    return root.characters[key]
end
function A.Changed()
    if A.onChange then A.onChange() end
end
local function append(event, source)
    local book = A.Book()
    local root = ns.Store.DB().ledger
    root.seq = root.seq + 1
    event.id, event.at, event.source = root.seq, event.at or time(), source or "manual"
    book.events[#book.events + 1] = event
    A.Changed()
    return event.id
end
function A.Market(id)
    local q = ns.Disenchant and ns.Disenchant.Quote(id)
    if not q or q.complete == false or (q.miss or 0) > 0 then return nil end
    return q.price
end
function A.Selling()
    local view = ns.DisenchantUI
    return view and view.selling or {hours = 12, losses = 1}
end
local function nextShare(chain)
    return math.floor(chain.cost * (chain.processed + 1) / chain.count) - math.floor(chain.cost * chain.processed / chain.count)
end
function A.Project(book, since, now)
    book = book or A.Book()
    now = now or time()
    since = since or 0
    local p = {chains = {}, byChain = {}, batches = {}, byBatch = {}, materials = {}, sales = {}, bySale = {},
        posts = {}, byPost = {}, journal = {}, reversed = {}, byEvent = {},
        stages = {sent = 0, unsure = 0, mail = 0, bag = 0, done = 0, lost = 0},
        holding = 0, holdingCount = 0, spent = 0, gross = 0, fees = 0, net = 0, soldCost = 0,
        stockCost = 0, stockValue = 0, unknownStock = false, unknownSales = 0, outputValue = 0}
    for _, event in ipairs(book.events) do
        p.byEvent[event.id] = event
        if event.kind == "reverse" then p.reversed[event.target] = event.id end
    end
    local function material(id)
        local m = p.materials[id]
        if not m then
            m = {itemID = id, received = 0, sold = 0, remaining = 0, posted = 0, cost = 0, net = 0, soldCost = 0}
            p.materials[id] = m
        end
        return m
    end
    for _, event in ipairs(book.events) do
        p.journal[#p.journal + 1] = event
        local live = not p.reversed[event.id] and event.kind ~= "reverse"
        local chain = live and event.target and p.byChain[event.target]
        if live and event.kind == "buy" then
            chain = {id = event.id, itemID = event.itemID, link = event.link, suffix = event.suffix or 0,
                count = event.count, cost = event.cost, owner = event.owner, level = event.level,
                quality = event.quality, band = event.band, at = event.at, source = event.source,
                state = event.sent and "sent" or "bought", received = 0, processed = 0, outputs = {}, events = {event.id}}
            p.chains[#p.chains + 1], p.byChain[chain.id] = chain, chain
        elseif chain and event.kind == "won" then chain.state = "bought"; chain.events[#chain.events + 1] = event.id
        elseif chain and event.kind == "lost" then chain.state = "lost"; chain.events[#chain.events + 1] = event.id
        elseif chain and event.kind == "receive" then
            if chain.state == "sent" then chain.state = "bought" end
            chain.received = math.min(chain.count, chain.received + event.count)
            chain.events[#chain.events + 1] = event.id
        elseif chain and event.kind == "disenchant" then
            if chain.state == "sent" then chain.state = "bought" end
            chain.processed = chain.processed + 1
            chain.received = math.max(chain.received, chain.processed)
            chain.events[#chain.events + 1] = event.id
            for index, output in ipairs(event.outputs) do
                local batch = {id = event.id .. ":" .. index, itemID = output.itemID, count = output.count,
                    cost = output.cost, sold = 0, soldCost = 0, chain = chain.id, at = event.at}
                p.batches[#p.batches + 1], p.byBatch[batch.id] = batch, batch
                chain.outputs[output.itemID] = (chain.outputs[output.itemID] or 0) + output.count
            end
        elseif live and event.kind == "post" then
            local post = {id = event.id, itemID = event.itemID, stack = event.stack, stacks = event.stacks,
                bid = event.bid, buyout = event.buyout, at = event.at, ends = event.at + (event.hours or 24) * 3600,
                sold = 0, removed = 0}
            p.posts[#p.posts + 1], p.byPost[post.id] = post, post
        elseif live and event.kind == "unpost" and p.byPost[event.target] then
            p.byPost[event.target].removed = p.byPost[event.target].removed + 1
        elseif live and event.kind == "sale" then
            local sale = {id = event.id, itemID = event.itemID, count = event.count, gross = event.gross,
                fee = event.fee, net = event.gross - event.fee, at = event.at, post = event.post, cost = 0,
                source = event.source, allocations = event.allocations or {}}
            p.sales[#p.sales + 1], p.bySale[sale.id] = sale, sale
            if sale.post and p.byPost[sale.post] then p.byPost[sale.post].sold = p.byPost[sale.post].sold + 1 end
        elseif live and event.kind == "count" and p.bySale[event.target] then
            local sale = p.bySale[event.target]
            sale.count, sale.allocations = event.count, event.allocations or {}
        end
    end
    for _, sale in ipairs(p.sales) do
        for _, allocation in ipairs(sale.allocations) do
            local batch = p.byBatch[allocation.batch]
            if batch then
                batch.sold, batch.soldCost = batch.sold + allocation.count, batch.soldCost + (allocation.cost or 0)
                sale.cost = sale.cost + (allocation.cost or 0)
                if not allocation.cost then sale.unknownCost = true end
            end
        end
        local m = material(sale.itemID)
        if sale.count then m.sold = m.sold + sale.count else p.unknownSales = p.unknownSales + 1 end
        m.net, m.soldCost = m.net + sale.net, m.soldCost + sale.cost
        if sale.at >= since then
            p.gross, p.fees, p.net, p.soldCost = p.gross + sale.gross, p.fees + sale.fee, p.net + sale.net, p.soldCost + sale.cost
        end
    end
    for _, batch in ipairs(p.batches) do
        local m = material(batch.itemID)
        local remaining = batch.count - batch.sold
        m.received, m.remaining = m.received + batch.count, m.remaining + remaining
        if batch.cost then m.cost = m.cost + batch.cost - batch.soldCost
        elseif remaining > 0 then m.unknownCost = true end
    end
    for _, post in ipairs(p.posts) do
        post.active = post.ends > now and post.sold + post.removed < post.stacks
        if post.active then
            local m = material(post.itemID)
            m.posted = m.posted + post.stack * (post.stacks - post.sold - post.removed)
        end
    end
    local fee = book.fee or 0.05
    local selling = A.Selling()
    for id, m in pairs(p.materials) do
        m.posted = math.min(m.posted, m.remaining)
        m.price = A.Market(id)
        if m.remaining > 0 then
            p.stockCost = p.stockCost + m.cost
            if m.price then
                m.value = math.floor(m.price * m.remaining * (1 - fee))
                p.stockValue = p.stockValue + m.value
            else p.unknownStock = true end
            if m.unknownCost then p.unknownStock = true end
        end
    end
    for _, chain in ipairs(p.chains) do
        local stage = chain.state
        if stage == "sent" and now - chain.at > A.PENDING then stage = "unsure"
        elseif stage == "bought" then
            stage = chain.processed >= chain.count and "done" or (chain.received > chain.processed and "bag" or "mail")
        end
        chain.stage = stage
        local gross, reserve, known = 0, 0, next(chain.outputs) ~= nil
        for id, count in pairs(chain.outputs) do
            local price = A.Market(id)
            if price then gross = gross + price * count else known = false end
            local deposit = ns.Disenchant and ns.Disenchant.Deposit(id, count, fee, selling)
            if deposit then reserve = reserve + deposit * (selling.losses or 0) end
        end
        chain.gross = known and math.floor(gross + 0.5) or nil
        chain.reserve = known and math.floor(reserve + 0.5) or nil
        chain.value = known and math.floor(gross * (1 - fee) - reserve) or nil
        if stage == "done" and chain.value then chain.result = chain.value - chain.cost end
        if chain.at >= since then
            p.stages[stage] = p.stages[stage] + 1
            if stage ~= "lost" and stage ~= "sent" then p.spent = p.spent + chain.cost end
            if chain.value then p.outputValue = p.outputValue + chain.value end
        end
        if stage == "mail" or stage == "bag" or stage == "unsure" then
            local left = chain.cost - math.floor(chain.cost * chain.processed / chain.count)
            p.holding, p.holdingCount = p.holding + left, p.holdingCount + chain.count - chain.processed
        end
    end
    p.realized = p.net - p.soldCost
    p.forecast = not p.unknownStock and (p.realized + p.stockValue - p.stockCost) or nil
    return p
end
local function liveChain(p, id)
    p = p or A.Project()
    return p.byChain[id], p
end
function A.Buy(values, source)
    if not integer(values.itemID, 1, 10000000) or not integer(values.count, 1, 1000)
        or not integer(values.cost, 1) then return nil, "acInvalid" end
    return append({kind = "buy", itemID = values.itemID, link = values.link, suffix = values.suffix or 0,
        count = values.count, cost = values.cost, owner = A.Text(values.owner), level = values.level,
        quality = values.quality, band = values.band, sent = values.sent == true or nil}, source)
end
function A.Resolve(target, won, source)
    local chain = liveChain(nil, target)
    if not chain or chain.state ~= "sent" then return nil, "acState" end
    return append({kind = won and "won" or "lost", target = target}, source)
end
function A.Receive(target, count, source)
    local chain = liveChain(nil, target)
    if not chain or chain.state == "lost" or not integer(count, 1, chain.count - chain.received) then return nil, "acState" end
    return append({kind = "receive", target = target, count = count}, source)
end
function A.Disenchant(target, outputs, source)
    local chain = liveChain(nil, target)
    if not chain or chain.state == "lost" or chain.processed >= chain.count then return nil, "acState" end
    local allowed, combined, order = {}, {}, {}
    for _, itemID in ipairs(ns.disenchantMaterials) do allowed[itemID] = true end
    for _, output in ipairs(outputs) do
        if not allowed[output.itemID] or not integer(output.count, 1, 1000) then return nil, "acInvalid" end
        if not combined[output.itemID] then order[#order + 1] = output.itemID end
        combined[output.itemID] = (combined[output.itemID] or 0) + output.count
    end
    if #order == 0 then return nil, "acInvalid" end
    local weights, total, priced = {}, 0, true
    for _, itemID in ipairs(order) do if not A.Market(itemID) then priced = false end end
    for index, itemID in ipairs(order) do
        weights[index] = combined[itemID] * (priced and A.Market(itemID) or 1)
        total = total + weights[index]
    end
    local share, given, copy = nextShare(chain), 0, {}
    for index, itemID in ipairs(order) do
        local cost = index == #order and share - given or math.floor(share * (weights[index] / total))
        given = given + cost
        copy[index] = {itemID = itemID, count = combined[itemID], cost = cost}
    end
    local id = append({kind = "disenchant", target = target, outputs = copy}, source)
    if ns.DisenchantLog then
        ns.DisenchantLog.Record({itemID = chain.itemID, suffix = chain.suffix, link = chain.link, level = chain.level,
            quality = chain.quality, band = chain.band, outputs = copy, bought = true, chain = chain.id, ledger = id},
            source == "cast" and "cast" or "manual")
    end
    return id
end
function A.Post(values)
    if not integer(values.itemID, 1, 10000000) or not integer(values.stack, 1, 1000)
        or not integer(values.stacks, 1, 100) or not integer(values.bid or 0, 0) then return nil, "acInvalid" end
    return append({kind = "post", itemID = values.itemID, stack = values.stack, stacks = values.stacks,
        bid = values.bid or 0, buyout = values.buyout or 0, hours = values.hours or 24}, "auction")
end
function A.Unpost(target)
    local post = A.Project().byPost[target]
    if not post or not post.active then return nil, "acState" end
    return append({kind = "unpost", target = target}, "auction")
end
local function allocate(p, itemID, count)
    local allocations, left = {}, count
    for _, batch in ipairs(p.batches) do
        if batch.itemID == itemID and left > 0 then
            local take = math.min(left, batch.count - batch.sold)
            if take > 0 then
                local cost = batch.cost and (math.floor(batch.cost * (batch.sold + take) / batch.count) - batch.soldCost) or nil
                allocations[#allocations + 1] = {batch = batch.id, count = take, cost = cost}
                batch.sold, batch.soldCost = batch.sold + take, batch.soldCost + (cost or 0)
                left = left - take
            end
        end
    end
    return allocations, left
end
function A.Sell(values, source)
    if not integer(values.gross, 1) or not integer(values.fee or 0, 0, values.gross)
        or (values.count ~= nil and not integer(values.count, 1, 1000000)) then return nil, "acInvalid" end
    local allocations
    if values.count then allocations = allocate(A.Project(), values.itemID, values.count) end
    return append({kind = "sale", itemID = values.itemID, count = values.count, gross = values.gross,
        fee = values.fee or 0, post = values.post, allocations = allocations, at = values.at}, source)
end
function A.SaleCount(target, count)
    local p = A.Project()
    local sale = p.bySale[target]
    if not sale or not integer(count, 1, 1000000) then return nil, "acInvalid" end
    for _, allocation in ipairs(sale.allocations) do
        local batch = p.byBatch[allocation.batch]
        if batch then batch.sold, batch.soldCost = batch.sold - allocation.count, batch.soldCost - (allocation.cost or 0) end
    end
    return append({kind = "count", target = target, count = count, allocations = (allocate(p, sale.itemID, count))})
end
function A.Reversible(p, event)
    if event.kind == "reverse" or p.reversed[event.id] then return false end
    if event.kind == "buy" then
        local chain = p.byChain[event.id]
        return chain ~= nil and chain.processed == 0
    end
    if event.kind == "disenchant" then
        for index = 1, #event.outputs do
            local batch = p.byBatch[event.id .. ":" .. index]
            if batch and batch.sold > 0 then return false end
        end
        local chain = p.byChain[event.target]
        return chain ~= nil
    end
    return true
end
function A.Reverse(target)
    local p = A.Project()
    local event = p.byEvent[target]
    if not event or not A.Reversible(p, event) then return nil, "acDepends" end
    local id = append({kind = "reverse", target = target})
    if event.kind == "disenchant" and ns.DisenchantLog then ns.DisenchantLog.CancelLedger(target) end
    return id
end
function A.SetFee(fee)
    A.Book().fee = fee; A.Changed()
end
function A.Analysis(p, by)
    local D, fee, selling = ns.Disenchant, A.Book().fee or 0.05, A.Selling()
    local groups, order = {}, {}
    for _, chain in ipairs(p.chains) do
        if chain.processed > 0 and chain.gross then
            local key = by == "level" and (chain.level or 0) or (by == "band" and (chain.band or "?") or chain.itemID)
            local g = groups[key]
            if not g then
                g = {key = key, itemID = chain.itemID, level = chain.level, band = chain.band, count = 0, cost = 0,
                    gross = 0, expected = 0, value = 0, result = 0, units = 0, expectedUnits = 0, known = true,
                    crafted = ns.Crafting and ns.Crafting.byItem and ns.Crafting.byItem[chain.itemID] ~= nil}
                groups[key] = g; order[#order + 1] = g
            end
            local share = chain.processed / chain.count
            g.count = g.count + chain.processed
            g.cost = g.cost + chain.cost * share
            g.gross, g.value = g.gross + chain.gross, g.value + (chain.value or 0)
            g.result = g.result + (chain.value or 0) - chain.cost * share
            local band = chain.band and D and D.Band(chain.band)
            local main = band and D.MainOutput(band)
            if main then
                g.main = g.main or main.itemID
                g.units = g.units + (chain.outputs[main.itemID] or 0)
                g.expectedUnits = g.expectedUnits + main.chance * (main.minCount + main.maxCount) / 2 * chain.processed
            end
            local estimate = band and D.Estimate(band, chain.cost / chain.count, fee, nil, selling)
            if estimate and estimate.gross then g.expected = g.expected + estimate.gross * chain.processed
            else g.known = false end
        end
    end
    for _, g in ipairs(order) do
        g.luck = g.known and g.expected > 0 and g.gross / g.expected * 100 or nil
    end
    table.sort(order, function(a, b)
        if a.result ~= b.result then return a.result < b.result end
        return a.count > b.count
    end)
    return order
end
function A.Levels(itemID)
    local p = A.Project()
    local m = p.materials[itemID]
    if not m then return end
    local fee = A.Book().fee or 0.05
    local levels = {sales = {}, count = m.remaining}
    if m.remaining > 0 and not m.unknownCost then
        levels.cost = m.cost / m.remaining
        levels.breakEven = math.ceil(levels.cost / (1 - fee))
    end
    for _, sale in ipairs(p.sales) do
        if sale.itemID == itemID and sale.count then
            levels.sales[#levels.sales + 1] = {at = sale.at, price = sale.gross / sale.count, count = sale.count}
        end
    end
    return levels
end
