# Simple Gather for Qbox

Qbox 環境向けの、設定ファイルで管理できるシンプルな採取システムです。

採取エリア・対象アイテム・取得個数・採取時間・採取モーション・マップ上の Blip を設定することで、プレイヤーが指定されたエリア内で採取を行えるようにします。

FiveM の RP サーバーでの利用を想定しており、木材、鉱石、植物、その他のアイテム採取など、さまざまな用途に対応します。

## Features

- **設定ファイルによる採取エリア管理**
  - 複数の採取エリアを登録可能
  - エリアごとに座標と採取可能範囲を設定
  - 円形エリア内であれば、中心地点に近づかなくても採取可能
- **プログレスバーによる採取**
  - `ox_lib` のプログレスバーを使用
  - 採取時間をエリアごとに設定可能
  - 採取中の移動・戦闘などを制限
  - 採取中の多重実行を防止
- **採取モーションの設定**
  - エリアごとにシナリオまたはアニメーションを指定可能
  - 採取内容に応じたモーションを設定可能
- **取得個数の設定**
  - 固定個数
  - 指定範囲内のランダム個数
- **マップ Blip の設定**
  - エリアごとに表示・非表示を指定可能
  - 表示する Blip の外観を共通設定で統一
  - 違法アイテムなど、マップに表示したくない採取地点を非表示に設定可能
- **サーバー側の検証**
  - 採取地点への距離を検証
  - 採取開始と完了を分離して管理
  - 採取時間の経過を検証
  - 取得アイテムの付与をサーバー側で処理
- **ox_inventory 対応**
  - アイテムの追加に失敗した場合はエラー通知を表示

## Requirements

以下のリソースが必要です。

| Resource | Purpose |
|---|---|
| `qbx_core` | Qbox サーバー環境 |
| `ox_lib` | プログレスバー、通知、コールバック |
| `ox_inventory` | アイテムの付与 |

Qbox の通常の起動構成に加え、`ox_lib` と `ox_inventory` が正常に動作している必要があります。

## Installation

### 1. Resource の配置

このリポジトリをダウンロードし、サーバーのリソースフォルダに配置します。

```text
resources/
└── [local]/
    └── simple_gather/
        ├── fxmanifest.lua
        ├── config.lua
        ├── client.lua
        ├── server.lua
        └── README.md
```

### 2. server.cfg の設定

依存リソースより後に `simple_gather` を起動してください。

```cfg
ensure ox_lib
ensure qbx_core
ensure ox_inventory

ensure simple_gather
```

すでに起動設定が存在する場合は、既存の構成と起動順を維持してください。

### 3. アイテムの確認

`config.lua` で指定するアイテム名は、`ox_inventory` に登録されている内部名と一致させてください。

例：

```lua
item = 'wood'
```

上記は設定例です。実際のアイテム名はサーバーのアイテム定義に合わせて変更してください。

## Configuration

設定は `config.lua` で行います。

### Global Settings

```lua
Config = {}

Config.InteractKey = 38
Config.InteractDistance = 0
Config.DefaultDuration = 5000
Config.DefaultCooldown = 0
```

| Setting | Type | Description |
|---|---|---|
| `Config.InteractKey` | Number | 採取操作に使用するコントロール ID。`38` は E キー |
| `Config.InteractDistance` | Number | 操作距離の設定値。`0` は円形採取エリア内のどこでも操作可能とする意図の設定 |
| `Config.DefaultDuration` | Number | 採取時間のデフォルト値（ミリ秒） |
| `Config.DefaultCooldown` | Number | 採取完了後の追加待機時間（秒） |

**Note:** `InteractDistance` は、現在の実装では採取可能範囲そのものを制限する設定ではありません。採取可能範囲は各エリアの `radius` で決まります。

### Marker Settings

```lua
Config.Marker = {
    enabled = true,
    type = 1,
    scale = {
        x = 1.0,
        y = 1.0,
        z = 0.3
    },
    color = {
        r = 80,
        g = 200,
        b = 100,
        a = 100
    }
}
```

