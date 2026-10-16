local _, ns = ...
local B = {days = 7, all = {}}
B.__index = B
ns.MarketBoardUI = B
local function money(value)
    return ns.TradeKit.Money(value)
end
local function count(value)
    return tostring(math.floor(value + 0.5))
end
local function tiles(board)
    local C = ns.TradeKit.theme.chart
    local last, first, quote = board.last, board.first, board.quote
    local price = last and last.price or (quote and quote.price)
    local change, tone
    if first and last and first ~= last and first.price > 0 then
        local delta = (last.price / first.price - 1) * 100
        change, tone = ns.T("boardChange", delta, board.days), delta > 0.05 and "positive" or (delta < -0.05 and "negative" or nil)
    end
    local supply, supplyNote = board.supply, ns.T("boardSupplyMissing")
    if supply and board.supplyFirst and board.supplyFirst ~= supply and (board.supplyFirst.units or 0) > 0 then
        supplyNote = ns.T("boardSupplyChange", supply.lots or 0, ((supply.units or 0) / board.supplyFirst.units - 1) * 100)
    elseif supply then supplyNote = ns.T("boardSupplyLots", supply.lots or 0) end
    local flow = board.compared > 0
    return {
        {title = ns.T("boardPrice"), value = price and money(price) or ns.T("tradeNoPrice"), accent = C.minimum,
            note = change or ns.T("boardChangeMissing"), tone = tone, tip = ns.T("boardPriceTip")},
        {title = ns.T("boardMedian"), value = board.median and money(board.median) or ns.T("boardDash"), accent = C.median,
            note = ns.T("boardObservations", board.count), tip = board.low and ns.T("boardMedianTip", money(board.low), money(board.high))
            or ns.T("boardMedianEmpty")},
        {title = ns.T("boardVolatility"), value = board.volatility and ns.T("boardVolatilityValue", board.volatility) or ns.T("boardDash"),
            accent = C.late, note = ns.T("boardChanges", board.changes), tip = ns.T("boardVolatilityTip")},
        {title = ns.T("boardSupply"), value = supply and ns.T("boardUnits", supply.units or 0) or ns.T("boardDash"),
            accent = C.supply, note = supplyNote, tip = ns.T("boardSupplyTip")},
        {title = ns.T("boardEarly"), value = flow and ns.T("boardLots", board.early) or ns.T("boardDash"), accent = C.early,
            note = flow and ns.T("boardUnitsNote", board.earlyUnits) or ns.T("boardNoFlow"), tip = ns.T("boardEarlyTip")},
        {title = ns.T("boardLate"), value = flow and ns.T("boardLots", board.late) or ns.T("boardDash"), accent = C.late,
            note = flow and ns.T("boardLateNote", board.lateUnits, board.added) or ns.T("boardNoFlow"), tip = ns.T("boardLateTip")},
    }
