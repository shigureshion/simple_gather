local activeGathering = {}
local lastGather = {}

local function notify(src, message, notifyType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = '採取',
        description = message,
        type = notifyType or 'inform'
    })
end

local function getZoneById(zoneId)
    for _, zone in ipairs(Config.Zones) do
        if zone.id == zoneId then
            return zone
        end
    end
end

local function isPlayerInZone(src, zone)
    local ped = GetPlayerPed(src)

    if not ped or ped == 0 then
        return false
    end

    local coords = GetEntityCoords(ped)
    return #(coords - zone.coords) <= zone.radius
end

local function getAmount(zone)
    local amount = zone.amount

    if type(amount) ~= 'table' then
        return nil
    end

    if amount.mode == 'fixed' then
        local value = amount.value

        if type(value) ~= 'number'
            or value < 1
            or value % 1 ~= 0 then
            return nil
        end

        return value
    end

    if amount.mode == 'random' then
        local min = amount.min
        local max = amount.max

        if type(min) ~= 'number'
            or type(max) ~= 'number'
            or min < 1
            or max < min
            or min % 1 ~= 0
            or max % 1 ~= 0 then
            return nil
        end

        return math.random(min, max)
    end

    return nil
end

-- 採取開始
lib.callback.register(
    'simple_gather:server:begin',
    function(src, zoneId)
        if type(zoneId) ~= 'string' then
            return false
        end

        -- 既に採取中なら拒否
        if activeGathering[src] then
            return false
        end

        local zone = getZoneById(zoneId)

        if not zone then
            return false
        end

        if not isPlayerInZone(src, zone) then
            return false
        end

        -- アイテム・個数設定を事前検証
        if type(zone.item) ~= 'string'
            or zone.item == ''
            or not getAmount(zone) then
            print(('[simple_gather] Invalid zone config: %s')
                :format(zone.id))
            return false
        end

        local cooldown = zone.cooldown
            or Config.DefaultCooldown
        local now = GetGameTimer()
        local previous = lastGather[src]
            and lastGather[src][zone.id]

        if previous and now - previous < cooldown * 1000 then
            notify(src, 'まだ採取できません。', 'error')
            return false
        end

        local duration = zone.duration
            or Config.DefaultDuration

        if type(duration) ~= 'number'
            or duration < 1 then
            return false
        end

        activeGathering[src] = {
            zoneId = zone.id,
            startedAt = now,
            duration = duration
        }

        return true
    end
)

-- 採取完了
RegisterNetEvent('simple_gather:server:finish', function(zoneId)
    local src = source
    local gathering = activeGathering[src]

    if not gathering or gathering.zoneId ~= zoneId then
        return
    end

    local zone = getZoneById(zoneId)

    if not zone then
        activeGathering[src] = nil
        return
    end

    local elapsed = GetGameTimer() - gathering.startedAt

    -- プログレスバー相当の時間が経過しているか検証
    if elapsed < gathering.duration - 250 then
        activeGathering[src] = nil
        return
    end

    -- 完了時点でもエリア内であることを確認
    if not isPlayerInZone(src, zone) then
        activeGathering[src] = nil
        notify(src, '採取範囲から離れたため中断しました。', 'error')
        return
    end

    -- 完了イベントの二重実行を防止
    activeGathering[src] = nil

    local amount = getAmount(zone)

    if not amount then
        print(('[simple_gather] Invalid amount config: %s')
            :format(zone.id))
        return
    end

    local success, response = exports.ox_inventory:AddItem(
        src,
        zone.item,
        amount
    )

    if not success then
        notify(
            src,
            'アイテムを取得できませんでした。所持重量や空きスロットを確認してください。',
            'error'
        )
        return
    end

    lastGather[src] = lastGather[src] or {}
    lastGather[src][zone.id] = GetGameTimer()

    notify(
        src,
        ('%s x%d を入手しました。'):format(zone.label, amount),
        'success'
    )
end)

-- 採取キャンセル
RegisterNetEvent('simple_gather:server:cancel', function(zoneId)
    local src = source
    local gathering = activeGathering[src]

    if gathering and gathering.zoneId == zoneId then
        activeGathering[src] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source

    activeGathering[src] = nil
    lastGather[src] = nil
end)
