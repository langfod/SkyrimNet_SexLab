Scriptname SkyrimNet_SexLab_PlayerRef extends ReferenceAlias  

SkyrimNet_SexLab_Main Property main Auto  

Event OnPlayerLoadGame()
    Debug.Trace("[SkyrimNet_SexLab] OnPlayerLoadGame called "+main)
    main.Setup()
EndEvent