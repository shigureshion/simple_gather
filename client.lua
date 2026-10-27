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
