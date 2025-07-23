# SkyrimNet_SexLab

Adds SkyrimNet support to SexLab.

# Hot Key
There is an optional hot key, must be enabled in the MCM.  It supports: 
- ability to start a sexual act with an NPC in the crosshairs or between NPCs not in the crosshairs.
- add a per-stage description for the animation of the NPC in the crosshairs. 

## Per Stage Description 
When you press the hot key a one of two thing will happen:
- If the animation's stage already has a description, it will be presented with the option to replace it.
- If the animation's stage does not have a description, a text field will be presented to add it. 
  - After you finish typing, the code will add the actor's names and present the final description to you.  You can accept or reject. 

Descriptions you create will be stored in `SkyrimNet_SexLab/animations/\_local\_`with a single file for each animation. Additional stage descriptions will be stored in `animations/(author_name)` as they are shared with me, or people can simple give them to you.  The author's name will be presented when the description is provided, so you know where to edit the files. You can always create new description in \_local\_.

- Once the file exists, you can edit with your favorite editor if you so choose.
- If no stage descriptions is used, the tag based description will be used. 
- The last stage with a description will be used for those with out descriptions
- descriptions will be used in the order the directories are read, with \_local\_ loaded last.
- vesion 1 descriptions must take the form of:
    - Actor[0] "did something looking like something"
    - Actor[1] "did something to looking like something" actor[0] 

Examples can be found in the animations/GoodProvider sub directory.

`SkyrimNet_SexLab\animations\_local_\file.json
~~~
{
    "stage 1": {
        "description":"kisses with",
        "id":"stage 1",
        "version": "1.0"
    }
}
~~~

## 
Please send me any animations you create by zipping your \_local\_ directory and give me an authors name you would like to use.  I will also accept annoymous submissions.

- Send the zip file to me on discord
- email the zipped file to da.good.provider@gmail.com 

# Install 

**Requirements**
The following and depedancies:
- [Sexlab Framework](https://www.loverslab.com/files/category/228-sexlab-framework-se/)
- [Papyrus MessageBox](https://www.nexusmods.com/skyrimspecialedition/mods/83578)
- [OSL Aroused](https://www.nexusmods.com/skyrimspecialedition/mods/65454)
- [JContainers](https://www.nexusmods.com/skyrimspecialedition/mods/16495)
- [SkyUI SE](https://www.nexusmods.com/skyrimspecialedition/mods/12604)
  [UIExtensions](https://www.nexusmods.com/skyrimspecialedition/mods/17561)
- SkyrimNet
   - You must have narration enabled
- **SkyrimNet**
    - SkryimNet_SexLab (this mod) 
 

**Recommendations**
- **Utils**
    -  [SKSE](https://skse.silverlock.org/)
    -  [Address Library for SKSE Plugins](https://www.nexusmods.com/skyrimspecialedition/mods/32444)
    -  [Unofficial Skyrim Special Edition Patch - USSEP](https://www.nexusmods.com/skyrimspecialedition/mods/266)
    -  [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
    -  [Powerof three Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854)
    -  [Power of three Tweaks](https://www.nexusmods.com/skyrimspecialedition/mods/51073)
    -  [Alternate Start](https://www.nexusmods.com/skyrimspecialedition/mods/272) (nice, but not needed)
       - [Unofficial Skyrim Sepcial Edition Patch](https://www.nexusmods.com/skyrimspecialedition/mods/51073)
    -  [Stay At the System Page NG](https://www.nexusmods.com/skyrimspecialedition/mods/76927)
    -  [Papyrus MessageBox](https://www.nexusmods.com/skyrimspecialedition/mods/83578)
    -   SkyrimNet 
- **nude body (not required)**
    -   [Scholongs of Skyrim SE](https://www.loverslab.com/files/file/5355-schlongs-of-skyrim-se/)
    -   [Caliente's Beautiful Bodies Enhancer -CBBE-](https://www.nexusmods.com/skyrimspecialedition/mods/198) or BHUNP
- **SexLab**
    -  [Sexlab Framework](https://www.loverslab.com/files/category/228-sexlab-framework-se/)
    -  [SexLab Tools](https://www.loverslab.com/files/file/10660-sexlab-tools-for-se-patched/) (Allows you to change animations with 'h' hotkey)
- **Animation**
    -  [Pandora](https://www.nexusmods.com/skyrimspecialedition/mods/133232)
    -  Pandora Output (recommended to store Pandora's output)
    -  [XP32 Maximum Skeleton Special Extended (XPMSSE)](https://www.nexusmods.com/skyrimspecialedition/mods/1988)
    -   [SL Animation Loader](https://www.loverslab.com/files/file/5328-sexlab-animation-loader-sse/)
- **animations** (you might be able to get away with less ... )
    -   [Billyy](https://www.loverslab.com/files/file/3999-billyys-slal-animations-2025-1-1/)