| Setting | Description |
|---|---|
| `enabled` | マーカーの表示・非表示 |
| `type` | GTA V のマーカータイプ |
| `scale` | マーカーの大きさ |
| `color.r` | 赤成分（0～255） |
| `color.g` | 緑成分（0～255） |
| `color.b` | 青成分（0～255） |
| `color.a` | 透明度（0～255） |

円形マーカーの表示サイズと、採取可能範囲は別の設定です。採取可能範囲は `radius` で指定します。

### Blip Settings

```lua
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
```

| Setting | Description |
|---|---|
| `enabled` | 採取地点の Blip 機能を全体で有効・無効にする |
| `sprite` | Blip のアイコン ID |
| `color` | Blip の色 ID |
| `scale` | Blip の縮尺 |
| `shortRange` | 近距離表示の有効・無効 |
| `display` | Blip の表示方法 |
| `category` | Blip のカテゴリ |
| `label` | すべての採取地点で共通の表示名 |

すべての採取地点で共通のアイコン・色・縮尺・表示名を使用します。

各採取エリアの `blip` を `true` にすると表示し、`false` にすると表示しません。

```lua
blip = true
```

```lua
blip = false
```

`Config.Blip.enabled = false` にすると、すべての採取地点の Blip が非表示になります。

**Important:** Blip のカテゴリを統一しても、複数の Blip が内部的に単一の Blip へ統合されるわけではありません。表示対象の採取地点ごとに Blip が作成されます。不要な Blip を増やさないよう、必要な地点だけを表示してください。

### Zone Settings

採取地点は `Config.Zones` に登録します。

```lua
Config.Zones = {
    {
        id = 'forest_wood',
        label = '木材採取',

        coords = vector3(-550.0, 5348.0, 74.7),
        radius = 15.0,

        item = 'wood',

        amount = {
            mode = 'fixed',
            value = 1
        },

        duration = 5000,

        blip = true,

        anim = {
            scenario = 'WORLD_HUMAN_HAMMERING'
        }
    }
}
```

| Setting | Type | Description |
|---|---|---|
| `id` | String | 採取地点の一意な識別子 |
| `label` | String | プレイヤー向けの採取名称 |
| `coords` | Vector3 | 採取エリアの中心座標 |
| `radius` | Number | 採取可能範囲の半径（メートル） |
| `item` | String | 取得するアイテムの内部名 |
| `amount` | Table | 取得個数の設定 |
| `duration` | Number | 採取時間（ミリ秒） |
| `blip` | Boolean | 当該地点の Blip 表示設定 |
| `anim` | Table | 採取モーションの設定 |
| `cooldown` | Number | 当該地点の追加待機時間（秒） |

`id` は各採取地点で重複しない値を使用してください。

`duration` を省略した場合は `Config.DefaultDuration` が使用されます。`cooldown` を省略した場合は `Config.DefaultCooldown` が使用されます。

## Item Amount

取得個数は `amount.mode` で指定します。

### Fixed Amount

常に指定した個数を取得します。

```lua
amount = {
    mode = 'fixed',
    value = 1
}
```

この場合、採取完了時に必ず 1 個を取得します。

3 個固定にしたい場合は次のように設定します。

```lua
amount = {
    mode = 'fixed',
    value = 3
}
```

### Random Amount

指定した最小値と最大値の範囲で、取得個数をランダムに決定します。

```lua
amount = {
    mode = 'random',
    min = 1,
    max = 3
}
```

この場合、1～3 個のいずれかを取得します。

最小値と最大値が同じ場合も設定可能です。

```lua
amount = {
    mode = 'random',
    min = 1,
    max = 1
}
```

ただし、個数が常に同じであることを明示したい場合は `fixed` を推奨します。

## Gathering Animation

採取モーションは採取地点ごとに指定します。

### Scenario

GTA V のシナリオを使用する方法です。

```lua
anim = {
    scenario = 'WORLD_HUMAN_HAMMERING'
}
```

### Animation Dictionary and Clip

アニメーション辞書とクリップを指定する方法です。

```lua
anim = {
    dict = 'amb@world_human_gardener_plant@male@base',
    clip = 'base',
    flag = 1
}
```

| Setting | Description |
|---|---|
| `scenario` | シナリオ名 |
| `dict` | アニメーション辞書 |
| `clip` | アニメーションクリップ |
| `flag` | アニメーション再生フラグ |

