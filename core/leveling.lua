local _, ns = ...
local L = {}
ns.Leveling = L
local function integer(value, fallback, low, high)
    value = tonumber(value)
    if not value or value ~= value then value = fallback end
    return math.max(low, math.min(high, math.floor(value)))
end
function L.Options(options)
    options = options or {}
    local first = integer(options.first, 1, 1, 450)
    return {first = first, target = integer(options.target, 450, first, 450),
        tool = integer(options.tool, 0, 0, 9), reserve = integer(options.reserve, 0, 0, 20),
        owned = options.owned == true, choices = options.choices or {}, known = options.known or {},
        make = options.make or {}, open = options.open or {}}
end
function L.Obtain(id)
    return ns.levelingCatalogs.enchanting.obtains[id] or ns.Crafting.byItem[id]
end
function L.Quote(id)
    local vendor = ns.levelingCatalogs.enchanting.vendors[id]
    if vendor then return {price = vendor, vendor = true, complete = true, miss = 0} end
    return ns.Markets.Quote(id)
end
local function price(quote)
    if quote and quote.price and quote.complete and (quote.miss or 0) == 0 then return quote.price end
end
local function unitCost(id, options, quotes, path)
    local obtain = options.make[id] and L.Obtain(id)
    if obtain and not path[id] then
        path[id] = true
        local total = 0
        for _, input in ipairs(obtain.inputs) do
            local cost = unitCost(input[1], options, quotes, path)
            if cost == nil then path[id] = nil; return nil end
            total = total + cost * input[2]
        end
        path[id] = nil
        return total / obtain.count
    end
    if quotes[id] == nil then quotes[id] = L.Quote(id) or false end
    return price(quotes[id])
end
local function better(left, right)
    if not right then return true end
    if left.missing ~= right.missing then return left.missing < right.missing end
    return left.cost < right.cost
end
local function contains(mask, bit)
    return math.floor(mask / bit) % 2 == 1
