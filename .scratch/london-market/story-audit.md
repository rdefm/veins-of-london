# London market: user-story audit (ticket 13)

Legend: **P** pass (test / sim / doc evidence), **G** gap (reported, not fixed), **QA** needs human on-device QA (also P on the numbers where noted).
Evidence: `tests/test_market.gd` (M), `test_faction_sim.gd` (F), `test_soho.gd` (S), `test_offers.gd` (O), `test_map_pins.gd` (MP), `test_savemanager.gd` (SM), `test_archie_deals.gd` (AD). Case names abbreviated. Balance numbers from `balance-report.md` (BR), seeds 1-3, days 31-60.

Suite: `scripts/run_tests.sh` 4779 passed, **1 failed**: `test_playthrough: full_playthrough_tutorial_economy_ticks_and_save_roundtrip`. BR ticket 18 records it failing on the original tree too; not market-related (whole-state compare after save round-trip). `scripts/check_all.sh`: clean (503 files).

## Market as a real place
| # | | Evidence |
|---|---|---|
| 1 | P | M `archie_ore_dump_..._lands_in_stock`, `recorded_supply_enters_at_its_tier...`; F `a_sale_enters_stock_at_the_tier_held...` |
| 2 | P | F `a_buy_is_limited_to_the_shelf...`; S `buying_ore_moves_cash_pool_and_demand` |
| 3 | P | M `a_tiers_price_is_the_quote_times_the_quality_multiplier`; one quote per good (§3.13) |
| 4 | P | M `idle_london_stays_sane_with_factions_trading`, `idle_independents_only_market_settles_high_and_holds`; BR avg price (but see 89) |
| 5 | P | M `nameless_demand_falls_as_price_rises_down_to_a_floor` |
| 6 | P | M `independents_supply_rises_with_price_up_to_a_cap` |
| 7 | P | F `conclave_arbitrage_buys_a_crashed_good_and_sells_a_spiked_one`; M `a_big_faction_buy_or_sell_is_annotated...` |
| 8 | P | normalStock ~14 days of civilian demand, nameless flows dominate (BR: independents 34-48% of ore, items 24-30%) |
| 9 | P | same as 8 (civilianDemand + elasticity); M `stock_change_equals_the_sum_of_the_flows` |
| 10 | P | BR ticket 18: item named share 73 / 76 / 77% (s2, s3 slightly over 75; accepted by human at ticket 18 close) |

## Prices and control
| # | | Evidence |
|---|---|---|
| 11 | P | BR: 100-ore sale -1.3%, 10 Time Pearls 0% |
| 12 | P | BR: withholding 40/day for 7d +30% vs control, 80/day +84% |
| 13 | P | BR withhold result via Market seam; F `a_withheld_good_is_all_reserved` |
| 14 | P | F `a_planned_flood_raises_the_flooders_reserve...`; spec routes flood/deny/stabiliser capped by availability (F `a_buy_is_limited_to_the_shelf...`) |
| 15 | P | BR "Sustained player corner": Life 80/day for 7d +33%, 150/day +70% |
| 16 | P | M `war_lifts_shield...`, `demand_all_lifts_and_lowers_every_item`, `ticker_shift_annotates...`, `post_story_posts_headline_raises_emotion_demand_then_lapses` |

## Tiers
| # | | Evidence |
|---|---|---|
| 17 | P | M `item_stock_is_held_per_tier_and_sums_to_the_total` |
| 18 | P | M `a_tiers_price_is_the_quote_times_the_quality_multiplier` (+25% a tier) |
| 19 | P | S buy rows carry per-tier stock/availability; **QA** display |
| 20 | P | S `buying_items_lands_at_the_tier_bought`; **QA** tier picker |
| 21 | P | S `sold_items_enter_stock_at_their_tier...`; M `recorded_supply_enters_at_its_tier...` |
| 22 | P | S `...better_tiers_pay_more` |
| 23 | P | F `a_sale_enters_stock_at_the_tier_held_and_is_paid_per_tier` |
| 24 | P | F `a_buy_is_limited_to_the_shelf_and_takes_the_lowest_tier_first` |
| 25 | P | M price curve reads total stock across tiers (`item_stock_is_held_per_tier_and_sums_to_the_total`); §3.13 |

