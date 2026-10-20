local _, ns = ...
local UI = {buttons = {}}
UI.__index = UI
ns.CollectUI = UI
local C = ns.Collect
function UI.DisenchantButton(parent, width)
    local K = ns.TradeKit
    local b = K.Button(parent, "", width, function(self)
        if InCombatLockdown() then return end
        self:SetAttribute("type", "macro")
        self:SetAttribute("macrotext", C.DisenchantMacro((C.NextDisenchant())))
    end, "control", "SecureActionButtonTemplate")
    K.Tooltip(b, ns.T("collectDisenchantTitle"), ns.T("collectDisenchantTip"))
    b:HookScript("OnShow", function() UI.RenderDisenchant(b) end)
    UI.buttons[#UI.buttons + 1] = b
    UI.RenderDisenchant(b)
    return b
end
function UI.Attach(parent, width, place)
    if InCombatLockdown() then
        UI.waiting = UI.waiting or {}
        UI.waiting[#UI.waiting + 1] = {parent = parent, width = width, place = place}
        return
    end
    place(UI.DisenchantButton(parent, width))
end
function UI.RenderDisenchant(b)
    local target, total = C.NextDisenchant()
    b:SetText(ns.T("collectDisenchant", total))
    if InCombatLockdown() then return end
    if target and ns.Compat.SpellKnown(13262) then b:Enable() else b:Disable() end
end
function UI:New(parent)
    local K = ns.TradeKit
    local view = setmetatable({}, self)
    local f = ns.NewFrame("Frame", nil, parent)
    f:SetWidth(330); f:SetHeight(92)
    f:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 14, 72)
    f:EnableMouse(true)
    K.Panel(f)
    view.frame = f
    view.heading = K.Label(f, ns.T("collectTitle"), 12, -10, 306, "heading")
    view.mail = K.Label(f, "", 12, -30, 150, "secondary")
    view.bag = K.Label(f, "", 170, -30, 150, "secondary")
    view.take = K.Button(f, "", 150, function()
        if C.active then C.Stop() else C.Start() end
        view:Render()
    end, "control")
    view.take:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -46)
    K.Tooltip(view.take, ns.T("collectTakeTitle"), ns.T("collectTakeTip"))
    view.disenchant = UI.DisenchantButton(f, 150)
    view.disenchant:SetPoint("TOPLEFT", f, "TOPLEFT", 170, -46)
    view.status = K.Label(f, "", 12, -74, 306, "secondary")
    f:SetScript("OnShow", function() view:Render() end)
    return view
end
function UI:Render()
    local mail = C.active and #C.MailTargets(C.budget or {}) or C.MailCount()
    local _, bag = C.NextDisenchant()
    self.mail:SetText(ns.T("collectMail", mail))
    self.bag:SetText(ns.T("collectBag", bag))
    if C.active then
        self.take:SetText(ns.T("collectStop", C.taken)); self.take:Enable()
    else
        self.take:SetText(ns.T("collectTake", mail))
        if mail > 0 then self.take:Enable() else self.take:Disable() end
    end
    UI.RenderDisenchant(self.disenchant)
    self.status:SetText(C.reason and ns.T(C.reason, C.taken) or "")
end
function UI.Refresh()
    local panel = UI.panel
    if panel and panel.frame:IsVisible() then panel:Render() end
    for _, b in ipairs(UI.buttons) do
        if b:IsVisible() and (not panel or b ~= panel.disenchant) then UI.RenderDisenchant(b) end
    end
end
C.onChange = UI.Refresh
local events = ns.NewFrame("Frame")
for _, event in ipairs({"MAIL_SHOW", "PLAYER_REGEN_ENABLED"}) do ns.Listen(events, event) end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and UI.waiting then
        local waiting = UI.waiting
        UI.waiting = nil
        for _, item in ipairs(waiting) do UI.Attach(item.parent, item.width, item.place) end
    end
    if event == "MAIL_SHOW" and not UI.panel and MailFrame and not InCombatLockdown() then
        UI.panel = UI:New(MailFrame)
    end
    UI.Refresh()
end)
