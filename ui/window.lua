local _, ns = ...
local W = {lists = {}}
ns.AuctionWindow = W
local layouts = {
    {kind = "list", parent = "AuctionFrameBrowse", prefix = "BrowseButton", template = "BrowseButtonTemplate",
        scroll = "BrowseScrollFrame", update = "AuctionFrameBrowse_Update", original = 8, x = 195, y = 110,
        width = 625, sort = "BrowseQualitySort", sortWidth = 214},
    {kind = "bidder", parent = "AuctionFrameBid", prefix = "BidButton", template = "BidButtonTemplate",
        scroll = "BidScrollFrame", update = "AuctionFrameBid_Update", original = 9, x = 27, y = 76,
        width = 793, sort = "BidQualitySort", sortWidth = 195},
    {kind = "owner", parent = "AuctionFrameAuctions", prefix = "AuctionsButton", template = "AuctionsButtonTemplate",
        scroll = "AuctionsScrollFrame", update = "AuctionFrameAuctions_Update", original = 9, x = 219, y = 76,
        width = 599, sort = "AuctionsQualitySort", sortWidth = 185},
}
local function combat()
    return InCombatLockdown and InCombatLockdown() or false
end
local function region(row, suffix)
    return _G[row:GetName() .. suffix]
end
local function shift(frame, x, y)
    if not frame then return end
    local point, relative, anchor, left, top = frame:GetPoint(1)
    if point then frame:ClearAllPoints(); frame:SetPoint(point, relative, anchor, left + x, top + y) end
end
local function paint(list, row, index, delta)
    local name, icon, count, quality, usable, level, minBid, increment, buyout, bid, high, owner, sold = GetAuctionItemInfo(list.kind, index)
    if not name or not count or not minBid or not increment or buyout == nil or bid == nil then row:Hide(); return end
    row:Show()
    local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]
    local label, texture, stack = region(row, "Name"), region(row, "ItemIconTexture"), region(row, "ItemCount")
    label:SetText(name); label:SetTextColor(color.r, color.g, color.b)
    texture:SetTexture(icon); texture:SetVertexColor(1, usable and 1 or 0.1, usable and 1 or 0.1)
    stack:SetText(count > 1 and tostring(count) or ""); if count > 1 then stack:Show() else stack:Hide() end
    local duration = GetAuctionItemTimeLeft(list.kind, index)
    local closing = region(row, "ClosingTime")
    region(row, "ClosingTimeText"):SetText(AuctionFrame_GetTimeLeftText(duration))
    closing.tooltip = AuctionFrame_GetTimeLeftTooltipText(duration)
    local levelText = region(row, "Level")
    if levelText then levelText:SetText(level); levelText:SetTextColor(level > UnitLevel("player") and 1 or 1,
        level > UnitLevel("player") and 0.1 or 1, level > UnitLevel("player") and 0.1 or 1) end
    local amount = bid > 0 and bid or minBid
    row.bidAmount, row.buyoutPrice, row.itemCount = amount, buyout, count
    if list.kind == "bidder" then
        region(row, "BidStatus"):SetText(high and HIGH_BIDDER or OUTBID)
        region(row, "BidStatus"):SetTextColor(high and 0.4 or 1, high and 1 or 0.2, 0.2)
        MoneyFrame_Update(row:GetName() .. "CurrentBidMoneyFrame", amount)
        MoneyFrame_Update(row:GetName() .. "BuyoutMoneyFrame", buyout)
    else
        region(row, "HighBidder"):SetText(list.kind == "list" and (owner or "") or (high or NO_BIDS))
        local money, frame = region(row, "MoneyFrame"), region(row, "BuyoutFrame")
        MoneyFrame_Update(money:GetName(), amount)
        money:SetAlpha(list.kind == "owner" and bid == 0 and 0.5 or 1)
        money:ClearAllPoints(); money:SetPoint("RIGHT", row, "RIGHT", 10, buyout > 0 and 10 or 3)
        if buyout > 0 then MoneyFrame_Update(row:GetName() .. "BuyoutFrameMoney", buyout); frame:Show()
        else frame:Hide() end
        if list.kind == "list" then
            if high then region(row, "YourBidText"):Show() else region(row, "YourBidText"):Hide() end
        else
            region(row, "MoneyFrameLabel"):Hide()
            row.cancelPrice = math.floor(bid * 0.05)
            if sold == 1 then
                label:SetFormattedText(AUCTION_ITEM_SOLD, name); label:SetTextColor(0.5, 0.5, 0.5)
                texture:SetVertexColor(0.5, 0.5, 0.5); stack:Hide()
                region(row, "ClosingTimeText"):SetFormattedText(AUCTION_ITEM_TIME_UNTIL_DELIVERY, SecondsToTime(duration))
                closing.tooltip = region(row, "ClosingTimeText"):GetText()
                MoneyFrame_Update(money:GetName(), bid); money:SetAlpha(1)
                money:SetPoint("RIGHT", row, "RIGHT", 10, -4)
                region(row, "MoneyFrameLabel"):Show(); frame:Hide()
            end
        end
    end
    if GetSelectedAuctionItem(list.kind) == index then
        row:LockHighlight()
        if list.kind ~= "owner" then
            local prefix = list.kind == "list" and "Browse" or "Bid"
            local required = list.kind == "list" and (bid == 0 and minBid or bid + increment) or amount + increment
            MoneyInputFrame_SetCopper(_G[prefix .. "BidPrice"], required)
            if not high and owner ~= UnitName("player") and required <= (MAXIMUM_BID_PRICE or 2000000000)
                and GetMoney() >= required then _G[prefix .. "BidButton"]:Enable() end
            if buyout > 0 and buyout >= minBid and owner ~= UnitName("player")
                and GetMoney() + (high and bid or 0) >= buyout then
                _G[prefix .. "BuyoutButton"]:Enable()
                if AuctionFrame.type == list.kind or list.frame:IsShown() then AuctionFrame.buyoutPrice = buyout end
            end
        end
    else row:UnlockHighlight() end
    row:SetWidth(list.width + delta)
    region(row, "Highlight"):SetWidth(list.width + delta - 36)
    local size = list.kind == "bidder" and 187 or (list.kind == "owner" and 142 or 167)
    label:SetWidth(size + delta)
