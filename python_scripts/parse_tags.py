import json

data = {
  "animations": [
    {
      "actors": [
        {
          "add_cum": 1,
          "stages": [
            {"id": "B_Bear_B_Miss_A1_S1"},
            {"id": "B_Bear_B_Miss_A1_S2"},
            {"id": "B_Bear_B_Miss_A1_S3"},
            {"id": "B_Bear_B_Miss_A1_S4"},
            {"id": "B_Bear_B_Miss_A1_S5"}
          ],
          "type": "Female"
        },
        {
          "race": "Bears",
          "stages": [
            {"id": "B_Bear_B_Miss_A2_S1"},
            {"id": "B_Bear_B_Miss_A2_S2"},
            {"id": "B_Bear_B_Miss_A2_S3"},
            {"id": "B_Bear_B_Miss_A2_S4"},
            {"id": "B_Bear_B_Miss_A2_S5"}
          ],
          "type": "CreatureMale"
        }
      ],
      "creature_race": "Bears",
      "id": "B_Bear_B_Miss",
      "name": "Billyy (Bear) Missionary",
      "sound": "Squishing",
      "tags": "Billyy,Creature,Bear,Bestiality,Missionary,Laying,CF,Dirty,Creampie,Vaginal,MovingDick,ABC,"
    }
  ]
}

tags_str = data["animations"][0]["tags"]
tags_set = set(tag for tag in tags_str.split(",") if tag)
print(tags_set)