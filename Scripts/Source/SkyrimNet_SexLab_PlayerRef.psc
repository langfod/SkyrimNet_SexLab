Scriptname SkyrimNet_SexLab_PlayerRef extends ReferenceAlias  

int Property actorLock = 0 Auto

SkyrimNet_SexLab_Main Property main Auto  

Event OnPlayerLoadGame()
    Debug.Trace("[SkyrimNet_SexLab_Main] OnPlayerLoadGame called")

    main.Setup()
EndEvent