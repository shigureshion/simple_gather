local activeZone = nil
local isGathering = false
local textUIVisible = false

local function showText(zone)
    if textUIVisible then return end

    lib.showTextUI(('[E] %s'):format(zone.label), {
        position = 'left-center',
        icon = 'hand'
    })

    textUIVisible = true
end

local function hideText()
    if not textUIVisible then return end

    lib.hideTextUI()
    textUIVisible = false
end

local function isInsideZone(zone)
    local coords = GetEntityCoords(PlayerPedId())
    return #(coords - zone.coords) <= zone.radius
end

-- Blip作成
local createdBlips = {}

-- 採取開始前の近距離オブジェクトを記録
local function snapshotNearbyObjects(ped, radius)
    local snapshot = {}
    local coords = GetEntityCoords(ped)

    for _, object in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(object) then
            local objectCoords = GetEntityCoords(object)

            if #(objectCoords - coords) <= radius then
                snapshot[object] = true
            end
        end
    end

    return snapshot
end

-- 採取中に新しく生成された近距離オブジェクトを削除
local function cleanupNewNearbyObjects(snapshot, radius)
    local ped = PlayerPedId()

    -- 先にモーションを停止する
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)

    -- アタッチ解除やシナリオの終了処理を待つ
    Wait(100)

    local coords = GetEntityCoords(ped)

    for _, object in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(object) and not snapshot[object] then
            local objectCoords = GetEntityCoords(object)

            if #(objectCoords - coords) <= radius then
                -- ネットワークオブジェクトは制御権がある場合のみ削除
                if not NetworkGetEntityIsNetworked(object)
                    or NetworkHasControlOfEntity(object) then

                    SetEntityAsMissionEntity(object, true, true)

                    if IsEntityAttachedToEntity(object, ped) then
                        DetachEntity(object, true, true)
                    end

                    DeleteEntity(object)
                end
            end
        end
    end
end

CreateThread(function()
    if not Config.Blip.enabled then return end

    for _, zone in ipairs(Config.Zones) do
        if zone.blip then
            local blip = AddBlipForCoord(
                zone.coords.x,
                zone.coords.y,
                zone.coords.z
            )

            SetBlipSprite(blip, Config.Blip.sprite)
            SetBlipColour(blip, Config.Blip.color)
            SetBlipScale(blip, Config.Blip.scale)
            SetBlipDisplay(blip, Config.Blip.display)
            SetBlipAsShortRange(blip, Config.Blip.shortRange)

            -- 凡例上のカテゴリを統一
            SetBlipCategory(blip, Config.Blip.category)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(Config.Blip.label)
            EndTextCommandSetBlipName(blip)

            createdBlips[#createdBlips + 1] = blip
        end
    end
end)

-- 採取エリア判定とマーカー表示
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        activeZone = nil

        for _, zone in ipairs(Config.Zones) do
            local distance = #(coords - zone.coords)

            if distance <= zone.radius then
                activeZone = zone
                break
            end
        end

        if activeZone then
            sleep = 0

            if Config.Marker.enabled then
                DrawMarker(
                    Config.Marker.type,
                    activeZone.coords.x,
                    activeZone.coords.y,
                    activeZone.coords.z - 0.9,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    activeZone.radius * 2.0,
                    activeZone.radius * 2.0,
                    Config.Marker.scale.z,
                    Config.Marker.color.r,
                    Config.Marker.color.g,
                    Config.Marker.color.b,
                    Config.Marker.color.a,
                    false, false, 2, false,
                    nil, nil, false
                )
            end

            showText(activeZone)

            if IsControlJustReleased(0, Config.InteractKey)
                and not isGathering then

                isGathering = true

                local zone = activeZone

                CreateThread(function()
                    -- サーバー側で採取開始条件を検証
                    local allowed = lib.callback.await(
                        'simple_gather:server:begin',
                        false,
                        zone.id
                    )

                    if not allowed then
                        isGathering = false
                        return
                    end

                    local completed = false

                    -- 採取開始前のオブジェクトを記録
                    local propSnapshot = snapshotNearbyObjects(PlayerPedId(), 4.0)

                    -- プログレスバーとモーション
                    local success = lib.progressBar({
                        duration = zone.duration
                            or Config.DefaultDuration,
                        label = zone.label,
                        useWhileDead = false,
                        allowRagdoll = false,
                        allowSwimming = false,
                        canCancel = true,

                        anim = zone.anim,

                        disable = {
                            move = true,
                            sprint = true,
                            car = true,
                            combat = true
                        }
                    })

                    -- 採取中に新しく生成されたpropを整理
                    cleanupNewNearbyObjects(propSnapshot, 3.0)

                    -- キャンセル・完了どちらもサーバーに通知
                    if success and isInsideZone(zone) then
                        TriggerServerEvent(
                            'simple_gather:server:finish',
                            zone.id
                        )
                        completed = true
                    else
                        TriggerServerEvent(
                            'simple_gather:server:cancel',
                            zone.id
                        )
                    end

                    isGathering = false
                end)
            end
        else
            hideText()
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    hideText()

    for _, blip in ipairs(createdBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)
