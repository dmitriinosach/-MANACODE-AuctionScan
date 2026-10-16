local _, ns = ...
local R = {}
ns.Reagents = R
function R.Items()
    local items, seen = {}, {}
    for id in pairs(ns.Crafting.inputs) do seen[id] = true end
    for _, family in ipairs(ns.gemFamilies) do seen[family.raw] = true end
    for id in pairs(seen) do items[#items + 1] = {raw = id} end
    table.sort(items, function(a, b) return ns.Markets.Name(a.raw) < ns.Markets.Name(b.raw) end)
    return items
end
function R.Uses(id, fee)
    local uses = {}
    for _, key in ipairs(ns.Crafting.order) do
        local catalog = ns.craftCatalogs[key]
        if catalog then
            for _, recipe in ipairs(catalog.recipes) do
                for _, input in ipairs(recipe.inputs) do
                    if input[1] == id then
                        local estimate = ns.Crafting.Estimate(recipe, fee)
                        local market, basis = ns.Markets.Quote(id), ns.Crafting.Quote(id)
                        local gain
                        if estimate.revenue and market and market.price and market.miss == 0
                            and not market.vendor and basis and basis.price then
                            gain = (estimate.revenue - estimate.cost + basis.price * input[2]) / input[2]
                                - market.price * (1 - fee)
                        end
                        uses[#uses + 1] = {recipe = recipe, count = input[2], estimate = estimate,
                            gain = gain}
                    end
                end
            end
        end
    end
    table.sort(uses, function(a, b)
        if a.gain == b.gain then return a.recipe.raw < b.recipe.raw end
        if a.gain == nil then return false end
        if b.gain == nil then return true end
        return a.gain > b.gain
    end)
    return uses
end
function R.Complete(id, force)
    local ids = {id}
    for _, use in ipairs(R.Uses(id, 0.05)) do
        for _, target in ipairs(ns.Crafting.Targets(use.recipe)) do ids[#ids + 1] = target end
    end
    return ns.Batch.Complete(ids, force)
end
function R.Packs(id, fee)
    local result, quote = {}, ns.Markets.Quote(id)
    local item = ns.Markets.Item(id)
    local observation = item and item.observations[item.quote.scanID]
    local offers = ns.Markets.Offers(id)
    local reference
    for _, offer in ipairs(offers) do
        if offer.price and offer.owner ~= UnitName("player") then reference = math.min(reference or math.huge, offer.price) end
    end
    local maximum = select(8, ns.Compat.ItemInfo(id))
    local function add(count, recipe)
        local size = math.min(count, type(maximum) == "number" and maximum > 0 and maximum or count)
        local entry = {raw = recipe and recipe.raw or id, count = size, needed = count, recipe = recipe, lots = 0}
        for _, offer in ipairs(offers) do
            if offer.count == size and offer.buyout > 0 and offer.owner ~= UnitName("player") then
                entry.price = math.min(entry.price or math.huge, offer.buyout)
                entry.lots = entry.lots + 1
            end
        end
        if observation and observation.complete and not observation.truncated and quote and reference
            and quote.miss == 0 and entry.price then
            entry.net = entry.price * (1 - fee)
            entry.premium = entry.net - reference * size * (1 - fee)
        end
        result[#result + 1] = entry
    end
    add(1)
    for _, use in ipairs(R.Uses(id, fee)) do add(use.count, use.recipe) end
    return result
end
