local _, ns = ...
local S = { items = {}, offers = {}, options = {}, need = 1, got = 0, spent = 0, run = false, selected = 1 }
local Shop = { state = S }
ns.Shopping = Shop
Shop.onChange = nil
function Shop.Got()
    return S.got + (S.run and ns.Buy.state.bought or 0)
end
function Shop.Spent()
    return S.spent + (S.run and ns.Buy.state.spent or 0)
end
function Shop.Left()
    return math.max(0, S.need - Shop.Got())
end
local function changed()
    if Shop.onChange then Shop.onChange() end
end
function Shop.Replan()
    S.options = Shop.Left() > 0 and ns.Plan.Options(S.offers, Shop.Left()) or {}
    S.plan = S.options[1] and ns.Plan.Copy(S.options[1]) or nil
    changed()
end
function Shop.SetNeed(need)
    if ns.Buy.Active() then return end
    need = math.max(1, math.min(1000, math.floor(need or 1)))
    if need == S.need then return end
    if Shop.Left() == 0 then S.got, S.spent, S.run = 0, 0, false end
    S.need = need
    Shop.Replan()
end
function Shop.Select(id)
    if ns.Buy.Active() then return end
    for _, item in ipairs(S.items) do
        if item.id == id then
            if S.itemID ~= id then S.got, S.spent, S.run = 0, 0, false end
            S.itemID, S.name, S.offers = id, item.name, item.offers
            Shop.Replan()
            return
        end
    end
end
function Shop.Option(option)
    if ns.Buy.Active() or not S.options[option] then return end
    S.plan = ns.Plan.Copy(S.options[option])
    changed()
end
function Shop.Adjust(offer, delta)
    if ns.Buy.Active() or not S.plan then return end
    ns.Plan.Adjust(S.plan, offer, delta)
    changed()
end
function Shop.Reset()
    if ns.Buy.Active() then return end
    S.got, S.spent, S.run = 0, 0, false
    Shop.Replan()
end
function Shop.Search(query, itemID)
    query = (query or ""):match("^%s*(.-)%s*$")
    if query == "" then ns.say(ns.T("buySearchHint")); return false end
    if ns.Buy.Active() then ns.say(ns.T("sayBusy")); return false end
    if not ns.Scan.Start("pages", { itemID = itemID, query = ns.Query.Name(query) }) then return false end
    S.pendingID = ns.Scan.state.scan.id
    changed()
    return true
end
function Shop.Accept(scan)
    if not scan or scan.id ~= S.pendingID then return end
    S.pendingID = nil
    if (scan.miss or 0) > 0 then
        S.items, S.offers, S.plan, S.options = {}, {}, nil, {}
        ns.say(ns.T("buyIncomplete"))
        return changed()
    end
    local byID, items = {}, {}
    local me = UnitName("player")
    for _, text in ipairs(scan.lots) do
        local lot = ns.Lot.Decode(text)
        if lot and lot.buyout > 0 and lot.count > 0 and lot.owner ~= "" and lot.owner ~= me then
            local item = byID[lot.item]
            if not item then
                local stored = ns.Store.DB().items[lot.item]
                item = { id = lot.item, name = stored and stored:match("^[^\t]+") or ns.Markets.Name(lot.item), offers = {}, groups = {} }
                byID[lot.item], items[#items + 1] = item, item
            end
            local key = lot.count .. ":" .. lot.buyout
            local offer = item.groups[key]
            if not offer then
                offer = { stack = lot.count, buyout = lot.buyout, count = 0, page = 0 }
                item.groups[key] = offer
                item.offers[#item.offers + 1] = offer
            end
            offer.count = offer.count + 1
        end
    end
    table.sort(items, function(a, b) return a.name < b.name end)
    for _, item in ipairs(items) do
        table.sort(item.offers, function(a, b) return a.buyout * b.stack < b.buyout * a.stack end)
    end
    S.items = items
    if items[1] then
        Shop.Select(byID[S.itemID] and S.itemID or items[1].id)
    else
        S.itemID, S.name, S.offers = nil, nil, {}
        Shop.Replan()
    end
end
function Shop.Go()
    if ns.Buy.Active() then return ns.Buy.Confirm() end
    if not S.plan or S.plan.lots == 0 or Shop.Left() == 0 then return false end
    local got, spent = Shop.Got(), Shop.Spent()
    if not ns.Buy.Start(S.name, S.plan, S.itemID) then return false end
    S.got, S.spent, S.run = got, spent, true
    changed()
    return true
end
ns.Buy.onChange = function()
    if ns.Buy.Active() then changed() else Shop.Replan() end
    if ns.Disenchant then ns.Disenchant.BuyChanged() end
end
