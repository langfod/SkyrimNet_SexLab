#! /usr/bin/env python3
import json
import os
import sys
import re

if len(sys.argv) < 2:
  print ("sys.argv[0] anim_dir")
  exit()

class Actor:
  def __init__(self, name):
    self.name = name

class Animation:
  def __init__(self, anim):
    self.anim = anim
    self.tags = [tag.lower() for tag in anim['tags'].split(",")]

  def toDict(self):
    return self.anim

  def has_tag(self,tag):
    return tag.lower() in self.tags


def main():
    group_tag = {
        "bondage": ["bound", "yoke","armbinder","bondage", "rope", "chains", "cuffs", "collar",
                    "hogtied"],
        "tools": ["dildo", "vibrator", "strapon", "cockring", "buttplug", "gag", "blindfold",
            "whip","crop","balljob","magic","staff","chastitybelt"],
        "furniture": ["table", "lowtable","chair", "cage", "gallows",
                    "rack", "stockade", "pillory", "horse", "enchantingwb",
                    "alchemywb", "fuckmachine", "woodenpony", "necrochair",
                    "dwemerchair", "throne", "torturerack","javtable",
                    "xcross","tiltedwheel", "wheel","coffin", "floating", "tentacles"],
        "positions": ["69", "cowgirl", "missionary", "kneeling", "doggy",
                    "sitting", "standing", "behind","floating","spitroast","side","sideways",
                    "holding","vreversecowgirl""gloryhole","facesit","matingpress", "reversecowgirl"],
        "actions": ["anal", "assjob", "boobjob", "thighjob", "vaginal",
                "fisting", "oral", "blowjob", "cunnilingus", "spanking","slapping",
                "masturbation", "fingering", "footjob", "handjob",
                "kissing", "headpat", "hugging", "dildo","pussyslap","milking"],
        "styles": ["aggressive", "rough", "loving", "dirty","necro","lesdom",'denial'],
        "genders": ["f","m","mf","ff", "mm", "futa", "mmf","mff", "fmm", "mfm", "fmmf","mmmf","mmmmf"],
        "authors": ["funnybizness", "babo","billy","nelson"],
        "ignored": ["sex", "gangbang", "group", "creature", "bestiality",
                    "creaturefucking", "creaturefucked", "creaturefucker",
                    "creaturefuckingm", "creaturefuckedm", "creaturefuckerf",
                    "creaturefuckingf", "creaturefuckedf", "creaturefucker",
                    "defeat","bound","object","deviousdivice","orgy","fbbound",
                    "creampie","cuminmouth","furniture","laying","facial","aircum",
                    "animobject","gallowsstrappedo","furotub","gallowsupsidedown",
                    "deviousdevice","","analcreampie","dp","feetfish","grinding",
                    "gallowswoodenhorse","dd","obedient","chestcum",
                    "movingdick","deniel","feetfetish","uc"]

    }
    synyonyms = {
        "cuffs": ["cuffed","wrists"],
        "oral": ["blowjob", "cunnilingus","cunnullingus","cunullingus"],
        "aggressive": ["rape", "domsub","assault","forced","defeated","defeat","conquering",
                 "aggressivedefault","fbrape"],
        "masturbation": ["masurbation","solo"],
        "ff":["lesbian"],
        "mf":["straight"],
        "billy": ["billyy"],
        "doggy": ["doggystyle"],
        "necro": ["snuff"],
        "wheel": ["titledwheel"],
        "xcross": ["xcrossreverse"],
        "denial": ["noclimax","chastity"]
    }

    tag_group = {
        "_order":["actions","positions","tools","styles","bondage","furniture","authors"]
    }
    for group, tags in group_tag.items():
        if group not in tag_group["_order"] and group != "ignored":
            tag_group["_order"].append(group)
        for tag in tags:
            tag_group[tag] = group
    for syn, tags in synyonyms.items():
        group = tag_group.get(syn, None)
        if group is None:
            print ("Warning: no group for synonym", syn, file=sys.stderr)
            exit(1)
        for tag in tags:
            tag_group[tag] = group

    files = files_find(sys.argv[1])
    for file in files:
        anims = parse_json_file(file)
        for anim in anims:
            #if anim.has_tag('creature'):
                #creatures.add(anim.tags[1])
            #continue
            if anim.has_tag('bound'):
                missing = set()
                for tag in anim.tags: 
                    if tag not in tag_group:
                        missing.add(tag)
                if len(missing) > 0:
                    print ("Missing tags:", missing, file=sys.stderr)

    ignored = []
    for tag,group in tag_group.items():
        if group == "ignored":
            ignored.append(tag)
    for tag in ignored:
        del tag_group[tag]
    
    print ("creaing file",file=sys.stderr)
    print (json.dumps(tag_group, indent=2, ensure_ascii=False))

def tags_load(fname):
    with open (fname,"r", encoding="utf-8") as f:
        return json.load(f)
    
