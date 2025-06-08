Scriptname SexLab_SkyrimNet_PlayerRef extends ReferenceAlias  

SexLab_SkyrimNet_Main Property main  Auto  


Event OnPlayerLoadGame()
    Debug.Trace("[SexLab_SkyrimNet] OnPlayerLoadGame called")
    main.Setup()
EndEvent