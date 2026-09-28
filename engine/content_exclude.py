# -*- coding: utf-8 -*-
"""
Manual content-safety exclusion list, compiled by reviewing every word
whose JMdict gloss matched violence/death/suicide/weapon/crime/explicit-
sexual keyword patterns. Kept vs excluded was decided by which sense is
actually DOMINANT in everyday use (e.g. 真剣 "serious" kept despite an
etymological "real sword" origin; 一家 "a family" kept despite a slang
"yakuza family" sense; 達磨 "daruma doll" kept despite an archaic
"prostitute" sense) -- this is exactly the editorial judgment call the
product spec assigns to a native reviewer; treat this as a first pass,
not a substitute for one.
"""

EXCLUDE_WORDS = {
    # death / suicide
    "遺書", "遺体", "殺意", "殺害", "殺人", "死人", "死体", "自殺", "他殺",
    "亡骸", "未遂", "自決", "特攻隊", "過失致死", "殺人事件", "心中",
    # explicit sexual / bodily
    "勃起", "射精", "性交", "娼婦", "売春", "売春婦", "大便", "汚物",
    "婦女暴行", "暴行", "乱暴",
    # weapons
    "拷問", "大砲", "短刀", "鉄砲", "刀剣", "毒殺", "毒薬", "鈍器", "爆弾",
    "発砲", "武器", "兵器", "猟銃", "空砲", "火炎瓶", "核実験", "核兵器",
    "機関銃", "発煙筒", "化学兵器", "劇薬", "日本刀", "弓矢", "小刀",
    "照準", "銃声", "引金",
    # crime / organized violence
    "暗殺", "強奪", "強盗", "強要", "恐喝", "脅迫", "絞殺", "盗賊", "盗難",
    "暴挙", "麻薬", "誘拐", "炸裂", "泥棒", "略奪", "水爆", "総会屋",
    "暴力団", "拉致問題", "組長", "暴力", "凶器", "虐殺", "愚連隊",

    # sexual / exploitation (incl. minors) -- caught by a follow-up scan,
    # not the original keyword pass; the euphemistic JMdict gloss
    # ("paid dating") hid the actual meaning from simple keyword matching
    "援助交際", "裸婦", "性癖", "乳首",

    # non-standard orthography: JMdict lists these as alternate spellings,
    # but the natural, standard written form uses the 々 iteration mark or
    # kana instead (元々/蝶々/中々/代々, or plain kana for onomatopoeia) --
    # a native speaker essentially never writes the doubled-kanji form.
    "本々", "粘粘", "日日", "一一", "蝶蝶", "中中", "代代",

    # obscure / dated / overly narrow for a general-audience app
    "二七日",  # niche Buddhist mourning-ritual term, also death-adjacent
    "成人病",  # outdated medical term, officially superseded by 生活習慣病
    "好守",    # narrow baseball-fielding jargon, not general vocabulary

    # --- second pass: exhaustive review of all 376 words containing a
    # risk-associated kanji component (殺死毒盗奪虐姦淫痴娼妓裸糞尿拷暴凶兵
    # 爆銃砲刃斬葬棺屍絞溺脅恫恐辱侵覚醒麻姦監禁拉致漢撮凌辱窃猥褻堕胎流産),
    # not just a keyword-in-gloss scan. Word-occupation/institution terms
    # (兵士, 刑務所-style, funeral-service terms) were kept as neutral;
    # words whose dominant sense is a violent act, a weapon, a person's
    # death, or a serious crime were excluded even where the JMdict
    # priority tag alone would have allowed them through.

    # death of a person (as opposed to plants/baseball jargon/idioms kept below)
    "急死", "死因", "死去", "死刑", "死後", "死者", "死亡", "水死", "凍死",
    "病死", "戦死", "即死", "焼死", "脳死", "餓死", "安楽死", "絞首刑",
    "致死", "致死量", "致命傷", "死傷者", "死亡者", "死亡率", "死刑囚",
    "殺気", "殺傷", "残虐", "射殺", "抹殺",

    # weapons / firearms / explosives / crime
    "監禁", "軟禁", "拳銃", "短銃", "銃器", "銃殺", "銃声", "銃弾", "小銃",
    "銃撃", "窃盗", "盗聴", "盗品", "盗用", "爆撃", "爆破", "爆発", "爆薬",
    "空爆", "原爆", "原水爆", "被爆", "迫撃砲", "砲火", "砲撃", "砲弾",
    "覚醒剤", "大麻", "痴漢", "堕胎", "胎児", "胎盤",

    # violence / atrocity / war aggression / abuse
    "虐待", "粗暴", "侮辱", "凶悪", "侵攻", "侵略", "暴徒", "暴動", "暴虐",

    # defunct government ministries (renamed/merged in the 2001 central
    # government reorganization) -- factually outdated, not just a style
    # preference
    "通産省", "通産相", "厚生省", "労働省", "文部省", "自治省", "郵政省",
    "建設省", "運輸省", "総理府", "経企庁", "国土庁",

    # non-standard orthography (native writing uses kana, not these kanji)
    "沢山", "出鱈目", "兎角",
    "御洒落",  # almost always おしゃれ or お洒落; the 御- prefix form is unnatural here

    # --- third pass: 320-word broad random sample for reading/naturalness ---
    "精子",    # reproductive/clinical anatomy, same category as 胎児/胎盤 already excluded
    "復讐",    # revenge -- conflict-themed, not calm-tone content
    "鎮圧",    # suppression of riots/uprisings, consistent with excluding 暴動 etc.
    "鈍間",    # mildly derogatory insult ("blockhead"), unpleasant as a puzzle answer

    # --- fourth pass: another 260-word broad random sample ---
    "生殖",    # reproductive biology term, same category as 精子/胎児
    "婦女",    # archaic/legalistic register for "women", unnatural standalone
    "此方",    # essentially always written こちら in kana in modern Japanese
    "白血病",  # serious/distressing illness (leukemia), heavier than health terms kept
}
