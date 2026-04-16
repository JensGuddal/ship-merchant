# Project Context — Ship Merchant RPG

> Drop this file in the root of your Godot project.
> Start every Cursor session with: "Read project_context.md before writing any code."

---

## Game Concept

A 2D Age of Sail trading RPG built in **Godot 4 (GDScript)**. The player starts as a
penniless merchant with only a small inventory of trade goods and a few coins. Through
buying low and selling high between ports, the player builds a shipping empire — acquiring
ships, hiring crew, opening a trade office, and dominating sea routes.

Inspired by **Mount & Blade: Warband / Bannerlord** and **Kenshi** in terms of open-ended
economic progression and emergent difficulty.

---

## Engine & Language

- **Engine:** Godot 4
- **Language:** GDScript
- **Perspective:** Top-down 2D
- **Controls:** WASD to move player, E to interact with objects/NPCs

---

## Core Gameplay Loop

```
World Map → Enter Port (E) → Trade Screen → Manage Fleet/Crew → World Map
```

1. Player navigates the world map between port cities
2. At each port, press E to enter the port scene
3. Visit the market to buy/sell goods
4. Visit the dockyard to hire crew or buy/upgrade ships
5. Visit the office to manage routes and investments
6. Set sail to the next port and repeat

---

## Scene Structure

```
Main.tscn                  ← Scene manager / root
├── WorldMap.tscn          ← Top-down map, WASD player movement, port nodes
├── Port.tscn              ← Port interior, NPC interactions, sub-scenes
│   ├── Market.tscn        ← Buy/sell trade goods
│   ├── Dockyard.tscn      ← Buy ships, hire crew
│   └── Office.tscn        ← Empire management, route assignments
├── TradeUI.tscn           ← Trade screen overlay (buy/sell interface)
├── FleetManager.tscn      ← Fleet overview and ship management
└── PlayerHUD.tscn         ← Persistent HUD: coins, rep, inventory summary
```

**Scene switching** is handled by `Main.tscn` via a scene manager function.
Never use `get_tree().change_scene_to_file()` directly in child scenes —
always signal up to Main to handle transitions.

---

## Autoload Singletons

These are always loaded. Reference them anywhere with their name.

### `GameData`
Owns all persistent player state. Handles save and load via Godot `FileAccess`.

```gdscript
# Key properties
var coins: int = 50
var inventory: Array[Dictionary] = []   # [{ "id": "wheat", "qty": 10 }]
var reputation: float = 0.0             # -100.0 to 100.0
var fleet: Array[Dictionary] = []       # [{ "name": "The Sparrow", "type": "sloop", ... }]
var crew: Array[Dictionary] = []        # [{ "name": "Hans", "role": "navigator", "wage": 5 }]
var office_level: int = 0               # 0 = none, 1-3 = tiers
var current_port: String = ""
var discovered_ports: Array[String] = []
```

### `EconomyManager`
Owns the goods catalogue and port price tables. Phase 1 uses **fixed prices per port**.
Phase 2 will add supply/demand. Keep price logic here so swapping is easy.

```gdscript
# Goods catalogue: { id, display_name, base_price, weight, category }
# Port price table: { port_id: { good_id: price } }
# Methods: get_buy_price(port_id, good_id), get_sell_price(port_id, good_id)
```

**Trade goods (Phase 1):**
| ID | Name | Base Price | Weight | Category |
|----|------|-----------|--------|----------|
| wheat | Wheat | 8 | 2 | Food |
| salt | Salt | 15 | 1 | Food |
| timber | Timber | 20 | 5 | Materials |
| iron | Iron | 35 | 4 | Materials |
| cloth | Cloth | 25 | 2 | Luxury |
| spices | Spices | 80 | 1 | Luxury |
| rum | Rum | 40 | 2 | Luxury |
| cannon | Cannon | 120 | 8 | Military |

### `FactionManager`
Tracks player reputation with each faction. Reputation affects trade prices,
port access, and NPC dialogue options.

```gdscript
# var reputation: Dictionary = { "merchants_guild": 0.0, "navy": 0.0, "pirates": 0.0 }
# Methods: modify_rep(faction, amount), get_rep(faction), get_rep_tier(faction)
# Tiers: Hostile < -50 | Unfriendly < -10 | Neutral | Friendly > 10 | Allied > 50
```

### `EventManager`
Fires random world events during travel (pirates, storms, merchant distress, etc.).
Events are triggered by `WorldMap.tscn` when the player moves between ports.

```gdscript
# Methods: roll_travel_event(from_port, to_port) -> Dictionary or null
# Event dict: { "type": "pirate_attack", "severity": 0.6, "description": "..." }
```

---

## Player Progression Arc

### Phase 0 — Foot Merchant (Starting State)
- No ship. Travels between nearby ports on foot / hired passage.
- Carries goods in personal inventory (weight limit: 30)
- Starting loadout: 50 coins, small mixed inventory of cheap goods
- Goal: Accumulate ~300 coins to afford a basic vessel

### Phase 1 — First Ship (Mid Game Entry)
Unlocked by saving up enough coins to purchase a vessel outright.

- **Milestone:** Buy a Sloop (~250–300 coins)
- Cargo capacity increases dramatically (weight limit: 150)
- Can now reach distant ports
- Hire first crew member (Navigator reduces travel time)
- Unlock `FleetManager` UI

