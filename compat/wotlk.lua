local ADDON, ns = ...
local C = {}
ns.Compat = C
C.family = "wotlk"
function C.ItemInfo(id)
    return GetItemInfo(id)
end
function C.SpellIcon(id)
    if not GetSpellInfo then return nil, nil end
    local name, _, icon = GetSpellInfo(id)
    return name, icon
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
