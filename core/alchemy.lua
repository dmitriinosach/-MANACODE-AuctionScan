local _, ns = ...
local A = {}
ns.Alchemy = A
ns.Crafting = A
ns.craftCatalogs = ns.craftCatalogs or {}
ns.craftCatalogs.alchemy = {labelKey = "alchemySection", recipes = ns.alchemyRecipes}
A.order = {"alchemy", "enchanting", "tailoring", "blacksmithing"}
A.items, A.inputs, A.byItem = {}, {}, {}
for _, key in ipairs(A.order) do
    local catalog = ns.craftCatalogs[key]
    if catalog then
        catalog.byItem = {}
        for _, recipe in ipairs(catalog.recipes) do
            recipe.profession = key
            catalog.byItem[recipe.raw], A.byItem[recipe.raw], A.items[recipe.raw] = recipe, recipe, true
            for _, input in ipairs(recipe.inputs) do
                A.items[input[1]], A.inputs[input[1]] = true, true
            end
        end
    end
end
local function prices()
    local db = ns.Store.DB()
    db.alchemyPrices = db.alchemyPrices or {}
    local key = (GetRealmName() or "") .. "|" .. (UnitFactionGroup("player") or "")
    db.alchemyPrices[key] = db.alchemyPrices[key] or {}
    return db.alchemyPrices[key]
end
function A.IsInput(id)
    return A.inputs[id] or false
end
function A.SetPrice(id, copper)
    if not A.IsInput(id) or ns.vendorPrices[id] then return false end
    if copper and (copper ~= copper or copper < 0 or copper > 1000000000) then return false end
    prices()[id] = copper and math.floor(copper + 0.5) or nil
    return true
end
function A.Quote(id)
    local q = ns.Markets.Quote(id)
    if ns.vendorPrices[id] then return q end
    local price = prices()[id]
    if price == nil then return q end
    return {price = price, miss = 0, units = q and q.units or 0, lots = q and q.lots or 0, at = time(), manual = true}
end
function A.Estimate(recipe, fee)
    local cost = 0
    for _, input in ipairs(recipe.inputs) do
        local q = A.Quote(input[1])
        if not q or not q.price or q.miss > 0 then return {} end
        cost = cost + q.price * input[2]
    end
    local result = {cost = cost, unitCost = cost / recipe.count}
    local output = ns.Markets.Quote(recipe.raw)
    if output and output.price and output.miss == 0 then
        result.revenue = output.price * recipe.count * (1 - fee)
        result.margin = result.revenue - cost
        result.unitMargin = result.margin / recipe.count
    end
    return result
end
function A.Targets(recipe)
    if ns.CraftPlan then return ns.CraftPlan.Targets(recipe) end
    local ids = {recipe.raw}
    for _, input in ipairs(recipe.inputs) do
        if ns.vendorPrices[input[1]] or prices()[input[1]] == nil then ids[#ids + 1] = input[1] end
    end
    return ids
end
function A.Scan(recipe)
    if ns.Hidden.Is(recipe.raw) then return false end
    return ns.Batch.Start(A.Targets(recipe))
end
function A.RecipeSources(recipe, options)
    return options and ns.CraftPlan.Targets(recipe, options) or A.Targets(recipe)
end
function A.Complete(recipe, force, options)
    if ns.Hidden.Is(recipe.raw) then return false end
    return ns.Batch.Complete(A.RecipeSources(recipe, options), force)
end
function A.ProfessionSources(profession)
    local ids = {}
    for _, recipe in ipairs(ns.Hidden.Filter(ns.craftCatalogs[profession].recipes, false)) do
        for _, id in ipairs(A.Targets(recipe)) do ids[#ids + 1] = id end
    end
    return ids
end
function A.CompleteProfession(profession, force)
    return ns.Batch.Complete(A.ProfessionSources(profession), force, true)
end
