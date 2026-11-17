# Brainrot Bazaar

![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)
![Rank](https://make.fun/badge/roblox-brainrot-01/khan7271/brainrot-bazaar/rank.svg)
![Reward](https://make.fun/badge/roblox-brainrot-01/khan7271/brainrot-bazaar/reward.svg)

**Brainrot Bazaar** is a 3D Roblox brainrot game for make.fun's roblox-brainrot-01 bounty: a central plaza with a conveyor belt carrying absurd meme-born characters past eight player bases. Buy them, park them on your base, and watch the cash tick up every second — while rival thieves sneak in to steal them and a Tsunami of Sauce sweeps the map on a timer.

## How to play

- **Buy brainrots** — click any character rolling along the conveyor belt. Each one earns $/sec on your base.
- **Climb the rarity ladder** — Common, Rare, Epic, Legendary, Mythic, Brainrot God. Mutations (Golden x2, Diamond x5, Rainbow x10) multiply earnings.
- **The cast** — Croissant Captain, Banana Phone, DJ Toast, Pickle Professor, Noodle Ninja, Cheddar Chairman, Llama Latte and the Baguette Baron.
- **Defend your base** — slap thieves away with E (or the SLAP! button), or buy a Base Lock in the shop.
- **Outrun the Tsunami of Sauce** — when the warning sounds, dash back to your base safe zone or get swept to spawn and drop 10% of your cash.
- **Rebirth** — at $1,000,000 Cash, rebirth for a permanent +25% earnings multiplier and a golden crown.
- **Shop** — Slap Power, Speed Boost, Lucky Charm and Base Lock. Leaderboards track top Cash and Rebirths.

## How it is built

The whole 3D world is built procedurally in Luau at runtime: `src/server/WorldBuilder.luau` creates the baseplate, plaza, fountain, conveyor belt, eight base plots, lamps, trees, clouds and the sauce river from code — no hand-placed Studio parts. `src/server/` holds one service per job (conveyor, bases, thieves, tsunami, shop, slap, leaderboard, player data); `src/shared/` holds the character data, game config and money formatting; `src/client/` builds the HUD ScreenGui and wires the shop, slap and rebirth buttons.

Build the place with Rojo:

    rojo build default.project.json --output game.rbxl

Hand it in (the grader's way):

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with the vendored make.fun library. `PLAY.json` names the published place — fill it in once the game is published on Roblox.