## Faction trade
| # | | Evidence |
|---|---|---|
| 26 | P | F `a_sale_enters_stock...` |
| 27 | P | F `a_faction_buys_its_shortfall_and_the_quote_rises` |
| 28 | P | REFERENCE §3.1 "Two passes"; `FactionSim.trade_order()`; F rotation case |
| 29 | P | F `a_buy_is_limited_to_the_shelf...`; M `availability_floors_at_zero...` |
| 30 | P | F shelf-limited buy case (pays by units received) |
| 31 | P | F `the_first_faction_served_rotates_by_day_and_repeats` |
| 32 | P | F `a_burn_holdings_cannot_cover_becomes_shortfall`; BR shortfall days tracked |
| 33 | P | BR: Network short on Déjà Vu 9/30 days (only crafter / Fate); emergent shortage visible. Also see 90 |
| 34 | P | no war rule in code (`FactionSim.trade` has no war check; spec "anonymous") |
| 35 | P | F `conclave_arbitrage_is_capped_by_cash_and_daily_volume`; availability caps all market moves |

## Direct trades
| # | | Evidence |
|---|---|---|
| 36 | P | existing lanes untouched: `test_vein_trade`, `test_recipe_seller_trade` pass |
| 37 | P | direct routes stop recording to tallies; M tally cases; table in spec Routes |
| 38 | P | emergent via faction resell (BR sim, no direct unit test) |
| 39 | P | emergent via shortfall path; F shortfall cases |
| 40 | P | emergent; F `a_withheld_good_is_all_reserved` |
| 41 | P | business calc purchases are in the "No" rows; no market record (tallies stop) |
| 42 | P | AD / M `archie_ore_dump_sells_at_todays_quote_and_lands_in_stock` |
| 43 | P | M `archie_ore_dump...lands_in_stock`, `mugged_archie_ore_sale_still_records_supply` |
| 44 | P | AD `roll_deal_prices_at_the_london_quote_and_records_nothing`, `accept_deal_*` |
| 45 | P | Soho beats Archie only from £300 (BR table); Archie keeps relation gain, tag-alongs, no fee under £300 premium; S `no_relation_gain_and_no_archie_cut` |

## Soho Marketplace
| # | | Evidence |
|---|---|---|
| 46 | P | S `locked_until_the_flag_is_set`; flag set by `biz_a1_closing` |
| 47 | P | `data/events/biz_a1_closing.json` c9a/c9b (Archie: bulk to Soho, small to me); **PROSE-REVIEW** done at ticket 10 |
| 48 | P | MP `soho_pin_absent_before_unlock_present_after`; **QA** placement on map |
| 49 | P | same MP case |
| 50 | P | S `closing_event_sets_flag_and_old_saves_backfill`; SaveManager.gd:296 |
| 51 | P | S `buying_ore_moves_cash...`, `selling_uses_the_shared_pool_only` |
| 52 | P | S `buying_items_lands_at_the_tier_bought`, `sold_items_enter_stock_at_their_tier...` |
| 53 | P | S rows; **QA** display |
| 54 | P | S `buying_is_limited_by_availability_and_cash` |
| 55 | P | S `buying_items_lands...`, `buying_ore_moves_cash_pool...` |
| 56 | P | S `selling_uses_the_shared_pool_only` |
| 57 | P | S `no_relation_gain_and_no_archie_cut` (no mugging path in `soho.gd`) |
| 58 | QA | S `availability` zero covered; empty-state rendering is on-device |