`scenario` と `dict` / `clip` は、原則としてどちらか一方を指定してください。

使用するモーションがゲーム内で再生可能かどうかは、サーバー環境で確認してください。

## Example: Multiple Gathering Zones

```lua
Config.Zones = {
    {
        id = 'forest_wood',
        label = '木材採取',
        coords = vector3(-550.0, 5348.0, 74.7),
        radius = 15.0,
        item = 'wood',

        amount = {
            mode = 'fixed',
            value = 1
        },

        duration = 5000,
        blip = true,

        anim = {
            scenario = 'WORLD_HUMAN_HAMMERING'
        }
    },

    {
        id = 'mine_iron',
        label = '鉄鉱石採掘',
        coords = vector3(2950.0, 2787.0, 40.5),
        radius = 10.0,
        item = 'ironore',

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
        item = 'illegal_item',

        amount = {
            mode = 'fixed',
            value = 1
        },

        duration = 6000,
        blip = false,

        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 1
        }
    }
}
```

上記の座標・アイテム名・モーションは説明用のサンプルです。実際のサーバーに合わせて変更してください。

## How It Works

1. プレイヤーが採取エリアに入ると、設定に応じてマーカーと操作案内が表示されます。
2. プレイヤーが E キーを押すと、サーバーに採取開始リクエストが送信されます。
3. サーバーが採取地点とプレイヤーの距離などを検証します。
4. 採取が許可されると、プログレスバーと採取モーションが開始されます。
5. 採取が完了すると、クライアントからサーバーに完了リクエストが送信されます。
6. サーバーが経過時間と採取地点を再検証し、`ox_inventory` でアイテムを付与します。
7. アイテムの付与結果に応じて通知が表示されます。

採取をキャンセルした場合は、アイテムは付与されません。

## Troubleshooting

### アイテムが取得できない

以下を確認してください。

- `item` が `ox_inventory` のアイテム定義と一致しているか。
- 所持重量や空きスロットに余裕があるか。
- サーバーコンソールにエラーが出ていないか。
- 採取時間の経過前に完了処理が実行されていないか。

### マーカーが表示されない

- `Config.Marker.enabled` が `true` になっているか。
- 採取地点の座標が正しいか。
- マーカーが地面に埋まっていないか。

### Blip が表示されない

- `Config.Blip.enabled` が `true` になっているか。
- 採取地点の `blip` が `true` になっているか。
- Blip の座標が正しいか。

### 採取モーションが再生されない

- シナリオ名が正しいか。
- アニメーション辞書とクリップの組み合わせが有効か。
- `anim` の設定形式が正しいか。

## Limitations

- このリソースはシンプルな採取機能を提供するもので、採取地点の生成やアイテム定義の登録は行いません。
- 採取範囲は円形です。
- Blip は地点ごとに作成されます。Blip の統一は外観とカテゴリに関するもので、内部的な統合を意味しません。
- 採取中の検証はサーバー側で行いますが、より厳格な不正対策が必要な大規模サーバーでは、採取セッション管理や同時リクエスト制御などの追加対策を検討してください。
- 座標、アイテム名、モーション名は各サーバー環境に合わせて設定する必要があります。

## Disclaimer

本スクリプトは、個人利用を目的として作成したものであり、第三者へのサポートや動作保証を目的としたものではありません。

本スクリプトの導入・使用・改変・再配布、および本スクリプトと他のリソース、プラグイン、スクリプト等との併用によって発生した不具合、データの損失、サーバーの障害、その他一切の損害について、作成者は責任を負いません。

本スクリプトは現状有姿で提供されます。動作の保証、継続的な保守、アップデート、不具合の修正、特定の環境への対応は行いません。

また、本スクリプトに関する質問、問い合わせ、修正依頼、機能追加の要望、その他一切のサポート依頼は受け付けておりません。

本スクリプトを導入・使用・改変・再配布する場合は、利用者自身の責任において行ってください。

本スクリプトを利用した時点で、上記の注意事項を理解し、了承したものとします。

なお、本注意事項は、適用される法令により免責が認められない場合にまで、作成者の責任を免除するものではありません。
