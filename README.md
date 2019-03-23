# PSDK
This engine allows you to make 2D `P*k*mon` games running on Computer devices.

## What engine PSDK use ?

PSDK use the [LiteRGSS](https://github.com/NuriYuri/LiteRGSS) to display the game & [FMOD](https://fmod.com) to process the audio files.

You can find a documentation of the `LiteRGSS` here : [LiteRGSS documentation](https://psdk.pokemonworkshop.fr/litergss/).

## How to edit a PSDK project ?

Currently, you use two or three tools to edit a PSDK project : 
- [RPG Maker XP](http://www.rpgmakerweb.com/products/programs/rpg-maker-xp) : to edit the event and eventually the maps
- [Tiled](https://www.mapeditor.org) : To make the maps with more freedom (you'll need [Tile2RXDATA](https://pokemonworkshop.fr/forum/index.php?topic=4588.0#post_english) to load the map in RMXP)
- **RubyHost** : to edti the database.

## How to download PSDK ?

To download PSDK you should join the [Pokémon Workshop Discord](https://discord.gg/0noB0gBDd91B8pMk) and ask the access in **#access_psdk** then download the right archive in the **Téléchargements-PSDK** category.

## Technical informations

- Framerate : 60FPS
- Default screen resolution : 320x240
- Supported OS : Windows, Debian-like OS.
- Ruby version : 2.5.0 (on Windows)
- Supported Ruby feature :

    - Socket, net/HTTP, net/HTTPS
    - OpenSSL
    - Json, YAML
    - Thread, Fiber, Mutex
    - Gems (using `Game gem <arguments>`)
    - Bundle (using `Game bundle <arguments>`)