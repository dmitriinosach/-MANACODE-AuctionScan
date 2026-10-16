local _, ns = ...
local P = {}
ns.CraftPlan = P
local function sum(left, right)
    if left == nil or right == nil then return nil end
    return left + right
end
function P.Build(recipe, options)
    local stock, path, rows = {}, {[recipe.raw] = true}, {}
    local function material(id, quantity, depth)
        local quote = ns.Crafting.Quote(id)
        local price = quote and quote.miss == 0 and quote.price or nil
        local child = ns.Crafting.byItem[id]
        local make = options.make and options.make[id]
        if make == nil then make = options.craftAll end
        local expandable = child and not path[id] and depth < 8
        local node = {id = id, count = quantity, depth = depth, quote = quote, expandable = expandable,
            crafted = make and expandable or false, own = 0, need = quantity, children = {}}
        rows[#rows + 1] = node
        if options.ignore and options.ignore[id] then
            node.excluded, node.crafted, node.own, node.need, node.value, node.cash = true, false, quantity, 0, 0, 0
            return node
        end
        if options.owned and not ns.vendorPrices[id] then
            if stock[id] == nil then stock[id] = math.max(0, GetItemCount(id, true) or 0) end
            node.own = math.min(quantity, stock[id])
            stock[id] = stock[id] - node.own
            node.need = quantity - node.own
        end
        node.value = node.own == 0 and 0 or (price and node.own * price)
        node.cash = 0
        if node.crafted and node.need > 0 then
            path[id] = true
            node.crafts = math.ceil(node.need / child.count)
            node.extra = node.crafts * child.count - node.need
            for _, input in ipairs(child.inputs) do
                local part = material(input[1], input[2] * node.crafts, depth + 1)
                node.children[#node.children + 1] = part
                node.value, node.cash = sum(node.value, part.value), sum(node.cash, part.cash)
            end
            path[id] = nil
        elseif node.need > 0 then
            node.cash = price and node.need * price
            node.value = sum(node.value, node.cash)
        end
        return node
    end
    local result = {rows = rows, cost = 0, cash = 0, count = recipe.count}
    for _, input in ipairs(recipe.inputs) do
        local node = material(input[1], input[2], 0)
        result.cost, result.cash = sum(result.cost, node.value), sum(result.cash, node.cash)
    end
    local output = ns.Markets.Quote(recipe.raw)
    if output and output.price and output.miss == 0 then
        result.revenue = output.price * recipe.count * (1 - (options.fee or 0.05))
        if result.cost then result.margin = result.revenue - result.cost end
    end
    return result
end
function P.Stock(recipe)
    local crafts
    for _, input in ipairs(recipe.inputs) do
        local enough = math.floor(math.max(0, GetItemCount(input[1], true) or 0) / input[2])
        crafts = math.min(crafts or enough, enough)
    end
    return crafts or 0
end
function P.Rank(recipes, options)
    local ranked = {}
    for _, recipe in ipairs(recipes) do
        if not (ns.Hidden and ns.Hidden.Is(recipe.raw)) then
            ranked[#ranked + 1] = {raw = recipe.raw, recipe = recipe, plan = P.Build(recipe, options)}
        end
    end
    table.sort(ranked, function(a, b)
        local left, right = a.plan.margin, b.plan.margin
        if left == right then return ns.Markets.Name(a.raw) < ns.Markets.Name(b.raw) end
        if left == nil then return false end
        if right == nil then return true end
        return left > right
    end)
    return ns.Collections and ns.Collections.Order(ranked) or ranked
end
function P.Targets(recipe, options)
    local ids, seen = {recipe.raw}, {[recipe.raw] = true}
    if options then
        for _, row in ipairs(P.Build(recipe, options).rows) do
            local quote = ns.Crafting.Quote(row.id)
            if not row.excluded and not seen[row.id] and not (quote and quote.manual) then
                seen[row.id] = true
                ids[#ids + 1] = row.id
            end
        end
        return ids
    end
    local function visit(current, depth)
        if depth > 8 then return end
        for _, input in ipairs(current.inputs) do
            local id = input[1]
            if not seen[id] then
                seen[id] = true
                local quote = ns.Crafting.Quote(id)
                if ns.vendorPrices[id] or not (quote and quote.manual) then ids[#ids + 1] = id end
                if ns.Crafting.byItem[id] then visit(ns.Crafting.byItem[id], depth + 1) end
            end
        end
    end
    visit(recipe, 0)
    return ids
end
