local ADDON, ns = ...
local Store = {}
ns.Store = Store
local VERSION = 1
local MAX_LOG = 60
local STORAGE_NOTICE = 400 * 1024 * 1024
function Store.DB()
    local db = AuctionScanDB
    if type(db) ~= "table" or db.v ~= VERSION then
        db = { v = VERSION }
        AuctionScanDB = db
    end
    db.maxScans = 0
    db.seq = db.seq or 0
    db.scans = db.scans or {}
    db.items = db.items or {}
    db.log = db.log or {}
    return db
end
local function scanBytes(scan)
    local bytes = 512
    for _, text in ipairs(scan.lots) do bytes = bytes + #text + 24 end
    for _ in pairs(scan.disenchantItems or {}) do bytes = bytes + 120 end
    return bytes
end
function Store.Usage()
    local db = Store.DB()
    if db.scanBytesCount ~= #db.scans then
        db.scanBytes = 0
        for _, scan in ipairs(db.scans) do db.scanBytes = db.scanBytes + scanBytes(scan) end
        db.scanBytesCount = #db.scans
    end
    return db.scanBytes or 0
end
function Store.Begin(mode)
    local db = Store.DB()
    db.seq = db.seq + 1
    local t = time()
    local realm, faction = GetRealmName() or "", UnitFactionGroup("player") or ""
    return {
        id = realm .. "|" .. faction .. "|" .. t .. "|" .. db.seq,
        t = t,
        realm = realm,
        faction = faction,
        mode = mode,
        total = 0,
        secs = 0,
        lots = {},
    }
end
function Store.Item(id, name, quality)
    local items = Store.DB().items
    if not items[id] and name then
        items[id] = name .. "\t" .. tostring(quality or 0)
        Store.itemsVersion = (Store.itemsVersion or 0) + 1
    end
end
function Store.Log(text)
    local log = Store.DB().log
    log[#log + 1] = date("%d.%m %H:%M:%S") .. " " .. text
    while #log > MAX_LOG do table.remove(log, 1) end
end
function Store.Commit(scan)
    local db = Store.DB()
    local bytes = Store.Usage()
    if ns.Markets then ns.Markets.Remember(scan) end
    if ns.Family then ns.Family.Record(scan) end
    local scans = db.scans
    scans[#scans + 1] = scan
    db.scanBytes, db.scanBytesCount = bytes + scanBytes(scan), #scans
    if db.scanBytes >= STORAGE_NOTICE and not db.storageNotice then
        db.storageNotice = true
        ns.say(ns.T("storageNotice", db.scanBytes / 1024 / 1024))
    end
    return 0
end
