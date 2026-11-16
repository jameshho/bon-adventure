extends SceneTree
## 4 Nov 2026, Stage 4d batch 1: the supermarket order and the cashier in Chinese (a draft
## language, so the Lexicon is set directly). Every shop, cashier and money line renders in
## Chinese with its values filled and reads completely in pinyin, for random orders and
## amounts. Pure logic, no town and no saves:
## godot --headless --path . --script res://docs/evidence/chinese-shop-20261104/verify.gd
const Lexicon := preload("res://scripts/language/lexicon.gd")
const ShopDialogue := preload("res://scripts/learning/shop_dialogue.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const ROUNDS := 200
var failures := 0
var checks := 0
var lex
var bad: Array = []

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

## One rendered Chinese line: filled, not the phrase id, and every character has pinyin.
func expect_line(id: String, line: Dictionary) -> void:
	var text := str(line.get("foreign", ""))
	if text == "" or text == id or "{" in text or not lex.reading_gaps(text, "zh").is_empty() or lex.reading(text, "zh") == "":
		bad.append("%s -> %s | %s" % [id, text, lex.reading(text, "zh")])

func run() -> void:
	lex = Lexicon.shared()
	lex.native = "en"
	lex.foreign = "zh"
	var dialogue = ShopDialogue.new(lex)
	var pool: Array = []
	for key in lex.words():
		if "supermarket" in lex.words()[key].get("sold_in", []):
			pool.append(key)
	var missing_words: Array = pool.filter(func(key): return lex.word_entry(key, "zh").text == "")
	check(pool.size() >= 80 and missing_words.is_empty(), "every supermarket item has Chinese (%d items, missing %s)" % [pool.size(), missing_words])
	var people: Array = lex.words().keys().filter(func(key): return lex.words()[key].get("category", "") == "People" and lex.word_entry(key, "zh").text == "")
	check(people.is_empty(), "every People word has Chinese: %s" % [people])
	check(dialogue.speaker("salesperson", "m") == "售貨員" and dialogue.speaker("cashier", "f") == "收銀員", "speaker cards in Chinese: %s, %s" % [dialogue.speaker("salesperson", "m"), dialogue.speaker("cashier", "f")])
	for group in ["shop", "cashier", "money"]:
		for id in lex.phrases:
			if id.begins_with(group + ".") and not lex.phrases[id].has("zh"):
				bad.append("no Chinese line: " + id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for round_index in ROUNDS:
		var items: Dictionary = {}
		for i in rng.randi_range(2, 5):
			items[pool[rng.randi_range(0, pool.size() - 1)]] = rng.randi_range(1, 5)
		var keys: Array = items.keys()
		expect_line("shop.retry_keep", dialogue.line("shop.retry_keep", {"correct": dialogue.items_values(items)}))
		expect_line("shop.retry_missing", dialogue.line("shop.retry_missing", {"missing": dialogue.items_values(items)}))
		expect_line("shop.extra_item", dialogue.line("shop.extra_item", {"item": {"word": keys[0]}}))
		expect_line("shop.final_reveal", dialogue.line("shop.final_reveal", {"pairs": {"zh": dialogue.pairs_text(keys), "en": dialogue.pairs_text(keys)}}))
		var cents := Currency.random_cents(rng)
		for variant in range(1, 6):
			expect_line("cashier.request_%d" % variant, dialogue.line("cashier.request_%d" % variant, {"amount": dialogue.money_values(cents)}))
		for id in ["cashier.gave", "cashier.short", "cashier.over"]:
			expect_line(id, dialogue.line(id, {"given": dialogue.money_values(cents), "diff": dialogue.money_values(cents)}))
		var words: String = lex.money(cents, "zh")
		if not ("美元" in words or "美仙" in words):
			bad.append("money %d -> %s" % [cents, words])
	for id in lex.phrases:
		if (id.begins_with("shop.") or id.begins_with("cashier.") or id.begins_with("money.")) and lex.placeholders(str(lex.phrases[id].get("zh", ""))).is_empty():
			expect_line(id, dialogue.line(id))
	expect_line("shop.return_to_clerk", dialogue.line("shop.return_to_clerk", {"clerk": dialogue.role("salesperson", "m")}))
	expect_line("shop.cart_max", dialogue.line("shop.cart_max", {"max": 10}))
	check(bad.is_empty(), "%d rounds of shop and cashier lines render in Chinese with pinyin: %s" % [ROUNDS, bad.slice(0, 4)])
	print("sample: ", dialogue.line("shop.retry_missing", {"missing": dialogue.items_values({"apple": 2, "milk": 1})}).foreign, " | ", lex.reading(dialogue.line("shop.retry_missing", {"missing": dialogue.items_values({"apple": 2, "milk": 1})}).foreign, "zh"))
	print("sample: ", dialogue.line("cashier.request_1", {"amount": dialogue.money_values(14738)}).foreign, " | ", lex.reading(dialogue.line("cashier.request_1", {"amount": dialogue.money_values(14738)}).foreign, "zh"))
	lex.native = "en"
	lex.foreign = "es"
	print("chinese shop: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
