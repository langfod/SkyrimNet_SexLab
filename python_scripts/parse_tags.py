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
  files = files_find(sys.argv[1])
          "Sexlab Skyrimnet/creature-descriptions.json", 
  creatures = set() 
  for file in files:
    anims = parse_animation_file(file)
    for anim in anims:
        if anim.has_tag('creature'):
            creatures.add(anim.tags[1])
        continue
        print (json.dumps(anim.toDict()['tags'],indent=4))
        print (describe_animation(anim, "snake","nina", \
            [Actor("Nina"),Actor("Snake")]))
        print ("\n")
  print ("Please provide a single sentence description of the physical look, physical feel, and emotioanl response a normal human would have of intimate contact with these skyrim creatrures:")
  for creature in creatures:
     print (creature)


def tags_load(fname):
    with open (fname,"r", encoding="utf-8") as f:
        return json.load(f)
    
def files_find(anim_dir):
    files = [] 
    for root, dirs, fs in os.walk(anim_dir):
        for f in fs:
            if f.endswith(".txt"):
                files.append(os.path.join(root, f))
    return files

def describe_animation(anim, dom_name, sub_name, actors):

    if anim.has_tag("aggressive"):
        buffer = f"{dom_name} is sexually assaulting {sub_name}. "
    else:
      buffer = ""
    buffer += f"{sub_name} is"

    if anim.has_tag("rough"):
      buffer += " roughly"
    elif anim.has_tag("loving"):
      buffer += " lovingly"

    if anim.has_tag("cowgirl"):
       buffer += ", cowgirl position,"
    elif anim.has_tag("missionary"):
       buffer += ", missionary position,"
    elif anim.has_tag("kneeling"):
       buffer += ", kneeling position,"
    elif anim.has_tag("standing"):
       buffer += ", standing position,"

    if anim.has_tag("anal"):
        buffer += " having anal sex with"
    elif anim.has_tag("assjob"):
        buffer += " having a assjob by"
    elif anim.has_tag("boobjob"):
        buffer += " giving a blowjob to"
    elif anim.has_tag("thighjob"):
        buffer += " givingt a thighjob to"
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
    else:
        buffer += " having sex with"
        print ("no match!!!!!!!!!!!!!!")

    if len(actors) > 1:
        buffer += f" {dom_name}"
    buffer += "."

    return buffer

def parse_animation_file(filepath):
    animations = []
    with open(filepath, "r", encoding="utf-8") as f:
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