def files_find(anim_dir):
    print ("searching directory",anim_dir,file=sys.stderr)
    files = [] 
    for root, dirs, fs in os.walk(anim_dir):
        for f in fs:
            if f.endswith(".json"):
                files.append(os.path.join(root, f))
    return files

def describe_animation(anim, dom_name, sub_name, actors):

    if anim.has_tag("aggressive"):
        buffer = f"{dom_name} is sexually assaulting {sub_name}. "
    else:
      buffer = ""
    buffer += f"{sub_name} is"

    if anim.has_tag('bound'):
       buffer += " bound"
    else:
        return 

    if anim.has_tag("rough"):
      buffer += " roughly"
    elif anim.has_tag("loving"):
      buffer += " lovingly"

    if anim.has_tag("bestiality"):
      buffer += " bestaility "

    positions = ["69", "cowgirl", "missionary", "kneeling","doggy","sitting","standing"]
    i = 0
    found = False
    while i < len(positions) and not found:
        if anim.has_tag(positions[i]):
            buffer += ", "+positions[i]+" position,"
            found = True
        i += 1

    if anim.has_tag("behind"):
       buffer += " from behind"

    on_furniture = ["Table", "LowTable",
        "JavTable", "Pole", "wall", "horse",
        "Pillory", "PilloryLow", "Cage",
        "Haybale", "Xcross", "WoodenPony",
        "EnchantingWB", "AlchemyWB", "FuckMachine",
        "chair", "wheel", "DwemerChair", "NecroChair",
        "Throne", "Stockade", "TortureRack",
        "Rack"
    ]

    i = 0
    found = False
    while i < len(on_furniture):
        if anim.has_tag(on_furniture[i]):
            buffer += " on a "+on_furniture[i]
            found = True
        i += 1
    if anim.has_tag("Cage"):
       buffer += " in a cage"
    elif anim.has_tag("Gallows"):
       buffer += " in a gallows"
    elif anim.has_tag("coffin"):
       buffer += " in a coffin"
    elif anim.has_tag("floating"):
       buffer += " floating in air"
    elif anim.has_tag("tentacles"):
       buffer += " with tentacles"
    elif anim.has_tag("gloryhole") or anim.has_tag("gloryholem"):
       buffer += " through a gloryhole"
    elif not found and anim.has_tag("Furniture"):
       print ("miss furniture")

    if anim.has_tag("anal"):
        buffer += " having anal sex with"
    elif anim.has_tag("assjob"):
        buffer += " having a assjob by"
    elif anim.has_tag("boobjob"):
        buffer += " giving a blowjob to"
    elif anim.has_tag("thighjob"):
        buffer += " giving a thighjob to"
    elif anim.has_tag("vaginal"):
        buffer += " having vaginal sex with"
    elif anim.has_tag("fisting"):
        buffer += " having having her pussy fisted by"
    elif anim.has_tag("oral") or anim.has_tag("blowjob") or anim.has_tag("Cunnilingus"):
        buffer += " giving a blowjob to"
    elif anim.has_tag("spanking"):
        buffer += " being spanked by"
    elif anim.has_tag("masturbation"):
        buffer += " masturbating furiously"
    elif anim.has_tag("fingering"):
        buffer += " being fingered by"
    elif anim.has_tag("footjob"):
        buffer += " giving a footjob to"
    elif anim.has_tag("handjob"):
        buffer += " giving a handjob to"
    elif anim.has_tag("kissing"):
        buffer += " kissing with"
    elif anim.has_tag("headpat"):
        buffer += " having head patted by"
    elif anim.has_tag("hugging"):
        buffer += " hugging"
    elif anim.has_tag("dildo"):
        buffer += " using a dildo"
        if len(actors) > 1:
           buffer += " with"
    else:
        buffer += " having sex with"
        print ("no match!!!!!!!!!!!!!!")

    if len(actors) > 1:
        buffer += f" {dom_name}"
    buffer += "."

    return buffer

def parse_json_file(filepath):
    anims =[] 
    with open(filepath) as f:
      data = json.load(f)
      for anim in data['animations']:
         anims.append(Animation(anim))
    return anims 

def parse_animation_file(filepath):
    animations = []
    print (filepath)
    with open(filepath, "r") as f:
        lines = f.readlines()
    current_anim = {}
    for line in lines:
        #print (line.rstrip())
        line = line.strip()
        if line.startswith("Animation("):
            current_anim = {}
        elif line.startswith("id="):
            current_anim["id"] = line.split("=", 1)[1].strip().strip('",')
        elif line.startswith("name="):
            current_anim["name"] = line.split("=", 1)[1].strip().strip('",')
        elif line.startswith("tags="):
            current_anim["tags"] = line.split("=", 1)[1].strip().strip('",')
        # Parse Female(add_cum=...)
        elif line.startswith("actor1=Female("):
            match = re.search(r'add_cum=([A-Za-z]+)', line)
            if match:
                current_anim["actor1_add_cum"] = match.group(1)
            else:
                current_anim["actor1_add_cum"] = None
        elif line.startswith(")"):
            if current_anim:
                animations.append(Animation(current_anim))
    return animations

main()