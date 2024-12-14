# !!! Before reading this file !!!
To read this file the intended way, open this file using Visual Studio Code (VSCode) and type CTRL+K, then V.  
It will open the preview of this file.  
You can also read it on the official GitLab repository of PSDK.
Enjoy your reading!
# Best Practices for Developing AI for PSDK Battles
A few contributors had a voice chat about this topic and decided to define some best practices for developing AI for the battle system in PSDK.  
Here we are! ✨  

The goal of this guide is to ensure that the Pokémon SDK AI remains simple, effective, and capable of meeting user needs while being **easy to maintain**.  
It is crucial to follow these principles to avoid overly complex AI that is hard to adjust or too powerful, thus ensuring a better gaming experience.  
Keep in mind that the average fangame player is a casual gamer, and strategic players are not the target audience.
## Prioritize Heuristics for Moves
Focus your efforts on developing heuristics for moves before introducing overly complex features.  
This will simplify the organization and improve the AI's responsiveness.   
> The most relevant work is the one that is the most efficient with the least amount of code.
## Solve Before Adding Complexity
**Heuristics should solve basic problems and bring consistency to the AI's behavior.**  
More complex mechanisms should only be added once the existing system is effective.
## Simplicity First
Keep the AI simple and based on basic assumptions, without creating overly complex mechanisms.  
This will help avoid overloading the system and prevent unwanted side effects.
## Use Plugins for Controversial Mechanics
Whenever you think of adding an improvement to the PSDK AI that makes it behave more like a strategic player, ask yourself: "Will players actually enjoy facing this kind of difficulty?"
If the answer is not or unclear, you should consider offering it as a plugin, which means it should be placed at the bottom of your priority list.
## Keep the Player Experience in Mind
The AI should not have access to more information than a player would.   
Ensure that AI decisions remain fair and do not feel arbitrary or overly punishing.  
The goal is to enhance the player’s enjoyment and provide a meaningful challenge.
## Integrate a Degree of Randomness (RNG)
To avoid making the AI too predictable or overly powerful, introduce a degree of randomness in its decisions (RNG).  
Deterministic calculations (also called Magic Numbers) should be avoided to maintain an element of unpredictability.  
The lower the AI level, the more randomness it should have, while a high-level AI can be more "confident" in its choices.  
For example, you can use code like this in `compute(move, user, target, ai)` methods: `heuristic *= ai.scene.logic.move_damage_rng.rand(0.15..0.5)`, which multiplies the heuristic by a random number between `0.15` and `0.5`.
### Favor Progressive or Regressive Calculations
Similarly, use algorithms with progressive or regressive values to avoid extreme results (like 0.0 or 1.0), which would make the AI too predictable.
## Optimization of Trainer Switches
Improving heuristics related to moves will also enhance the decision-making for Pokémon switches during battles, increasing the AI's fluidity at higher levels.  
In fact, the calculation that decides a switch takes into account the effectiveness of the trainer’s team members who are not currently in battle, to determine if another Pokémon is better suited to face the player's Pokémon.  

By following these practices, you will ensure an AI that is accessible, efficient, and tailored to player needs, while remaining easy to modify and improve over time.  
The more complexity we implement, the more time we'll spend adjusting values.  
Adopt the KISS design logic: [Keep It Stupid Simple](https://en.wikipedia.org/wiki/KISS_principle).
