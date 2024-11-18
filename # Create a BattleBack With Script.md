# !!! Before reading this file !!!

To read this file the intended way, open this file using Visual Studio Code (VSCode) and type CTRL+K, then V. It will open the preview of this file.

You can also read it on the official GitLab repository of PSDK.

Enjoy your reading!

# Create BattleBack with Script

In this tutorial, we will explain how to create Battle Backgrounds with the Dynamic Camera.

## Prerequisites
To use this feature, you need to set to true the following constant:
`Battle::BATTLE_CAMERA_3D`
With This constant set to true, you will switch the classic Visual Battle to the 3D one and then the BattleBacks will need to be created with a script.


For the rest of this tutorial, we will take `01600 Alpha 25 Battle Engine\00001 Battle_Scene\00001 BattleUI\00700 BattleBack Forest.rb` as a base.

Please make sure you know how to monkey-patch/add a script to PSDK before following this tutorial. If you're not sure, refer to this video: `https://www.youtube.com/watch?v=CQphy2qzfV0`

## Graphics Resources
You need to put your Graphical Resources into the BattleBacks folder of your project. I choose for the BattleBack of this tutorial to put the resources into `battlebacks/animated_camera/BattleBack Forest`
I suggest you use 1 subfolder per battleback (it will be useful in the future of your project, once you have several dozen BattleBacks)

## Create a new BattleBack
First, you need to create a class that inherits from `BattleUI::BattleBack3D`
Once it's done, you need to create a initialize method like such:
```ruby
  def initialize(viewport, scene)
    super
  end
```
It's not mandatory, but it will allow you to add methods to the `initialize` if you need to.

## Add elements to your BattleBack
Modify the method `resource_path` with the relative path to the folder with your battleback resources (by default it's "animated_camera/") check `00700 BattleBack Forest.rb` to know how to change it.
Then create your method create_graphics, and inside it, add your elements to the BattleBack.
You need to use the method `add_battleback_element` (you can check its docstring for the args).
I suggest you store all your sprites into a class variable (cf. create_graphics)

## Add animations to your BattleBack
Add a `Yuki::Animation::TimedAnimation` to `@animations` and it will be automatically updated. Use the method `create_animations` for that. No need to stat your animations by yourself, this is done automatically by the `battleBack3D` class.
You can check, for example, how the clouds movement is done in `00700 BattleBack Forest.rb`.
If you don't know how to use the animations, check this files : `pokemonsdk\# Yuki Animation.md`

## Add you background to the system
Once everything is settled, you should monkey-patch (or submit your PSDK with a Merge request) the method `create_background` of `Battle::Visual3D` you should proceed as following:
```ruby
  def create_background
    case background_name
    when "back_grass"
      @background = BattleUI::BattleBackGrass.new(viewport, @scene)
    when "name_of the BattleBack used by PSDK here"
      @background = BattleUI::NameOfYourClass.new(viewport, @scene) # Change the class name by yours
    else
      @background = BattleUI::BattleBackGrass.new(viewport, @scene)
    end
  end
```
You can add as many cases as you what/which if you don't know how is handled background_name, check the next section

## Know which name to choose for your BattleBack matching (Optional)
By default PSDK handles these BattleBacks:
- back_building (default one if no condition triggers the activation of another BattleBack)
- back_grass
- back_tall_grass
- back_taller_grass
- back_cave
- back_mount
- back_sand
- back_pond
- back_sea
- back_under_water
- back_ice
- back_snow

If you are not sure you can check the constant `Battle::Logic::BattleInfo::BACKGROUND_NAMES`

If you want to create a "custom" BattleBack (for example a specific battle against a trainer or a Legendary), you need to modify it manually with the RPG Maker XP command before the battle, once it's selected create a case with the name of the image selected:
If you choose: `battleback legendary arceus.png` as a BattleBack, then if you want the you need to add a case in the method above as follow:
```ruby
def create_background
  ...
  case background_name
  ...
  when "battleback legendary arceus"
    @background = BattleUI::NameOfYourClass.new(viewport, @scene) # Change the class name by the one corresponding
  end
end
```

## What is implemented and not
The function `add_battleback_element` will automatically use a sprite according to its name extension.
Example: If you want to display a different sprite between daytime and night, you just need to add them into the right folder (`sprite1_day.png` and `sprite1_night.png` for example), then just use `add_battleback_element(@path, sprite1)` and the function will display the right sprite according to the moment the battle starts.
For the moment, .gif are not handled at the moment (you're free to add it to `add_battleback_element`).