import sys
import os 
import argparse
import json 
# Create the parser
parser = argparse.ArgumentParser(description='Parses the wiki.')

# Add arguments
parser.add_argument('-s', '--src', type=str, required=True)
parser.add_argument('-d', '--dst', type=str, required=True)
args = parser.parse_args()

fname_info = {} 
for fname in os.listdir(args.src):
    with open(f"{args.src}/{fname}") as fin: 
        fname_info[fname] = json.load(fin) 

for fname,info in fname_info.items(): 
    path = f"{args.dst}/{fname}"
    merged = " " 
    if os.path.exists(path): 
        with open(path) as fin: 
            print ("loading",fname)
            old = json.load(fin) 
            for key,value in old.items(): 
                if key not in info: 
                    merged = "M" 
                    info[key] = value 
    print (merged,fname)
    with open(path,"w") as fout: 
        json.dump(info,indent=4,fp=fout)