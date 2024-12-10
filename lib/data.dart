import 'libs/installer.dart';

final List<DownloadableAsset> requiredAssets = [
  DownloadableAsset(
    url: Uri.parse("https://r2.chikach.net/dqm-assets/steve.png"),
    size: 1284,
    md5: "0F7506E16BC479E7393D9CEDF3E42B11",
  ),
  DownloadableAsset(
    url: Uri.parse(
        "https://r2.chikach.net/dqm-assets/deobfuscation_data_1.5.2.zip"),
    size: 201404,
    md5: "270D9775872CC9FA773389812CAB91FE",
  ),
  DownloadableAsset(
    url: Uri.parse("https://r2.chikach.net/dqm-assets/fml_libs15.zip"),
    size: 10545276,
    md5: "FA7C893F7F9C96F6AEB29B94E261722F",
  ),
  DownloadableAsset(
    url: Uri.parse("https://r2.chikach.net/dqm-assets/resources.zip"),
    size: 46833816,
    md5: "8D2B3420D2CC65518E40E9A93E84EAFB",
  ),
];

final List<AdditionalMod> additionalMods = [
  AdditionalMod(
    "Skin Fixer",
    "ランチャーでアップロードしたスキンをゲーム内に反映させます。"
        "これを導入しなかった場合には、上で指定したスキンが使用されます。"
        "スリムスキンは腕に黒帯が発生します。",
    mod: DownloadableAsset(
      url: Uri.parse("https://mediafilez.forgecdn.net/files/2571/89/skin-fixer-1.5.2-1.0.1.jar"),
      size: 196880,
      md5: "EB9D650CA8DCFF99F02F108E319F579A",
    ),
  ),
  AdditionalMod(
      "ChickenChunks",
      "チャンク読み込みMOD。これを使うと、別ディメンションにいるときでも薬草などが育ちます。\n"
          "チャンクローダーをクラフトする必要があります。クラフト方法はCraftGuideで調べてください。",
      mod: DownloadableAsset(
        url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/ChickenChunks 1.3.2.14.jar"),
        size: 93761,
        md5: "9A613B4B5FD287E4CE4F20875F72EC04",
      ),
      coreMod: DownloadableAsset(
        url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/CodeChickenCore 0.8.7.3-fix1.jar"),
        size: 322443,
        md5: "CD266D0E4DF718146D16940255C28997",
      )),
  AdditionalMod(
      "CraftGuide",
      "全アイテムのクラフト方法を確認できます。DQMの攻略を進めるためにはほぼ必須と言っても過言ではありません。"
          "Gキーで開けます。",
      mod: DownloadableAsset(
        url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/CraftGuide-1.6.7.3-modloader.zip"),
        size: 287669,
        md5: "049409351B2C8DA043C3EDAF6864B9B5",
      )),
  AdditionalMod(
    "Inventory Tweaks",
    "インベントリを整理してくれます。Rキーで発動します。",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/InventoryTweaks-1.54.jar"),
      size: 181890,
      md5: "9ABB1A208511091A14AEB313A948B099",
    ),
  ),
  AdditionalMod(
    "Multi Page Chest",
    "超大容量チェストを追加するMODです。ダイヤ4個とチェスト4個でクラフトできます。",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/multiPageChest_1.2.3_Universal.zip"),
      size: 25232,
      md5: "BCEFFA79B66FA82479DEE29EA0001D02",
    ),
  ),
  AdditionalMod(
    "日本語MOD",
    "Minecraft 1.5.2は日本語入力に非対応のため、このMODを導入すると日本語でチャットを打ち込めるようになります。",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/NihongoMOD_v1.2.2_forMC1.5.2.zip"),
      size: 98764,
      md5: "C0E324D3D76B377D4C241A38D2190909",
    ),
  ),
  AdditionalMod(
    "VoxelMap",
    "地図MODです。最後に死んだ場所を記録したり、マップピンを刺したりできます。Mキーでオプションが開きます。",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/VoxelMap-1.5.2.zip"),
      size: 435242,
      md5: "DC29DD2035FBC1B2151B3A73797B1D41",
    ),
  ),
  AdditionalMod(
    "Damage Indicators",
    "Mobの残り体力を表示できます。与えたダメージを表示する機能もありますが、こちらはDQMに標準で備わっています。",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/1.5.2 DamageIndicators v2.7.0.1.zip"),
      size: 292208,
      md5: "B781CC90B6AA50DDD3FD11388D8E34BB",
    ),
  ),
  AdditionalMod(
    "MineAll",
    "岩石を一括破壊できます。DQMの岩石に対応させるには下記の設定が必要です。",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/[1.5.2]mod_MineAllSMP_v2.5.6_forge7.8.0.696.zip"),
      size: 12672,
      md5: "5D6636100D5915CF25CFC07B10492405",
    ),
  ),
  AdditionalMod(
    "CutAll",
    "木を一括破壊できます。",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/[1.5.2]mod_CutAllSMP_v2.4.7_forge7.8.0.696.zip"),
      size: 11443,
      md5: "2520FAAE983B776C617D4F29ECC31DB0",
    ),
  ),
  AdditionalMod(
    "DigAll",
    "土を一括破壊できます。DQMディメンションの土に対応させるには下記の設定が必要です。",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/[1.5.2]mod_DigAllSMP_v2.2.6_forge7.8.0.696.zip"),
      size: 12648,
      md5: "F0F78B1CE7302965BE50C96BA6BE417E",
    ),
  ),
  AdditionalMod(
    "LookupID",
    "Minecraftの各ブロックに割り当てられているIDを確認することができます。ブロックに向かってIキーを押すと表示されます。\n"
        "DQM世界のブロックに一括破壊系を対応させるには、次の設定が必要です。\n"
        "1. .minecraftフォルダーの中にある「config」フォルダー内の「mod_MineAllSMP.cfg」（「MineAll」の部分はMODに合わせてください）というファイルをメモ帳で開く。\n"
        "2. 「blockIds=」に続けて破壊対象のブロックIDがカンマ区切りで並んでいるが、そこにBlockIDを追記する。\n"
        "3. (ブランチマイニング等に使用する場合)「limiter=」に続けて「0」とあるが、これを「3」に書き換える。でないと大変なことになる。(3にすると3x3x3の範囲が削れる。)",
    mod: DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/recommended-mods/%5B1.5.2%5DLookupID.zip"),
      size: 1459,
      md5: "5D530906E8300C248D6A4DD7BC662875",
    ),
  ),
];

class AdditionalMod {
  final String title;
  final String description;
  final DownloadableAsset mod;
  final DownloadableAsset? coreMod;

  const AdditionalMod(this.title, this.description,
      {required this.mod, this.coreMod});

  List<DownloadableAsset> toFiles() {
    return [mod, if (coreMod != null) coreMod!];
  }
}
