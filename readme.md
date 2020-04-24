# Mule

Mule is an addon for [Windower](http://www.windower.net/) that eases targeting woes when controlling more than one character. 
Issue commands from one character and have them executed on another, all while being able to define a target without needing to switch characters. This functions similarly to the Send command already in use amongst the player base, however it extends on this functionality to allow users to dynamically send targets to other characters as well.

## Installation

To install Mule, simply create a folder in the Windower addons directory and drop the `mule.lua` file into the folder. Load the LUA file on all applicable characters and you're good to go! No configuration is needed, you'll be able to issue commands right away.

## Usage

Using Mule is super simple. Similar to Send, Mule allows you to issue commands to other characters. Since this was intended as more of a personal project at the current moment, Mule only allows for common commands to be issued to characters. The type of command being sent is determined by the declaration. Let's break down some commands and give an example.

### Command Structure

A command is issued with a set structure in mind. This structure is as follows

```
mule {declaration} {character} {action} {?target}
```

An example of a full command would be

```
mule cast MyAltCharacter 'Fire V' <t>
```

#### Declaration

The declaration is the type of command being sent. At the moment valid declarations are `cast`, `ability`, and `item`. I feel as though these are pretty self explanatory, but I'll break them down anyway.

* `Cast` - Casts magic from the target character. Any magic I guess. I haven't tested every single magic in the game, but it works for everything I have used.
* `Ability` - Uses a job ability on the target character.
* `Item` - Uses an item on the target character. 

#### Character

This is the character you would like to issue the command on. Valid entries include the character name, as well as `@ALL`, `@OTHERS`, and `@{JOB}`. This should be familiar if you've ever used Send.

#### Action

This is the action you would like the target character to perform, be it a job ability, a magic spell, or an item. It is important to note that ***the action must be contained within SINGLE quotes***, rather than DOUBLE quotes. This is due to issues with how LUA (or I guess programming in general) and FFXI handle spaces and quotes. 

I could work in logic to sanitize input to work with either, but I feel like it's easier to just add single quotes as a good practice anyway. I also don't know LUA that well, and am lazy, so there's that.

#### Target

This is actual an optional parameter. It is performed in the context of the character receiving the command (the alt), and accepts the standard FFXI targeting options. So things like `<t>`, `<me>`, and `<bt>` will work. Built in FFXI commands such as `<st>`, `<stpc>`, `<stnpc>` and such will not work as they will cause the target character to perform these commands, negating the whole point of this addon.

If a target is **NOT** defined, it will default to `<t>`.

### Dynamic Targeting

This is the meat of the addon and is why it was built it in the first place. Targeting on multiple characters is a pain, there's no way around that. To ease this, Mule allows you to specify a target from the context of the main character prior to issuing a command.

Say we want to cast magic on a specific target. Through traditional means, we would use something like `<bt>` to handle this. While this is great and works well for a lot of cases, this requires the main character to be engaged with the target in order to work properly. There's also the option of simply sending a `/assist` command to the secondary characters. Using the assist option poses similar problems however, as it requires the main character to be actively targeting something.

What if we want to be engaged to one mob, and be able to sleep a different one without switching targets? What if we want to buff multiple party members without having to specify a macro for each target? This can be accomplished by simply issuing a `/target` command on the main character prior to sending a command through Mule. Lets look at an example.

Here's what a traditional macro would look like to cast haste on a character using Mule.

```
/con mule cast MyAltCharacter 'Haste II' MyMainCharacter
```

This works to buff one single player. What if we want to buff a different character? Simply `/target` them before the command.

```
/target <stpc>
/con mule cast MyAltCharacter 'Haste II'
```

Note that we omit the target in the actual command as the target will be derived from the main character on the previous line.

This can be done for enemies as well.

```
/target <stnpc>
/con mule cast MyAltCharacter 'Geo-Frailty'
```

## Considerations

Due to the way the targeting system works in FFXI, when targeting an enemy, there will be a brief period where the recipient character will lock on to the enemy. There is no workaround for this that I have found aside from issuing a delay and forcing the character to unlock from the target. Delay may need to be adjusted for lag in some cases. It should work fine for most things at the moment though.

Issuing a command will stop the recipient character from following a target. This was done to ensure that magic would cast without being interrupted, and so that the character would not start running aimlessly into the target.