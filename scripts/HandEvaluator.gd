class_name HandEvaluator

enum Hand {
	HIGH_CARD,
	PAIR,
	TWO_PAIR,
	THREE_OF_A_KIND,
	STRAIGHT,
	FLUSH,
	FULL_HOUSE,
	FOUR_OF_A_KIND,
	STRAIGHT_FLUSH,
	ROYAL_FLUSH
}

const HAND_NAMES = {
	Hand.HIGH_CARD: "High Card",
	Hand.PAIR: "Pair",
	Hand.TWO_PAIR: "Two Pair",
	Hand.THREE_OF_A_KIND: "Three of a Kind",
	Hand.STRAIGHT: "Straight",
	Hand.FLUSH: "Flush",
	Hand.FULL_HOUSE: "Full House",
	Hand.FOUR_OF_A_KIND: "Four of a Kind",
	Hand.STRAIGHT_FLUSH: "Straight Flush",
	Hand.ROYAL_FLUSH: "Royal Flush"
}

const HAND_MULTIPLIERS = {
	Hand.HIGH_CARD: 1,
	Hand.PAIR: 2,
	Hand.TWO_PAIR: 3,
	Hand.THREE_OF_A_KIND: 4,
	Hand.STRAIGHT: 5,
	Hand.FLUSH: 6,
	Hand.FULL_HOUSE: 8,
	Hand.FOUR_OF_A_KIND: 12,
	Hand.STRAIGHT_FLUSH: 20,
	Hand.ROYAL_FLUSH: 50
}

# Main function — pass in array of {rank, suit} dicts
# New signature — accepts optional modifiers
static func evaluate(cards: Array, doubled_index: int = -1) -> Hand:
	var expanded = cards.duplicate()

	# DOUBLE — insert the doubled card again
	if doubled_index >= 0 and doubled_index < expanded.size():
		expanded.append(expanded[doubled_index])

	# WILD — replace wild cards with best possible rank
	for i in range(expanded.size()):
		if expanded[i].suit == "w":
			expanded[i] = _best_wild(expanded)

	# Now evaluate the (up to 6 card) hand — take best 5
	if expanded.size() > 5:
		return _best_five(expanded)

	var ranks = expanded.map(func(c): return c.rank)
	var suits = expanded.map(func(c): return c.suit)
	return _evaluate_five(ranks, suits)

static func _best_wild(cards: Array) -> Dictionary:
	# Wild becomes whatever rank appears most in hand
	var freq = {}
	for c in cards:
		if c.suit != "w":
			freq[c.rank] = freq.get(c.rank, 0) + 1
	var best_rank = 14
	var best_count = 0
	for r in freq:
		if freq[r] > best_count:
			best_count = freq[r]
			best_rank = r
	return {"rank": best_rank, "suit": cards[0].suit}

static func _best_five(cards: Array) -> Hand:
	# Try all combinations of 5 from 6, return best hand
	var best = Hand.HIGH_CARD
	for skip in range(cards.size()):
		var five = []
		for i in range(cards.size()):
			if i != skip:
				five.append(cards[i])
		var ranks = five.map(func(c): return c.rank)
		var suits = five.map(func(c): return c.suit)
		var h = _evaluate_five(ranks, suits)
		if h > best:
			best = h
	return best

# Rename your existing evaluate logic into this:
static func _evaluate_five(ranks: Array, suits: Array) -> Hand:
	var is_flush = _check_flush(suits)
	var is_straight = _check_straight(ranks)
	var counts = _rank_counts(ranks)

	if is_flush and is_straight:
		if ranks.has(1) and ranks.has(10) and ranks.has(11) and ranks.has(12) and ranks.has(13):
			return Hand.ROYAL_FLUSH
		return Hand.STRAIGHT_FLUSH
	if counts.has(4): return Hand.FOUR_OF_A_KIND
	if counts.has(3) and counts.has(2): return Hand.FULL_HOUSE
	if is_flush: return Hand.FLUSH
	if is_straight: return Hand.STRAIGHT
	if counts.has(3): return Hand.THREE_OF_A_KIND
	if counts.has(2) and counts[2] == 2: return Hand.TWO_PAIR
	if counts.has(2): return Hand.PAIR
	return Hand.HIGH_CARD

static func get_hand_name(hand: Hand) -> String:
	return HAND_NAMES[hand]

static func get_hand_multiplier(hand: Hand) -> int:
	return HAND_MULTIPLIERS[hand]

# --- helpers ---

static func _check_flush(suits: Array) -> bool:
	return suits.count(suits[0]) == 5

static func _check_straight(ranks: Array) -> bool:
	var sorted = ranks.duplicate()
	sorted.sort()
	# Normal straight (Ace = 1, so 1-2-3-4-5 is a straight)
	var is_seq = true
	for i in range(1, sorted.size()):
		if sorted[i] != sorted[i-1] + 1:
			is_seq = false
			break
	if is_seq:
		return true
	# Wheel straight with Ace-high: 10-J-Q-K-A (10,11,12,13,1)
	if sorted == [1, 10, 11, 12, 13]:
		return true
	return false

# Returns a dict of how many times each count appears
# e.g. [A,A,K,K,K] → {2:1, 3:1}  (one pair, one three)
static func _rank_counts(ranks: Array) -> Dictionary:
	var freq = {}
	for r in ranks:
		freq[r] = freq.get(r, 0) + 1
	# Flip to count-of-counts
	var counts = {}
	for r in freq:
		var c = freq[r]
		counts[c] = counts.get(c, 0) + 1
	return counts
