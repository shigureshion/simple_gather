Config = {}

Config.InteractKey = 38 -- Eキー
Config.InteractDistance = 0 -- 0なら円形エリア内のどこでも操作可能
Config.DefaultDuration = 5000 -- 採取時間（ミリ秒）
Config.DefaultCooldown = 0 -- 完了後の追加待機時間（秒）

-- 円形エリアのマーカー
Config.Marker = {
    enabled = true,
    type = 1,
    scale = { x = 1.0, y = 1.0, z = 0.3 },
    color = { r = 80, g = 200, b = 100, a = 100 }
}

-- 全採取地点で統一するBlip設定
Config.Blip = {
    enabled = true,
    sprite = 1,
    color = 2,
    scale = 0.7,
    shortRange = true,
    display = 4,
    category = 10,
    label = '採取ポイント'
}

Config.Zones = {
    {
        id = 'forest_wood',
        label = '木材採取',
        coords = vector3(-550.0, 5348.0, 74.7),
        radius = 15.0,

        item = 'rolling_paper',

        -- 固定個数
        amount = {
            mode = 'fixed',
            value = 1
        },

        duration = 5000,

        -- falseならマップに表示しない
        blip = true,

        -- アイテム別の採取モーション
        anim = {
            scenario = 'WORLD_HUMAN_HAMMERING',
            -- scenarioを使用する場合はdict/clip不要
        }
    },

    {
        id = 'mine_iron',
        label = '鉄鉱石採掘',
        coords = vector3(2950.0, 2787.0, 40.5),
        radius = 10.0,

        item = 'iron',

        -- ランダム個数
        amount = {
            mode = 'random',
            min = 1,
            max = 3
        },

        duration = 8000,
        blip = true,

        anim = {
            scenario = 'WORLD_HUMAN_CONST_DRILL'
        }
    },

    {
        id = 'illegal_gather',
        label = '違法物資採取',
        coords = vector3(1000.0, -3000.0, 5.0),
        radius = 8.0,

        item = 'weed_brick',

        amount = {
            mode = 'fixed',
            value = 1
        },

        duration = 6000,

        -- 違法物資の地点は非表示
        blip = false,

        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 1
        }
    }
}