end
function L.Stages(catalog, options)
    local out = {}
    for index, stage in ipairs(catalog.stages) do
        local first, target = math.max(options.first, stage.first), math.min(options.target, stage.target)
        if first < target then out[#out + 1] = {index = index, first = first, target = target, choices = stage.choices} end
    end
    return out
end
local function transition(catalog, options, stage, recipe, previous, quotes)
    if recipe.requiredSkill > stage.first or recipe.gray < stage.target then return nil end
    local step = {first = stage.first, target = stage.target, index = stage.index, spell = recipe.spellID,
        tools = {}, inputs = {}, cost = 0, missing = 0, tool = previous.tool, mask = previous.mask,
        gains = 0, prev = previous}
    local skill = stage.first
    local function add(id, count)
        if count <= 0 then return end
        step.inputs[id] = (step.inputs[id] or 0) + count
        local value = unitCost(id, options, quotes, {})
        if value then step.cost = step.cost + value * count else step.missing = step.missing + 1 end
    end
    local function learn(part)
        if not part.acquisition or options.known[part.spellID] then return end
        local bit = part.acquisition.bit
        if contains(step.mask, bit) then return end
        step.mask = step.mask + bit
        for _, input in ipairs(part.acquisition.inputs) do add(input[1], input[2]) end
    end
    for tier = previous.tool + 1, recipe.tool do
        local tool = catalog.recipes[catalog.tools[tier].spell]
        if tool.requiredSkill > skill then return nil end
        learn(tool)
        for _, input in ipairs(tool.inputs) do
            if tier == 1 or input[1] ~= catalog.tools[tier - 1].item then add(input[1], input[2]) end
        end
        local gain = skill < tool.gray and skill < stage.target
        if gain and skill >= tool.yellow then step.toolUncertain = true end
        step.tools[#step.tools + 1] = {spell = tool.spellID, item = catalog.tools[tier].item, gain = gain}
        if gain then skill = skill + 1; step.gains = step.gains + 1 end
        step.tool = tier
    end
    step.count = stage.target - skill
    step.uncertain = step.toolUncertain or (step.count > 0 and stage.target - 1 >= recipe.yellow)
    step.extra = step.uncertain and options.reserve or 0
    if step.count + step.extra > 0 then
        learn(recipe)
        for _, input in ipairs(recipe.inputs) do add(input[1], input[2] * (step.count + step.extra)) end
    end
    step.totalCost, step.totalMissing = previous.cost + step.cost, previous.missing + step.missing
    return step
end
function L.Route(options)
    local catalog = ns.levelingCatalogs.enchanting
    local p = L.Options(options)
    local initial = {cost = 0, missing = 0, tool = p.tool, mask = 0}
    local states, quotes, comparison = {initial}, {}, true
    for _, stage in ipairs(L.Stages(catalog, p)) do
        local nextStates, keys = {}, {}
        for _, previous in ipairs(states) do
            for _, spell in ipairs(stage.choices) do
                if not p.choices[stage.index] or p.choices[stage.index] == spell then
                    local step = transition(catalog, p, stage, catalog.recipes[spell], previous, quotes)
                    if step then
                        if step.missing > 0 then comparison = false end
                        local key = step.tool .. ":" .. step.mask
                        local candidate = {cost = step.totalCost, missing = step.totalMissing,
                            tool = step.tool, mask = step.mask, step = step}
                        if better(candidate, keys[key]) then keys[key] = candidate end
                    end
                end
            end
        end
        for _, candidate in pairs(keys) do nextStates[#nextStates + 1] = candidate end
        table.sort(nextStates, function(a, b)
            if a.tool ~= b.tool then return a.tool < b.tool end
            return a.mask < b.mask
        end)
        states = nextStates
        if #states == 0 then return {options = p, steps = {}, inputs = {}, unavailable = true, comparison = false} end
    end
    local best
    for _, candidate in ipairs(states) do if better(candidate, best) then best = candidate end end
    local out = {options = p, steps = {}, inputs = {}, comparison = comparison, stateCount = #states,
        catalogVersion = catalog.version, cost = best and best.cost, missing = best and best.missing or 0}
    local step = best and best.step
    while step do table.insert(out.steps, 1, step); step = step.prev.step end
    for _, part in ipairs(out.steps) do
        for id, count in pairs(part.inputs) do out.inputs[id] = (out.inputs[id] or 0) + count end
    end
    return out
end
function L.Alternatives(route, step)
    local catalog, out = ns.levelingCatalogs.enchanting, {}
    local stage = {first = step.first, target = step.target, index = step.index}
    for _, spell in ipairs(catalog.stages[step.index].choices) do
        local candidate = transition(catalog, route.options, stage, catalog.recipes[spell], step.prev, {})
        if candidate then out[#out + 1] = candidate end
    end
    return out
end
local function purchase(need, id)
    if need == 0 then return {cost = 0, units = 0} end
    if need > 1000 or not ns.Markets.Fresh(id) then return nil end
    local item, q = ns.Markets.Item(id), L.Quote(id)
    if not item or not q or q.shared then return nil end
    local observation = item.observations[item.quote.scanID]
    if not observation or observation.truncated then return nil end
    local groups, offers, me = {}, {}, UnitName("player")
    for _, lot in ipairs(ns.Markets.Offers(id)) do
        if lot.buyout > 0 and lot.count > 0 and lot.owner ~= "" and lot.owner ~= me then
            local key = lot.count .. ":" .. lot.buyout
            if not groups[key] then
                groups[key] = {stack = lot.count, buyout = lot.buyout, count = 0, page = 0}
                offers[#offers + 1] = groups[key]
            end
            groups[key].count = groups[key].count + 1
        end
    end
    return ns.Plan.Options(offers, need)[1]
end
function L.Basket(route)
    local p, stock, surplus, pending, used, roots = route.options, {}, {}, {}, {}, {}
    local rows, leaves = {}, {}
    local out = {rows = rows, leaves = leaves, roots = roots, cost = 0, cash = 0, lotsCost = 0,
        missing = 0, cashMissing = 0, stale = 0, unavailable = route.unavailable, extra = 0}
    local function build(id, count, depth, path)
        local q, obtain = L.Quote(id), L.Obtain(id)
        local expandable = obtain and not path[id] and depth < 8
        local make = p.make[id] and expandable or false
        local row = {id = id, count = count, depth = depth, quote = q, expandable = expandable,
            crafted = make, opened = p.open[id], children = {}, own = 0, need = count}
        rows[#rows + 1] = row
        local missingBefore = out.missing
        row.reused = math.min(count, surplus[id] or 0)
        surplus[id] = (surplus[id] or 0) - row.reused
        if p.owned then
            if stock[id] == nil then stock[id] = math.max(0, GetItemCount(id, true) or 0) end
            row.own = math.min(count - row.reused, stock[id]); stock[id] = stock[id] - row.own
        end
        row.need = count - row.own - row.reused
        local unit = price(q)
        if (row.own > 0 or (not make and row.need > 0)) and q and not q.vendor and not ns.Markets.Fresh(id) then
            out.stale = out.stale + 1
        end
        row.cost, row.cash, row.lotsCost = unit and row.own * unit or 0, 0, 0
        if row.own > 0 and not unit then out.missing = out.missing + 1 end
        if make and row.need > 0 then
            local crafts = math.ceil(row.need / obtain.count)
            row.extra = crafts * obtain.count - row.need
            surplus[id] = (surplus[id] or 0) + row.extra
            path[id] = true
            for _, input in ipairs(obtain.inputs) do
                local child = build(input[1], input[2] * crafts, depth + 1, path)
                row.children[#row.children + 1] = child
                row.cost, row.cash, row.lotsCost = row.cost + child.cost, row.cash + child.cash, row.lotsCost + child.lotsCost
            end
            path[id] = nil
        elseif row.need > 0 then
            local leaf = leaves[id]
            if not leaf then leaf = {id = id, need = 0, quote = q}; leaves[id] = leaf end
            leaf.need = leaf.need + row.need
            if unit then row.cash = row.need * unit; row.cost = row.cost + row.cash
            else out.missing = out.missing + 1; out.cashMissing = out.cashMissing + 1 end
        end
        row.incomplete = out.missing > missingBefore
        return row
    end
    local ids = {}
    for id, count in pairs(route.inputs) do pending[id] = count; ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        if not used[id] then
            used[id] = true
            local row = build(id, pending[id], 0, {})
            roots[#roots + 1] = row
            out.cost, out.cash = out.cost + row.cost, out.cash + row.cash
        end
    end
    out.lotsMissing = 0
    for _, leaf in pairs(leaves) do
        local batch = ns.levelingCatalogs.enchanting.vendorBatches[leaf.id] or 1
        local units = math.ceil(leaf.need / batch) * batch
        local plan = leaf.quote and leaf.quote.vendor and {cost = units * leaf.quote.price, units = units}
            or purchase(leaf.need, leaf.id)
        leaf.plan = plan
        if plan then out.lotsCost = out.lotsCost + plan.cost else out.lotsMissing = out.lotsMissing + 1 end
    end
    if out.missing > 0 then out.cost = nil end
    if out.cashMissing > 0 then out.cash = nil end
    if out.lotsMissing > 0 then out.lotsCost = nil end
    return out
end
function L.Targets(options, all)
    local p, catalog, seen, ids = L.Options(options), ns.levelingCatalogs.enchanting, {}, {}
    local function add(id, path)
        if seen[id] or catalog.vendors[id] or ns.vendorPrices[id] then return end
        seen[id] = true; ids[#ids + 1] = id
        local obtain = L.Obtain(id)
        if obtain and not path[id] and (all or p.make[id]) then
            path[id] = true
            for _, input in ipairs(obtain.inputs) do add(input[1], path) end
            path[id] = nil
        end
    end
    if all then
        local maxTool = p.tool
        for _, stage in ipairs(L.Stages(catalog, p)) do
            for _, spell in ipairs(stage.choices) do
                local r = catalog.recipes[spell]; maxTool = math.max(maxTool, r.tool)
                for _, input in ipairs(r.inputs) do add(input[1], {}) end
                if r.acquisition and not p.known[spell] then
                    for _, input in ipairs(r.acquisition.inputs) do add(input[1], {}) end
                end
            end
        end
        for tier = p.tool + 1, maxTool do
            local r = catalog.recipes[catalog.tools[tier].spell]
            for _, input in ipairs(r.inputs) do
                if tier == 1 or input[1] ~= catalog.tools[tier - 1].item then add(input[1], {}) end
            end
            if r.acquisition and not p.known[r.spellID] then
                for _, input in ipairs(r.acquisition.inputs) do add(input[1], {}) end
            end
        end
    else
        local basket = L.Basket(L.Route(p))
        for id in pairs(basket.leaves) do
            if not seen[id] and not catalog.vendors[id] and not ns.vendorPrices[id] then
                seen[id] = true; ids[#ids + 1] = id
            end
        end
    end
    table.sort(ids)
    return ids
end
function L.Complete(options, all, force)
    return ns.Batch.Complete(L.Targets(options, all), force, true)
end