end
local function tip(bucket)
    local C = ns.TradeKit.theme.chart
    local lines = {
        {ns.T("boardTipMinimum"), bucket.price and money(bucket.price) or ns.T("tradeNoPrice"), C.minimum},
        {ns.T("boardTipQuartile"), bucket.p25 and money(bucket.p25) or ns.T("tradeNoPrice"), C.quartile},
        {ns.T("boardTipSupply"), bucket.units and ns.T("boardTipSupplyValue", bucket.units, bucket.lots or 0) or ns.T("boardDash"), C.supply},
    }
    if bucket.compared > 0 then
        lines[#lines + 1] = {ns.T("boardTipAdded"), ns.T("boardTipFlowValue", bucket.added, bucket.addedUnits), C.added}
        lines[#lines + 1] = {ns.T("boardTipEarly"), ns.T("boardTipFlowValue", bucket.early, bucket.earlyUnits), C.early}
        lines[#lines + 1] = {ns.T("boardTipLate"), ns.T("boardTipFlowValue", bucket.late, bucket.lateUnits), C.late}
    else lines[#lines + 1] = {ns.T("boardTipNoFlow")} end
    if bucket.points > 1 then lines[#lines + 1] = {ns.T("boardTipScans", bucket.points)} end
    if bucket.shared then lines[#lines + 1] = {ns.T("boardTipShared")} end
    return date("%d.%m %H:%M", bucket.at), lines
end
function B:New(parent)
    local K = ns.TradeKit
    local view = setmetatable({tiles = {}, periods = {}}, self)
    local f = ns.NewFrame("Frame", nil, parent)
    view.frame = f
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -74)
    f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -12, 8)
    f:SetFrameLevel(parent:GetFrameLevel() + 3); f:EnableMouse(true)
    for i, days in ipairs({1, 7, 30}) do
        local button = K.Button(f, ns.T("familyDays", days), 64, function() B.days = days; view:Render() end, "quiet")
        button:SetPoint("TOPLEFT", f, "TOPLEFT", (i - 1) * 70, 0)
        view.periods[days] = button
    end
    view.coverage = K.Label(f, "", 222, -5, 300); view.coverage:SetHeight(14)
    view.coverage:SetTextColor(unpack(K.theme.secondary))
    view.help = K.Button(f, ns.T("tradeInfo"), 24, function() end, "quiet")
    view.help:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    K.Tooltip(view.help, ns.T("boardHelpTitle"), ns.T("boardHelp"))
    view.refresh = K.Button(f, ns.T("tradeUpdate"), 90, function()
        if view.props then ns.Markets.Scan(view.props.id) end
    end)
    view.refresh:SetPoint("RIGHT", view.help, "LEFT", -6, 0)
    K.Tooltip(view.refresh, ns.T("cacheRefreshItem"), ns.T("cacheRefreshTip"))
    for i = 1, 6 do view.tiles[i] = K.StatTile:New(f) end
    view.chart = K.TimeChart:New(f)
    view.chart.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -94)
    view.chart.frame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 18)
    view.status = K.Label(f, ns.T("tradeReadyShort"), 0, 0, 400)
    view.status:ClearAllPoints(); view.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0); view.status:SetHeight(14)
    f:SetScript("OnSizeChanged", function() if view.props then view:Layout() end end)
    B.all[#B.all + 1] = view
    return view
end
function B:SetProps(props)
    self.props = props; self.frame:Show(); self:Render()
end
function B:Layout()
    local width = self.frame:GetWidth() or 760
    local tile = math.floor((width - 5 * 8) / 6)
    for i, view in ipairs(self.tiles) do
        view.frame:ClearAllPoints()
        view.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (i - 1) * (tile + 8), -32)
        if view.props then view.props.width = tile; view:Render() end
    end
    self.coverage:SetWidth(math.max(60, width - 222 - 130))
    self.status:SetWidth(width)
end
function B:Controls()
    if ns.Scan.state.phase == "idle" and not ns.Buy.Active() and not (ns.vendorPrices and ns.vendorPrices[self.props.id]) then
        self.refresh:Enable()
    else self.refresh:Disable() end
end
function B:Render()
    if not self.props then return end
    local C = ns.TradeKit.theme.chart
    local board = ns.Activity.Board(self.props.id, B.days)
    for days, button in pairs(self.periods) do button:SetActive(days == B.days) end
    for i, props in ipairs(tiles(board)) do self.tiles[i].props = props end
    self:Layout()
    local last = board.points[#board.points]
    self.coverage:SetText(ns.T("boardCoverage", #board.points, board.compared,
        last and ns.T("boardAge", math.max(0, math.floor((time() - last.at) / 60))) or ns.T("boardDash")))
    self.chart:SetProps({from = board.from, to = board.to,
        empty = board.count < 2 and ns.T("familyNeedHistory") or nil,
        buckets = function(n) return ns.Activity.Buckets(board, n) end, tip = tip,
        tracks = {
            {kind = "steps", weight = 5, title = ns.T("boardTrackPrice"), format = money,
                median = board.median, medianLegend = ns.T("boardLegendMedian"),
                series = {{field = "p25", color = C.quartile, legend = ns.T("boardLegendQuartile"), thick = 1},
                    {field = "price", color = C.minimum, legend = ns.T("boardLegendMinimum"), area = true, dots = true}}},
            {kind = "bars", weight = 2, title = ns.T("boardTrackSupply"), format = count,
                series = {{field = "units", color = C.supply}}},
            {kind = "flow", weight = 3, title = ns.T("boardTrackFlow"), format = count,
                series = {{field = "addedUnits", color = C.added, legend = ns.T("boardLegendAdded")}},
                down = {{field = "earlyUnits", color = C.early, legend = ns.T("boardLegendEarly")},
                    {field = "lateUnits", color = C.late, legend = ns.T("boardLegendLate")}}},
        }})
    self:Controls()
end
function B.Status(text)
    for _, view in ipairs(B.all) do
        view.status:SetText(text)
        if view.props then view:Controls() end
    end
end
function B.Refresh()
    for _, view in ipairs(B.all) do
        if view.props and view.frame:IsVisible() then view:Render() end
    end
end
