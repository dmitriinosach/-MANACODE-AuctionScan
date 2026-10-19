local _, ns = ...
local R = {}
ns.Recipes = R
local function book()
    local db = ns.Store.DB()
    local key = (GetRealmName() or "") .. "|" .. (UnitName("player") or "")
    db.recipeBook = db.recipeBook or {}
    db.recipeBook[key] = db.recipeBook[key] or {known = {}, checked = {}}
    return db.recipeBook[key]
end
local function complete()
    local box = _G["TradeSkillFrameAvailableFilterCheckButton"]
    if box and box:GetChecked() then return false end
    local text = GetTradeSkillItemNameFilter and GetTradeSkillItemNameFilter()
    if text and text ~= "" then return false end
    if GetTradeSkillSubClassFilter and not GetTradeSkillSubClassFilter(0) then return false end
    if GetTradeSkillInvSlotFilter and not GetTradeSkillInvSlotFilter(0) then return false end
    return true
end
function R.Read()
    if not GetTradeSkillLine or not GetNumTradeSkills or not GetTradeSkillRecipeLink then return false end
    if IsTradeSkillLinked and IsTradeSkillLinked() then return false end
    local line = GetTradeSkillLine()
    if not line or line == "UNKNOWN" then return false end
    local entry, seen, full = book(), {}, complete()
    for i = 1, GetNumTradeSkills() do
        local _, kind, _, expanded = GetTradeSkillInfo(i)
        if kind == "header" then
            if not expanded then full = false end
        else
            local link = GetTradeSkillRecipeLink(i)
            local spell = link and tonumber(link:match("enchant:(%d+)"))
            if spell then seen[spell] = true end
        end
    end
    for spell in pairs(seen) do entry.known[spell] = line end
    if full then
        for spell, owner in pairs(entry.known) do
            if owner == line and not seen[spell] then entry.known[spell] = nil end
        end
        entry.checked[line] = time()
    end
    return true
end
function R.Known(spell, profession)
    if not spell then return nil end
    local entry = book()
    if entry.known[spell] then return true end
    if profession and entry.checked[profession] then return false end
    return nil
end
function R.Checked(profession)
    return book().checked[profession]
end
local events = ns.NewFrame("Frame")
ns.Listen(events, "TRADE_SKILL_SHOW")
ns.Listen(events, "TRADE_SKILL_UPDATE")
events:SetScript("OnEvent", function()
    if R.Read() and ns.Trader and ns.Trader.frame and ns.Trader.frame:IsShown() then ns.Trader.Refresh() end
end)
