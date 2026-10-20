local ADDON, ns = ...
local C = {}
ns.Compat = C
C.family = "wotlk"
function C.ItemInfo(id)
    return GetItemInfo(id)
end
local query = {asked = {}, waiting = {}, done = {}}
local function watch(_, elapsed)
    query.tick, query.age = query.tick + elapsed, query.age + elapsed
    if query.tick < 0.5 then return end
    query.tick = 0
    local arrived, left = false, false
    for id in pairs(query.waiting) do
        if GetItemInfo(id) then query.waiting[id] = nil; arrived = true else left = true end
    end
    if arrived then
        local done = query.done
        query.done = {}
        for fn in pairs(done) do fn() end
        if left then for fn in pairs(done) do query.done[fn] = true end end
    end
    if not left or query.age > 10 then query.waiting, query.done = {}, {}; query.driver:SetScript("OnUpdate", nil) end
end
function C.RequestItem(id, done)
    if type(id) ~= "number" or query.asked[id] or GetItemInfo(id) then return end
    query.asked[id] = true
    if not query.tip then
        query.tip = ns.NewFrame("GameTooltip", "ManaCodeItemQueryTip", UIParent, "GameTooltipTemplate")
        query.driver = ns.NewFrame("Frame", "ManaCodeItemQuery")
    end
    query.tip:SetOwner(UIParent, "ANCHOR_NONE")
    query.tip:SetHyperlink("item:" .. id)
    query.tip:Hide()
    query.waiting[id] = true
    if done then query.done[done] = true end
    query.tick, query.age = 0, 0
    query.driver:SetScript("OnUpdate", watch)
end
function C.SpellIcon(id)
    if not GetSpellInfo then return nil, nil end
    local name, _, icon = GetSpellInfo(id)
    return name, icon
end
function C.SpellKnown(id)
    local name = C.SpellIcon(id)
    return name ~= nil and GetSpellInfo(name) ~= nil
end
function C.BagSlots(bag)
    if GetContainerNumSlots then return GetContainerNumSlots(bag) end
end
function C.BagItemIcon(bag, slot)
    if GetContainerItemInfo then return GetContainerItemInfo(bag, slot) end
end
function C.AuctionFilter(id)
    if not id or not GetAuctionItemClasses or not GetAuctionItemSubClasses then return nil, nil end
    local _, _, _, _, _, className, subName = C.ItemInfo(id)
    if not className then return nil, nil end
    for classIndex, name in ipairs({GetAuctionItemClasses()}) do
        if name == className then
            for subIndex, sub in ipairs({GetAuctionItemSubClasses(classIndex)}) do
                if sub == subName then return classIndex, subIndex end
            end
            return classIndex, nil
        end
    end
    return nil, nil
end
function ns.NewFrame(kind, name, parent, template)
    return CreateFrame(kind, name, parent, template)
end
function ns.Listen(frame, event)
    frame:RegisterEvent(event)
    return true
end
function ns.Gradient(texture, orient, r1, g1, b1, a1, r2, g2, b2, a2)
    texture:SetGradientAlpha(orient, r1, g1, b1, a1, r2, g2, b2, a2)
end
function ns.SetFont(fs, path, size, flags)
    if path then fs:SetFont(path, size, flags or "") end
end
