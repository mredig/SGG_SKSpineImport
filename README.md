SGG_SKSpineImport
=================


Forked from [SGG_SKSpineImport](https://github.com/mredig/SGG_SKSpineImport) by [mredig](https://github.com/mredig)

See [original branch](https://github.com/mredig/SGG_SKSpineImport) for full documentation


Added three methods:


## changeSkinPartial
*Accepts: (NSMutableDictionary *)slotsToReplace*

**Dictionary format:**
>node name : replacement texture

Replaces the texture of any nodes mentioned in the slotsToReplace dictionary with their accompanying textures. Creates an NSMutableDictionary in memory containing the original textures, to easily swap back.

Created to serve my own needs: I have an avatar builder in my Sprite Kit game, and I need to swap out specific slots without changing the whole skin (so the player can choose different shirts, pants etc.).

### Usage:

```
NSDictionary* partReplacement = @{@"torso": @"goblin-torso", @"head": @"goblin-head"};

[goblin changeSkinPartial:partReplacement];
```


### Limitations:
* Your dictionary's keys must match the slot names specified in the skeleton's .json file.
* If you need to replace any 'nested' nodes, you must create an entry for that slot in your dictionary.



## resetSkinPartial
Resets any changes made through changeSkinPartial; reverts the skeleton back to the textures used when the scene was created.
Should only be called after changeSkinPartial.


## colorizeSlots
*Accetps: (NSArray *)slotsToColorize withColor:(SKColor *)color andIntensity:(CGFloat)blendFactor*

Colorizes the slots listed in the slotsToColorize array using the specified color and blend factor.

Can be used to make a body part flash red, or to let the player change their hair/skin color.

### Usage:
```
NSArray* partsToColorize = @[@"head", @"left shoulder", @"torso"];
SKColor* color = [SKColor redColor];
[boy colorizeSlots:partsToColorize withColor:color andIntensity:1];
```

### Limitations:
* Your array's values must match the slot names specified in the skeleton's .json file.
* If you need to colorize any 'nested' nodes, you must create an entry for that slot in your dictionary.


## Questions or comments?
Let me know!