end
function W.Paint(list)
    if list.painting then return end
    list.painting = true
    if list.kind ~= "owner" then
        local prefix = list.kind == "list" and "Browse" or "Bid"
        _G[prefix .. "BidButton"]:Disable(); _G[prefix .. "BuyoutButton"]:Disable()
        if AuctionFrame.type == list.kind or list.frame:IsShown() then AuctionFrame.buyoutPrice = nil end
    end
    local count, total = GetNumAuctionItems(list.kind)
    local visible = math.max(list.original, math.min(#list.rows, math.floor((W.frame:GetHeight() - list.y - 40) / 37)))
    local maximum = math.max(0, count + (total > 50 and 1 or 0) - visible)
    local offset = math.min(maximum, FauxScrollFrame_GetOffset(list.scroll))
    list.scroll.offset = offset
    FauxScrollFrame_Update(list.scroll, count + (total > 50 and 1 or 0), visible, 37)
    local delta = W.frame:GetWidth() - 832
    for i, row in ipairs(list.rows) do
        if i <= visible and offset + i <= count then paint(list, row, offset + i, delta)
        else row:Hide() end
    end
    local prefix = list.kind == "list" and "Browse" or (list.kind == "bidder" and "Bid" or "Auctions")
    local text = _G[prefix .. "SearchCountText"]
    if text and total > 50 and offset + visible > count then
        if list.kind == "list" then
            local first = (list.frame.page or 0) * 50 + 1
            text:SetFormattedText(NUMBER_OF_RESULTS_TEMPLATE, first, first + count - 1, total)
        else text:SetFormattedText(SINGLE_PAGE_RESULTS_TEMPLATE, total) end
        text:Show()
    elseif text then text:Hide() end
    if list.kind == "owner" then
        local selected = GetSelectedAuctionItem("owner")
        if selected and selected > 0 and CanCancelAuction(selected) then AuctionsCancelAuctionButton:Enable()
        else AuctionsCancelAuctionButton:Disable() end
    end
    list.visible = visible
    list.painting = false
end
local function installList(config)
    local parent, scroll, first = _G[config.parent], _G[config.scroll], _G[config.prefix .. "1"]
    if not parent or not scroll or not first or not _G[config.update] then return end
    local list = {}
    for key, value in pairs(config) do list[key] = value end
    list.frame, list.scroll, list.rows, list.fields = parent, scroll, {}, {}
    for i = 1, 40 do
        local row = i <= list.original and _G[list.prefix .. i]
            or ns.NewFrame("Button", "ManaCodeAuction" .. list.kind .. i, parent, list.template)
        row:SetID(i)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", parent, "TOPLEFT", list.x, -list.y - (i - 1) * 37)
        for _, suffix in ipairs({"Level", "HighBidder", "ClosingTime", "BidStatus"}) do
            local field = region(row, suffix)
            if field then
                local point, relative, anchor, x, y = field:GetPoint(1)
                if point then list.fields[#list.fields + 1] = {frame = field, point = point, relative = relative, anchor = anchor, x = x, y = y} end
            end
        end
        list.rows[i] = row
    end
    W.lists[#W.lists + 1] = list
    hooksecurefunc(config.update, function() W.Paint(list) end)
end
function W.Layout()
    if W.layingOut then return end
    W.layingOut = true
    local width, height = W.frame:GetWidth(), W.frame:GetHeight()
    local dx, dy = width - 832, height - 447
    for _, name in ipairs({"AuctionFrameBrowse", "AuctionFrameBid", "AuctionFrameAuctions"}) do
        local frame = _G[name]
        if frame then frame:SetWidth(758 + dx); frame:SetHeight(447 + dy) end
    end
    ns.TradeKit.LayoutAuctionArt(W.frame, width, height, W.art)
    for _, list in ipairs(W.lists) do
        list.scroll:SetHeight((list.kind == "list" and 306 or 339) + dy)
        local sort = _G[list.sort]
        if sort then sort:SetWidth(list.sortWidth + dx) end
        for _, field in ipairs(list.fields) do
            field.frame:ClearAllPoints(); field.frame:SetPoint(field.point, field.relative, field.anchor, field.x + dx, field.y)
        end
        W.Paint(list)
    end
    if ns.Trader.frame then ns.Trader.Refresh() end
    W.layingOut = false
end
function W.Save()
    if not W.frame then return end
    W.frame:StopMovingOrSizing()
    ns.Store.DB().auctionWindow = {width = W.frame:GetWidth(), height = W.frame:GetHeight()}
end
function W.SetSize(width, height)
    if combat() then ns.say(ns.T("windowCombat")); return false end
    W.frame:SetWidth(math.max(832, math.min(width, W.maxWidth)))
    W.frame:SetHeight(math.max(447, math.min(height, W.maxHeight)))
    W.Layout(); W.Save()
    return true
end
function W.Install(frame)
    if W.frame then return end
    W.frame = frame
    W.art = ns.TradeKit.AuctionArt(frame)
    W.maxWidth = math.max(832, math.min(1600, (UIParent and UIParent:GetWidth() or 1920) - 35))
    W.maxHeight = math.max(447, math.min(1100, (UIParent and UIParent:GetHeight() or 1080) - 130))
    frame:SetResizable(true); frame:SetMinResize(832, 447); frame:SetMaxResize(W.maxWidth, W.maxHeight)
    for _, config in ipairs(layouts) do installList(config) end
    W.grip = ns.TradeKit.ResizeGrip(frame, function()
        if not combat() then frame:StartSizing("BOTTOMRIGHT") end
    end, W.Save)
    W.reset = ns.TradeKit.Button(frame, ns.T("windowDefault"), 62, function() W.SetSize(1040, 630) end)
    W.reset:SetPoint("TOPLEFT", frame, "TOPLEFT", 75, -12)
    ns.TradeKit.Tooltip(W.reset, ns.T("windowDefault"), ns.T("windowDefaultTip"))
    frame:HookScript("OnSizeChanged", W.Layout)
    hooksecurefunc("AuctionFrameTab_OnClick", W.Layout)
    local saved = ns.Store.DB().auctionWindow or {width = 1040, height = 630}
    W.SetSize(saved.width, saved.height)
end
