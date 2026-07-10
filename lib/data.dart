final List<AdditionalMod> additionalMods = [
  AdditionalMod(
    "Skin Fixer",
    "ランチャーでアップロードしたスキンをゲーム内に反映させます（※DQMVでは動作しません。上のフィールドにスキンの画像ファイルを設定してください。）。"
        "スリムスキンは腕に黒帯が発生します。",
    author: "Sm0keySa1m0n",
    mod: "assets/external_mods/skin-fixer-1.5.2-1.0.1.jar",
  ),
  AdditionalMod(
      "ChickenChunks",
      "チャンク読み込みMOD。これを使うと、別ディメンションにいるときでも薬草などが育ちます。\n"
          "チャンクローダーをクラフトする必要があります。クラフト方法はCraftGuideで調べてください。",
      author: "Chicken Bones",
      mod: "assets/external_mods/ChickenChunks 1.3.2.14.jar",
      coreMod: "assets/external_mods/CodeChickenCore 0.8.7.3-fix1.jar"),
  AdditionalMod(
      "CraftGuide",
      "全アイテムのクラフト方法を確認できます。DQMの攻略を進めるためにはほぼ必須と言っても過言ではありません。"
          "Gキーで開けます。",
      author: "Uristqwerty",
      mod: "assets/external_mods/CraftGuide-1.6.7.3-modloader.zip"),
  AdditionalMod(
    "Inventory Tweaks",
    "インベントリを整理してくれます。Rキーで発動します。",
    author: "Kobata",
    mod: "assets/external_mods/InventoryTweaks-1.54.jar",
  ),
  AdditionalMod(
    "Multi Page Chest",
    "超大容量チェストを追加するMODです。ダイヤ4個とチェスト4個でクラフトできます。",
    author: "cubex2",
    mod: "assets/external_mods/multiPageChest_1.2.3_Universal.zip",
  ),
  AdditionalMod(
    "日本語MOD",
    "Minecraft 1.5.2は日本語入力に非対応のため、このMODを導入すると日本語でチャットを打ち込めるようになります。",
    author: "wiro",
    mod: "assets/external_mods/NihongoMOD_v1.2.2_forMC1.5.2.zip",
  ),
  AdditionalMod(
    "VoxelMap",
    "地図MODです。最後に死んだ場所を記録したり、マップピンを刺したりできます。Mキーでオプションが開きます。",
    author: "MamiyaOtaru",
    mod: "assets/external_mods/VoxelMap-1.5.2.zip",
  ),
  AdditionalMod(
    "Damage Indicators",
    "Mobの残り体力を表示できます。与えたダメージを表示する機能もありますが、こちらはDQMに標準で備わっています。",
    author: "rich1051414",
    mod: "assets/external_mods/1.5.2 DamageIndicators v2.7.0.1.zip",
  ),
  AdditionalMod(
    "MineAll",
    "岩石を一括破壊できます。DQMの岩石に対応させるには下記の設定が必要です。",
    author: "scalar",
    mod: "assets/external_mods/[1.5.2]mod_MineAllSMP_v2.5.6_forge7.8.0.696.zip",
  ),
  AdditionalMod(
    "CutAll",
    "木を一括破壊できます。",
    author: "scalar",
    mod: "assets/external_mods/[1.5.2]mod_CutAllSMP_v2.4.7_forge7.8.0.696.zip",
  ),
  AdditionalMod(
    "DigAll",
    "土を一括破壊できます。DQMディメンションの土に対応させるには下記の設定が必要です。",
    author: "scalar",
    mod: "assets/external_mods/[1.5.2]mod_DigAllSMP_v2.2.6_forge7.8.0.696.zip",
  ),
  AdditionalMod(
    "LookupID",
    "Minecraftの各ブロックに割り当てられているIDを確認することができます。ブロックに向かってIキーを押すと表示されます。\n"
        "DQM世界のブロックに一括破壊系を対応させるには、次の設定が必要です。\n"
        "1. .minecraftフォルダーの中にある「config」フォルダー内の「mod_MineAllSMP.cfg」（「MineAll」の部分はMODに合わせてください）というファイルをメモ帳で開く。\n"
        "2. 「blockIds=」に続けて破壊対象のブロックIDがカンマ区切りで並んでいるが、そこにBlockIDを追記する。\n"
        "3. (ブランチマイニング等に使用する場合)「limiter=」に続けて「0」とあるが、これを「3」に書き換える。でないと大変なことになる。(3にすると3x3x3の範囲が削れる。)",
    author: "scalar",
    mod: "assets/external_mods/[1.5.2]LookupID.zip",
  ),
];

class AdditionalMod {
  final String title;
  final String description;
  final String author;

  /// Bundle asset key for mod body.
  final String mod;

  /// Bundle asset key for core mod.
  final String? coreMod;

  const AdditionalMod(
    this.title,
    this.description, {
    required this.author,
    required this.mod,
    this.coreMod,
  });

  List<String> toFiles() {
    return [mod, if (coreMod != null) coreMod!];
  }
}