### Phase 2 — Established Trader (Mid Game Core)
- Own 1–2 ships running different routes simultaneously
- Hire crew specialists: Navigator, Cook, First Mate
- Open a Level 1 Office — unlocks route assignments and passive income
- Reputation with Merchants Guild becomes meaningful (better prices)
- Threats become real: pirates target profitable routes

### Phase 3 — Fleet Owner (Late Game Entry)
- Own 3+ ships, each assigned a trade route
- Ships operate semi-autonomously (managed via Office)
- Invest in port infrastructure (warehouse, dock upgrades)
- Faction politics matter: Navy vs Pirates requires a stance
- Access to high-value luxury and military goods

### Phase 4 — Shipping Empire (Endgame)
- Dominant force in regional trade
- Fleet of 5+ ships covering all major routes
- Fully upgraded Office with trade route automation
- Significant faction influence
- Economy shapes around player's actions (Phase 2 economy system)

---

## Ship Types

| Type | Cost | Cargo | Crew Req. | Speed | Notes |
|------|------|-------|-----------|-------|-------|
| Rowboat | 80 | 40 | 1 | Fast | Starter fallback |
| Sloop | 280 | 150 | 2 | Fast | First real ship |
| Brigantine | 650 | 350 | 5 | Medium | Mid-game workhorse |
| Galleon | 1800 | 900 | 12 | Slow | Late-game hauler |
| Frigate | 2400 | 400 | 15 | Fast | Combat-capable |

---

## Threats & Conflict

All three threat types are active from mid-game onwards:

- **Pirates:** Roll chance on travel. Severity scales with cargo value and route danger rating. Player can fight, flee, or pay toll (reputation cost with pirates).
- **Rival merchants:** NPC traders compete for the same routes. Can undercut prices at ports. Future: can be bribed or driven out.
- **Weather:** Storms during travel. Damage ships, delay arrival, spoil food cargo. Reduced by Navigator crew skill.
- **Debt:** If player takes a loan (Phase 2 feature), interest accrues. Missing payments tanks Merchants Guild reputation.

---

## Factions

| Faction | How to Gain Rep | Effect of High Rep |
|---------|----------------|-------------------|
| Merchants Guild | Complete trade contracts, pay dues | Better buy/sell prices, access to exclusive goods |
| Royal Navy | Report pirates, pay port taxes | Safe passage in navy waters, no inspection stops |
| Pirates | Pay tolls, smuggle goods | Safe passage in pirate waters, access to black market |
| Port Locals | Help NPC quests, donate to port | Cheaper docking fees, NPC discounts |

Factions are in tension. Gaining Navy rep loses Pirate rep and vice versa.

---

## Coding Conventions

- **GDScript only** — no C#
- **Godot 4 API** — use `CharacterBody2D`, `Node`, `Resource`, etc. (not Godot 3 equivalents)
- **Signals over direct calls** — child nodes signal upward, never call parent methods directly
- **Autoloads for global state** — never store player data in scene scripts
- **Snake_case** for variables and functions, **PascalCase** for classes and scene names
- **Constants in ALL_CAPS** at the top of each script
- **Comments** on all public methods explaining purpose and parameters
- Each system should be independently testable — avoid tight coupling between scenes

---

## Development Phases

### Phase 1 (Current) — Core Loop Prototype
- [ ] `GameData.gd` autoload with player state and save/load
- [ ] `EconomyManager.gd` with fixed price table
- [ ] `WorldMap.tscn` with WASD player and 3 port nodes
- [ ] `Port.tscn` with E-to-enter and basic market UI
- [ ] `TradeUI.tscn` — buy/sell screen
- [ ] `PlayerHUD.tscn` — coins and inventory display

### Phase 2 — Fleet & Crew
- [ ] Ship purchase flow in Dockyard
- [ ] `FleetManager.tscn` and fleet data in GameData
- [ ] Crew hiring and wage system
- [ ] Travel events via `EventManager.gd`

### Phase 3 — Factions & Threats
- [ ] `FactionManager.gd` with reputation tracking
- [ ] Pirate encounter system
- [ ] NPC dialogue with faction-aware options
- [ ] Office scene and route management

### Phase 4 — Economy & Polish
- [ ] Supply/demand economy (replace fixed prices)
- [ ] Weather system
- [ ] Ship combat (basic)
- [ ] Save/load UI

---

## Recommended First Prompt for Cursor

```
Read project_context.md. 

Start Phase 1 by creating two autoload singletons:

1. GameData.gd — stores player coins (int, default 50), inventory (Array of 
   Dictionaries with keys "id" and "qty"), reputation (float), fleet (Array), 
   crew (Array), and office_level (int). Include save() and load() methods 
   using Godot 4 FileAccess writing to "user://savegame.json".

2. EconomyManager.gd — stores a goods catalogue (Dictionary) and a port price 
   table (Dictionary of Dictionaries). Include get_buy_price(port_id, good_id) 
   and get_sell_price(port_id, good_id) methods. Populate with the 8 trade goods 
   from project_context.md and at least 3 ports with varied prices.

Follow all coding conventions in project_context.md.
```
