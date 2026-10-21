local _, ns = ...
local B = {}
ns.Batch = B
function B.Cancel()
    B.job = nil
end
local function fresh(task)
    if #task.covered == 0 then return false end
    for _, id in ipairs(task.covered) do if not ns.Markets.Fresh(id) then return false end end
    return true
end
local function nextItem()
    local job = B.job
    while job and job.items[job.index] do
        local item = job.items[job.index]
        if not job.force and fresh(item) then
            job.used = job.used + #item.covered
            job.index = job.index + 1
        else
            if not ns.Scan.Start("pages", item.target) then B.Cancel(); return false end
            job.scanID = ns.Scan.state.scan.id
            return true
        end
    end
    if job then B.last = job end
    B.Cancel()
    return true
end
local function plan(sources, mode, skipUnknown)
    local force, missing = mode == true, mode == "missing"
    local items, seen = {}, {}
    local job = {items = items, index = 1, force = force, used = 0, vendor = 0, unknown = 0, missing = 0, stale = 0}
    local failed
    local function have(id)
        if force then return false end
        if missing then
            local q = ns.Markets.Quote(id)
            return q ~= nil and q.price ~= nil
        end
        return ns.Markets.Fresh(id)
    end
    local function addItem(id)
        if seen[id] then return end
        seen[id] = true
        if ns.vendorPrices and ns.vendorPrices[id] then job.vendor = job.vendor + 1; return end
        if have(id) then job.used = job.used + 1; return end
        local name = ns.Compat.ItemInfo(id)
        if not name then
            job.unknown = job.unknown + 1
            if not skipUnknown then failed = id end
            return
        end
        local quote = ns.Markets.Quote(id)
        if quote and quote.price then job.stale = job.stale + 1 else job.missing = job.missing + 1 end
        items[#items + 1] = {target = {itemID = id, query = name}, covered = {id}}
    end
    for _, source in ipairs(sources) do
        local family = type(source) == "table" and ns.gemByRaw[source.family]
        if family then
            local stale = 0
            for _, id in ipairs(family.members) do if not seen[id] and not have(id) then stale = stale + 1 end end
            local name = ns.Compat.ItemInfo(family.raw)
            if stale >= 2 and name then
                local covered = {}
                for _, id in ipairs(family.members) do
                    if not seen[id] then covered[#covered + 1] = id; seen[id] = true end
                end
                if #covered > 0 then items[#items + 1] = {target = {family = family.raw, query = name}, covered = covered} end
            else
                for _, id in ipairs(family.members) do addItem(id) end
            end
        elseif type(source) == "table" and source.target then
            items[#items + 1] = {target = source.target, covered = source.covered or {}}
        elseif type(source) == "number" then addItem(source) end
    end
    return job, failed
end
local function begin(sources, mode, skipUnknown)
    if not ns.Scan.Release() or ns.Buy.Active() then ns.say(ns.T("sayBusy")); return false end
    local job, failed = plan(sources, mode, skipUnknown)
    local items = job.items
    if failed then ns.say(ns.T("alchemyColdItem", ns.Markets.Name(failed))); return false end
    B.last = job
    ns.say(ns.T("cachePlan", #items, job.used, job.vendor, job.unknown))
    if #items == 0 then return true end
    B.job = job
    return nextItem()
end
function B.PreviewText(sources, skipUnknown)
    local job = plan(sources, false, skipUnknown)
    local skipped = plan(sources, "missing", skipUnknown)
    return ns.T("batchPreview", #job.items, job.missing, job.stale, job.used, job.vendor, job.unknown)
        .. "\n" .. ns.T("batchPreviewMissing", #skipped.items)
end
function B.Start(ids)
    return begin(ids, true)
end
function B.Complete(sources, force, skipUnknown)
    return begin(sources, force or false, skipUnknown)
end
function B.AllSources()
    local sources = {}
    local shown = ns.FamilyUI and ns.FamilyUI.expansions or {wrath = true}
    for _, family in ipairs(ns.gemFamilies) do
        if shown[family.expansion or "wrath"] and not ns.Hidden.Is(family.raw) then sources[#sources + 1] = {family = family.raw} end
    end
    for _, key in ipairs(ns.Crafting.order) do
        local catalog = ns.craftCatalogs[key]
        if catalog then
            for _, recipe in ipairs(ns.Hidden.Filter(catalog.recipes, false)) do
                for _, id in ipairs(ns.Crafting.Targets(recipe)) do sources[#sources + 1] = id end
            end
        end
    end
    if ns.Resale then
        for _, id in ipairs(ns.Resale.Targets()) do sources[#sources + 1] = id end
    end
    if ns.Leveling then
        for _, id in ipairs(ns.Leveling.Targets(nil, true)) do sources[#sources + 1] = id end
    end
    return sources
end
function B.All(force)
    return begin(B.AllSources(), force or false, true)
end
function B.Accept(scan)
    local job = B.job
    if not job or job.scanID ~= scan.id then return end
    if (scan.miss or 0) > 0 then job.failed = (job.failed or 0) + 1 end
    job.index = job.index + 1
    nextItem()
end
function B.Stop()
    if not B.job then return end
    B.Cancel()
    ns.Scan.Stop()
end
ns.Scan.onAbort = B.Cancel