## Fees and rungs
| # | | Evidence |
|---|---|---|
| 59 | P | S `first_sell_rung_beats_archie_and_top_can_undercut_never_below_floor`; BR: +3 pts below £300 |
| 60 | P | BR ladder 0.43 → 0.08 |
| 61 | P | same S case; BR r2+ beats Archie at every relation |
| 62 | QA | rows tested (S `fee_rows_match_what_is_charged_at_every_rung`); live update on-device |
| 63 | QA | S fee rows give £ fee and net; display on-device |
| 64 | QA | S `rows_give_next_rung_and_top_rung_marks_best`, `buy_rows_give_ladder_next_rung_and_top`; display on-device |
| 65 | QA | same rows; display on-device |
| 66 | QA | ladder in rows; display on-device |
| 67 | QA | rung-cross signal is screen-only |
| 68 | QA | S top-rung "best" flag tested; display on-device |
| 69 | QA | Archie comparable fee in row; display on-device |
| 70 | P | S `fee_rows_match_what_is_charged_at_every_rung` |

## Root Feed
| # | | Evidence |
|---|---|---|
| 71 | P | F `root_feed_want_scales_with_veins_by_archetype_and_stops_at_the_cap` |
| 72 | P | same (producer 1.0 vs crafter 0.5) |
| 73 | P | same (cap 12) |
| 74 | P | want uses owned veins, F `root_feed_is_reserved_up_to_want...` |
| 75 | P | same reserve + shortfall buy |
| 76 | P | F `root_feed_is_reserved_up_to_want_and_tier_0_does_not_block_better_feed` |
| 77 | P | F `a_holding_faction_feeds_its_lowest_growth_unfed_vein_up_to_the_limit` |
| 78 | P | BR: faction harvests with feed; F feed cases (visible effect via harvest numbers) |
| 79 | G | BR ticket 12: net flow ≈ 0 on average (+0.2/+0.2/-0.3 per day) but shortfall days remain (guild 9-24, conclave 10-11, firm 2-7 of 30). Not tuned; needs human |
| 80 | P | F `root_feed_offers_need_base_rung_and_weight_wanting_factions` |
| 81 | P | same |
| 82 | P | same |
| 83 | P | applying feed is the consumption (§3.4); F feed cases |

## Saves and determinism
| # | | Evidence |
|---|---|---|
| 84 | P | SM `loading_an_untiered_market_migrates_it_once_with_prices_steady`; M `migration_rescales_stock_and_splits_by_mix_with_prices_steady` |
| 85 | G | Save round-trip tested (SM `tiered_item_stock_round_trips_through_save_as_ints`). Spec asks save **and** Rewind; no Rewind-specific tiered-stock test exists. Rewind snapshots deep-copy pure state, so low risk; add a test |
| 86 | P | M `tiered_stock_repeats_under_the_same_input_and_stays_pure_data`; F `a_month_of_trading_repeats_under_the_same_seed` |

## Balance outcomes (BR)
| # | | Evidence |
|---|---|---|
| 87 | P* | Item named 73 / 76 / 77% (target 65-75; s2, s3 over by 1-2 pts). Human accepted at ticket 18 close |
| 88 | G | Ore named share 19 / 15 / 18% vs baseline 52 / 66 / 60 (relaxed on purpose: Independents ore share raised to meet price targets). Needs sign-off |
| 89 | G | Not met: 19 / 11 / 10 goods pinned at max ≥5 days (blackHole, deadweight, signalFailure, skeletonKey, heavyMetal, cleanSlate, dejaVu, happyAccident, goodYear…). Ticket 18 closed with this accepted by human; ore no longer pinned |
| 90 | G | Network short on Déjà Vu 3-9 days, Conclave 0-8, Firm/Guild some days (BR). Not permanent but not zero; accepted at ticket 18 close |
| 91 | P | BR: single sale invisible, withholding +30-84% |
| 92 | P | BR: turf identical (firm 23% leader, no zero-turf); war endings varied |
| 93 | G | Archie per-unit income ~2.5x baseline (BR ticket 12): ore prices sit at ~2.5x base. Not comparable; needs human call (accept / retune ore supply) |
| 94 | P* | Same-day buy-then-resell loses at every rung and tier (S `buy_then_resell_loses_money_at_every_rung_and_tier`). **Multi-day flip of large orders (≥~400 units, ≥£3k) profits** (BR): no slippage. Needs human call (accept as the "corner" play / add slippage) |
| 95 | P | Wallet growth reported (BR, both tickets): guild/network +50-70k/day, others +14-30k/day. Not fixed (out of scope) |

