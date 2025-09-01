Scriptname SkyrimNet_SexLab_PlayerRef extends ReferenceAlias  

int Property actorLock = 0 Auto

SkyrimNet_SexLab_Main Property main Auto  

Function Trace(String msg, Bool notification=False) global
    if notification
        Debug.Notification(msg)
    endif 
    msg = "[SkyrimNet_SexLab.PlayerRef] "+msg
    Debug.Trace(msg)
EndFunction

Event OnInit() 
    Trace("OnInit called")
    main.Setup()
EndEvent 

Event OnPlayerLoadGame()
    Trace("OnPlayerLoadGame called")
    main.Setup()
EndEvent