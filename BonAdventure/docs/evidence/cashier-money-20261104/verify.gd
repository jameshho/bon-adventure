extends SceneTree
## 4 Nov 2026: cashier money-selection minigame, rules only (no town loaded, no saves).
## godot --headless --path . --script res://docs/evidence/cashier-money-20261104/verify.gd
const Currency := preload("res://scripts/learning/currency.gd")
## 4 Nov 2026: amounts in words moved from currency.gd to the Spanish rules module.
var es = preload("res://scripts/language/rules_es.gd").new()
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)
func run() -> void:
	# Denominations: 6 bills + 4 coins, unique ids, no $500.
	check(Currency.DENOMS.size() == 10, "ten denominations")
	var ids := {}
	for d in Currency.DENOMS: ids[d.id] = true
	check(ids.size() == 10 and not ids.has("bill_500"), "unique ids, no $500")
	# Known phrases.
	var known := {
		25: "veinticinco centavos", 1: "un centavo", 100: "un dólar", 101: "un dólar con un centavo",
		200: "dos dólares", 2100: "veintiún dólares", 2101: "veintiún dólares con un centavo",
		3100: "treinta y un dólares", 10000: "cien dólares", 10001: "cien dólares con un centavo",
		10100: "ciento un dólares", 10138: "ciento un dólares con treinta y ocho centavos",
		14738: "ciento cuarenta y siete dólares con treinta y ocho centavos",
		20000: "doscientos dólares", 30000: "trescientos dólares", 29999: "doscientos noventa y nueve dólares con noventa y nueve centavos",
		50000: "quinientos dólares", 100000: "mil dólares", 100100: "mil un dólares", 200000: "dos mil dólares",
		2100100: "veintiún mil un dólares", 12345: "ciento veintitrés dólares con cuarenta y cinco centavos",
		1000: "diez dólares", 1500: "quince dólares", 1599: "quince dólares con noventa y nueve centavos",
		2999: "veintinueve dólares con noventa y nueve centavos", 7005: "setenta dólares con cinco centavos",
		300000: "tres mil dólares", 0: "cero dólares",
	}
	for cents in known:
		var got := es.money_words(int(cents))
		check(got == known[cents], "%d -> '%s' (expected '%s')" % [cents, got, known[cents]])
	# Every request amount: structural rules.
	var bad := 0
	for cents in range(Currency.MIN_CENTS, Currency.MAX_CENTS + 1):
		var t := es.money_words(cents)
		var problem := ""
		if "  " in t or t.begins_with(" ") or t.ends_with(" "): problem = "spacing"
		elif " uno " in t or t.ends_with(" uno") or t.begins_with("uno "): problem = "uno"
		elif "veintiuno" in t: problem = "veintiuno"
		elif "un mil" in t: problem = "un mil"
		elif t.count("dólar") + t.count("centavo") == 0: problem = "no unit"
		elif cents % 100 != 0 and cents >= 100 and not " con " in t: problem = "missing con"
		elif cents % 100 == 0 and " con " in t: problem = "spurious con"
		elif cents < 100 and "dólar" in t: problem = "dollars for sub-dollar"
		elif cents / 100 == 1 and not (t.begins_with("un dólar")): problem = "one dollar"
		elif cents / 100 > 1 and not ("dólares" in t): problem = "plural dollars"
		elif cents % 100 == 1 and not (t.ends_with("un centavo")): problem = "one cent"
		elif cents % 100 > 1 and not t.ends_with("centavos") and cents % 100 != 0: problem = "plural cents"
		elif cents % 100 == 0 and not (t.ends_with("dólar") or t.ends_with("dólares")): problem = "ends dollars"
		if problem != "":
			bad += 1
			if bad <= 5: print("  bad ", cents, " ", problem, ": ", t)
	check(bad == 0, "all %d amounts well formed (%d bad)" % [Currency.MAX_CENTS - Currency.MIN_CENTS + 1, bad])
	# usd formatting.
	check(Currency.usd(25) == "$0.25" and Currency.usd(14738) == "$147.38" and Currency.usd(100000) == "$1,000.00" and Currency.usd(30000) == "$300.00", "usd format")
	# Totals and exactness (integer cents; any combination).
	check(Currency.total({"bill_100": 1, "bill_20": 2, "coin_25": 3, "coin_1": 3}) == 14078, "total mixed")
	check(Currency.is_exact({"bill_5": 1, "coin_25": 20}, 1000) and Currency.is_exact({"bill_10": 1}, 1000) and Currency.is_exact({"coin_10": 100}, 1000), "different combinations accepted")
	check(not Currency.is_exact({"bill_10": 1, "coin_1": 1}, 1000) and not Currency.is_exact({}, 25), "wrong totals rejected")
	var sum := 0.0
	for b in Currency.REQUEST_BUCKETS: sum += b[2]
	check(is_equal_approx(sum, 1.0), "bucket probabilities sum to 1")
	var contiguous := Currency.REQUEST_BUCKETS[0][0] == Currency.MIN_CENTS and Currency.REQUEST_BUCKETS[-1][1] == Currency.MAX_CENTS
	for i in range(1, Currency.REQUEST_BUCKETS.size()):
		if Currency.REQUEST_BUCKETS[i][0] != Currency.REQUEST_BUCKETS[i - 1][1] + 1: contiguous = false
	check(contiguous, "buckets contiguous over 25..30000")
	# Distribution over 200,000 draws: cumulative shares and the extremes.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var n := 200000
	var under := [0, 0, 0, 0]
	var lo := 999999
	var hi := 0
	for i in n:
		var c := Currency.random_cents(rng)
		lo = mini(lo, c)
		hi = maxi(hi, c)
		if c < 1000: under[0] += 1
		if c < 3000: under[1] += 1
		if c < 5000: under[2] += 1
		if c < 10000: under[3] += 1
	check(lo >= 25 and hi <= 30000, "draws stay in 25..30000 (%d..%d)" % [lo, hi])
	check(lo <= 40 and hi >= 29900, "both ends are reachable (%d..%d)" % [lo, hi])
	for pair in [[0, 0.10], [1, 0.40], [2, 0.70], [3, 0.90]]:
		var share := float(under[pair[0]]) / n
		check(absf(share - pair[1]) < 0.01, "cumulative share %d: %.3f ~ %.2f" % [pair[0], share, pair[1]])
	print("cashier money rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