Totals: 95 stories. P 80 (87 and 94 with caveats), QA 9 (58, 62-69), G 6 (79, 85, 88, 89, 90, 93).

## Out-of-scope check (spec "Out of Scope")
- Equipment, device components, recipe fragments in Soho: not built (`soho.gd` trades only goods the market lists; market lists ore + consumables).
- New FactionAI cornering behaviour: `systems/faction_ai.gd` untouched since the pre-market commit (git log empty).
- War embargoes/bans: none (no war check in trade).
- Separate per-tier scarcity pricing: none (one total-stock curve).
- Archie's cut, sell lane, tag-alongs: unchanged (`archie*`/`selling` untouched; AD tests pass).
- Gating sell lanes by demand: none.
- Renaming the Guild Marketplace: not renamed (CONTEXT.md keeps it, now disambiguated).
- Faction wallet inflation: reported only.
Note: tickets 14/18 added mechanics beyond the original spec (Independents ore share 1.5, faction boosts via Good Year / Borrowed Time, an extra Collective Fate vein, roster ore swaps). Each was a balance response closed by the human; flagged here for visibility.

## Docs check
- REFERENCE §1.8 (`wantMult`), §3.4 (`wantDays`, `wantCap`, faction Root Feed), §3.6 (Archie lane, London quote + stock record), §3.13 (market, Soho ladders, migration, pinned values), §3.1 daily order (⑤d4 feed, ⑥.6 reprice, two-pass trade): present and match code constants (`wantDays 2`, `wantCap 12`, `wantMult` 1.0/0.5, `sohoUnlocked` flag).
- CONTEXT.md defines **London market**, **Soho Marketplace**, **Guild Marketplace** (lines 143-151).

## On-device QA list (human)
1. Before Act 1 closing event: no Soho pin on the map. After `biz_a1_closing`: Soho pin appears; also on an old save already past that event.
2. Soho pin opens the Trade view in Soho mode (not a separate screen); Buy and Sell tabs, ore and items, tier picker, per-tier stock and prices.
3. Empty goods show as empty / disabled with a clear reason; cannot buy over stock or cash; sell only from the shared pool (stashed goods untouched).
4. Fee row: % fee updates live as qty goes up and down; £ fee and net shown; matches the cash actually taken.
5. Rung display: full ladder with position marked; "sell £X more to reach Y%" text; the next rung's %; a clear mark on crossing a rung; "best rate reached" on the top rung.
6. Archie comparison for the current order is shown and sensible at low and high volume.
7. No mugging, no relation change after a Soho trade.
8. Layout matches `docs/ui-vision.md` (phone width, no overflow).
9. Archie still sells as before; Act 1 closing prose (Soho vs Archie) reads right.

## Needs human sign-off (open decisions)
1. Balance reports ticket 11 / 12 / 14 / 18: ore named 15-19%, pinned goods, shortfalls, wallet growth 3-8x.
2. Archie income ~2.5x baseline per unit (93).
3. Multi-day large-order flip profits (94): accept, add slippage, or other.
4. Root Feed shortfall days (79).
5. Add a Rewind round-trip test for tiered stock (85) (trivial; not done here).
6. Pre-existing failing test `full_playthrough_tutorial_economy_ticks_and_save_roundtrip`.
