Scriptname SkyrimNet_SexLab_PlayerRef extends ReferenceAlias  

int Property actorLock = 0 Auto

SkyrimNet_SexLab_Main Property main Auto  

Function Trace(String func, String msg, Bool notification=False) global
    msg = "[SkyrimNet_SexLab_PlayerRef."+func+"] "+msg
    Debug.Trace(msg) 
    if notification
        Debug.Notification(msg)
    endif 
EndFunction

Event OnInit() 
    Trace("OnInit","")
    main.Setup()
EndEvent 

Event OnPlayerLoadGame()
    Trace("OnPlayerLoadGame","")
    main.Setup()
EndEvent