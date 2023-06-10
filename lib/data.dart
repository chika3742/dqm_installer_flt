import 'libs/installer.dart';

final List<AdditionalMod> additionalMods = [
  AdditionalMod(
    "Skin Fixer",
    "ランチャーでアップロードしたスキンをゲーム内に反映させます。"
        "これを導入しなかった場合には、上で指定したスキンが使用されます。"
        "スリムスキンは腕に黒帯が発生します。",
    mod: DownloadableAsset(
      Uri.parse(
          "https://mediafilez.forgecdn.net/files/2571/89/skin-fixer-1.5.2-1.0.1.jar"),
      196880,
    ),
  ),
  AdditionalMod(
      "ChickenChunks",
      "チャンク読み込みMOD。これを使うと、別ディメンションにいるときでも薬草などが育ちます。\n"
          "チャンクローダーをクラフトする必要があります。クラフト方法はCraftGuideで調べてください。",
      mod: DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/recommended-mods/ChickenChunks 1.3.2.14.jar"),
        93761,
      ),
      coreMod: DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/recommended-mods/CodeChickenCore 0.8.7.3-fix1.jar"),
        322443,
      )),
  AdditionalMod(
      "CraftGuide",
      "全アイテムのクラフト方法を確認できます。DQMの攻略を進めるためにはほぼ必須と言っても過言ではありません。"
          "Gキーで開けます。",
      mod: DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/recommended-mods/CraftGuide-1.6.7.3-modloader.zip"),
        287669,
      )),
  AdditionalMod(
    "Inventory Tweaks",
    "インベントリを整理してくれます。Rキーで発動します。",
    mod: DownloadableAsset(
      Uri.parse(
          "https://r2.chikach.net/dqm-assets/recommended-mods/InventoryTweaks-1.54.jar"),
      181890,
    ),
  ),
  AdditionalMod(
    "Multi Page Chest",
    "超大容量チェストを追加するMODです。ダイヤ4個とチェスト4個でクラフトできます。",
    mod: DownloadableAsset(
      Uri.parse(
          "https://r2.chikach.net/dqm-assets/recommended-mods/multiPageChest_1.2.3_Universal.zip"),
      25232,
    ),
  ),
  AdditionalMod(
    "日本語MOD",
    "Minecraft 1.5.2は日本語入力に非対応のため、このMODを導入すると日本語でチャットを打ち込めるようになります。",
    mod: DownloadableAsset(
      Uri.parse(
          "https://r2.chikach.net/dqm-assets/recommended-mods/NihongoMOD_v1.2.2_forMC1.5.2.zip"),
      98764,
    ),
  ),
  AdditionalMod(
    "VoxelMap",
    "地図MODです。最後に死んだ場所を記録したり、マップピンを刺したりできます。",
    mod: DownloadableAsset(
      Uri.parse(
          "https://r2.chikach.net/dqm-assets/recommended-mods/VoxelMap-1.5.2.zip"),
      435242,
    ),
  ),
  AdditionalMod(
    "Damage Indicators",
    "Mobの残り体力を表示できます。",
    mod: DownloadableAsset(
      Uri.parse(
          "https://r2.chikach.net/dqm-assets/recommended-mods/1.5.2 DamageIndicators v2.7.0.1.zip"),
      292208,
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
