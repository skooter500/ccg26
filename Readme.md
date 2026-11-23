![COGITO_banner](addons/cogito/COGITO_banner.jpg)
# COGITO
[![GodotEngine](https://img.shields.io/badge/Godot_4.6.3_stable-blue?logo=godotengine&logoColor=white)](https://godotengine.org/) [![COGITO](https://img.shields.io/badge/version_1.2.0-35A1D7?label=COGITO&labelColor=0E887A)](https://codeberg.org/Phazorknight/Cogito)

## What is it?
Cogito is a First Person Immersive Sim Template Project for Godot 4, providing a framework for creating interactable objects, various items to use and mechanics to influence the player and game environment.
In short, with COGITO you get a quick start for a fully-featured first person game with a great variety of mechanics and a solid base to create your own.

### [Online documentation + Tutorials](https://codeberg.org/Phazorknight/Cogito/wiki)
### [Cogito Community Space](https://community.thresholdanomaly.com/index.php?r=space%2Fspace&cguid=f29b9340-dc21-4a3c-8883-7e33bb804c27)
### [Cogito in the Godot Asset Store](https://store.godotengine.org/asset/philip-drobar/cogito/)

### Current Features
- First person player controller (simple OR state-based):
  - Sprinting, jumping, crouching, sliding, stairs handling, ladder handling, sitting, swimming
  - Lots of exposed properties to tweak to your liking (speeds, headbob, fall damage, bunnyhop, etc.)
  - Easy-to-use dynamic footstep sound system
- Player Attribute System
  - Health, Stamina, Visibility for stealth, etc
  - Customize how attributes get displayed in the HUD (or stay hidden)
  - Also useable for RPG-like attributes (Strength, Wisdom, etc)
  - Interactions can check attributes (eg. you can only lift a box if you're strong enough)
- Interaction System
  - Component-based interactions makes it easy to turn your own objects interactive quickly and customize existing ones
  - Examples for interactive objects like doors, drawers, boxes to carry, turn-wheels, elevators, notes, keypads
- Inventory System
  - Flexible resource-based inventories
  - Grid-based (think Resident Evil 4)
  - Inventory UI separate from inventory logic
  - Examples for multiple item types (consumables, keys, ammo, weapons, combinable Items)
  - Base class to easily add your custom item types
  - Containers with their own inventories
- Cogito NPC
  - NavigationAgent based general purpose NPC with state machine + animation states
  - Player detection system based on line-of-sight + simulated hearing.
- Main menu, pause menu and Options menu
- Rebindable controls
- Basic Quest System
- Save and Load System as well as scene persistency
- Full game pad support!
- Localization!
- Support for other plugins:
  - Works with Dialogic
  - Works with Dialgue Manager
- Work in progress:
  - Systemic Properties (wet/dry, flammable/on fire, soft, etc) (very WIP)

### Comes with fully featured Demo Scenes
- Set up like a game level including a variety of objects, weapons and quests
- Demo scenes contains hints that explain how objects in the scene were set up

COGITO is made by [Philip Drobar](https://www.philipdrobar.com) with help from [these contributors](https://codeberg.org/Phazorknight/Cogito/wiki/Credits%2C-Contributors%2C-License).

## Principles of this template
The structure of this template always tries to adhere to the following principles:
- **Complete**: When you download COGITO and press play, you get a functioning project out of the box. Game menu, save slot select, options and a playable level are all included.
- **Versatile**: Whether your game is set in the future, the past or the present, use melee, projectile or no weapons at all, have low poly, stylized or realistic graphics, the template will have features for you.
- **Modular**: Do not want to use a feature? You will be able to hide it, ignore it or strip it out without breaking COGITO. At the same time, COGITO is designed to be extendable with your own custom features or other add-ons.
- **Approachable**: While there will always be a learning curve, we strive to make COGTIO approachable and intuitive to use, so it doesn't get in your way of making your game.
- **No Generative AI**: All included code and assets are made by humans and listed in our credits and cotnributors page.

> [!IMPORTANT]  
> COGITO v1.2 is not 100% bug-free. While most features are set, be aware that this open source software is offered "as is". Use at your own risk and check Issues and Discussion pages for more information.

[Credits, Contributors and License](https://codeberg.org/Phazorknight/Cogito/wiki/Credits%2C-Contributors%2C-License)
