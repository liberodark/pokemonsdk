# Pokémon SDK

`PSDK` is a Starter Kit allowing to create Pokémon Games using various tools like Tiled Map Editor, RPG Maker XP & Pokémon Studio as a data base editor.

[![Discord](https://img.shields.io/discord/143824995867557888.svg?logo=discord&colorB=728ADA&label=Discord)](https://discord.gg/0noB0gBDd91B8pMk)
[![Twitter PSDK](https://img.shields.io/twitter/follow/PokemonSDK?label=Twitter%20PSDK&logoColor=%23333333&style=social)](https://twitter.com/PokemonSDK)
[![Twitter PW](https://img.shields.io/twitter/follow/PokemonWorkshop?label=Twitter%20PW&logoColor=%23333333&style=social)](https://twitter.com/PokemonWorkshop)

## Generic Links

[Downloads](https://download.psdk.pokemonworkshop.com/)
| [Event Making Tutorial](https://pokemonworkshop.com/en/help/event-making-in-rmxp/)
| [Help](https://pokemonworkshop.com/en/help)
| [LiteRGSS Documentation](https://psdk.pokemonworkshop.fr/yard/LiteRGSS.html)

## How to Install

When you create a new project using [Pokémon Studio](https://github.com/PokemonWorkshop/PokemonStudio/releases), PSDK is automatically installed on your PC in the following folder:
`appdata\local\programs\pokemon-studio\resources\psdk-binaries\pokemonsdk`.

The application offers a dedicated page to keep it up to date.

### Use your own PSDK codebase

> ⚠️ Recommended for advanced users only.

If you prefer to use your own PSDK codebase to manage versioning more precisely, you can create a submodule at the root of your project folder.

If PSDK detects a `pokemonsdk` folder at the root of your project, it will load from that directory instead.

## Specifications

Contrary to `PSP` or `Essentials`, `PSDK` doesn't use the RGSS. We wrote a graphic engine called `LiteRGSS` using `SFML`, which allows a better mastering of the Graphic part of PSDK like adding Shaders, turning some graphic process to C++ side etc.

* Game Engine: `LiteRGSS2` (under `Ruby 3.0.1`)
* Default screen size: `320x240` (upscaled to `640x480`)
* Sound: [FMOD](http://www.fmod.org/) (Support: Midi, WMA, MP3, OGG, MOD, WAVE)
* Map Editor:
    * [Tiled](https://www.mapeditor.org/)
* Event Editor:
    * `RPG Maker XP`
* Database Editor:
    * [Pokémon Studio](https://github.com/PokemonWorkshop/PokemonStudio/releases)
* Dependencies : `SFML`, `LodePNG`, `libnsgif`, `FMOD`, `OpenGL`, `sfeMovie`, `ffmpeg`

## PSDK Features
### System Features

- [Time & Tint System](https://psdk.pokemonworkshop.fr/wiki/en/event_making/time-system.html) (using virtual or real clock)
- Particle System (display animation on characters according to the terrain without using RMXP animations)
- [FollowMe](https://psdk.pokemonworkshop.fr/wiki/en/event_making/followme.html) (also known as Following Pokémon)
- [Quests](https://psdk.pokemonworkshop.fr/wiki/en/ruby_host/quest.html)
- Double Battles
- Running shoes
- Key Binding UI (F1)
- Multi-DayCare
- Berry System
- GTS

### Mapping & Event Making Features

- Shadow under events system (also known as Overworld Shadows)
- Extended event info (using the event name)  
    This feature allow the maker to specify various thing like the event graphics y offset, if the event display shadow or even if the event needs to display a sprite (optimization).
- SystemTags (Give more info about the terrain and allow specific interactions)
    - Wild info System Tags (+Particles) : Tall Grass, Cave, Sea/Ocean, Pond/River, Sand, Snow etc…
    - Mach Bike tiles (muddy slopes & cracked tiles)
    - Acro Bike tiles (white rails & bunny hop rocks)
    - Slopes (HGSS thing)
    - Stairs (4G+ stairs)
    - Bridges (With event support)
    - Ledges
    - Rapid water tiles (forcing direction) / Ice (sliding)
    - Wet sand (Water particle on player)
    - Headbutt
- Dialog / Text Database allowing easier translation for the game using CSV format
- Special Warp fades (5G out->in & 3G transition)
- Weathers : Rain, Harsh sunlight, Sandstorm, Snow, Fog
- Premade common events : Strength, Dig, Fly, DayCare Hosts, Berry Trees, Dowsing Machine, Head Butt, Cut, Rods, Rock Smash, WaterFall, Flash, Whirlpool, Rock Climb, Teleport, Defog

### Mini-Games
- Voltorb Flip
- Ruins of Alph puzzle
- Mining Game
- Slot Machines
