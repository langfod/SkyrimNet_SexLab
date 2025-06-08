Scriptname SexLab_SkyrimNet_Main extends Quest

Event OnInit()
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()
    Debug.Trace("SexLab_SkyrimNet_Main: Startup called")

    RegisterForModEvent("HookAnimationStart", "SexLab_SexStart")
    RegisterForModEvent("HookAnimationEnd", "SexLab_SexEnd")

    SkyrimNetApi.RegisterDecorator("get_sexlab_prompt", "SexLab_SkyrimNet_Main", "GetSexLab_Prompt")

    SkyrimNetApi.RegisterAction("SexTarget", \
            "Have sex with the target.", \
            "SexLab_SkyrimNet_Main", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Main", "SexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"target\": \"Actor\"}")

EndFunction

;----------------------------------------------------------------------------------------------------
; Prompts 
;----------------------------------------------------------------------------------------------------
String Function GetSexLab_Prompt(Actor akActor) global
    SexLab_SkyrimNet_Main main = Game.GetFormFromFile(0x800, "SexLab_SkyrimNet.esp") as SexLab_SkyrimNet_Main
    if ThreadSlots == None
        Debug.Trace("[SexLab_SkyrimNet] GetSexLab_Prompt: main is None")
        return ""
    endif
    sslThreadSlots ThreadSlots = Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadSlots
    if ThreadSlots == None
        Debug.Trace("[SexLab_SkyrimNet] GetSexLab_Prompt: ThreadSlots is None")
        return ""
    endif

    String prompt = ""
    int i = 0
    sslThreadController[] threads = ThreadSlots.Threads
    while threads.length < i
        prompt += main.GetThreadDecoration(threads[i])
        i += 1
    endwhile
    Debug.Trace("[SexLab_SkyrimNet] GetSexLab_Prompt"+prompt)
    return prompt 
EndFunction

String Function GetThreadDecoration(sslThreadController thread)
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.TraceAndBox("[SexLab_SkyrimNet] GetThreadDecoration: SexLab is None")
        return ""  
    endif

    String buffer = ""
    ; Get the thread that triggered this event via the thread id
    sslBaseAnimation anim = thread.Animation
    ; Get our list of actors that were in this animation thread.
    Actor[] actors = thread.Positions
    String sub_name = actors[0].GetLeveledActorBase().GetName()
    String dom_name = actors[1].GetLeveledActorBase().GetName()

    if anim.HasTag("aggressive")
        buffer = dom_name+" is sexually assaulting "+ sub_name + ". "
    else 
        buffer = dom_name+" and "+ sub_name + " are having a sexual activity. "
    endif 

    buffer += sub_name+" is "
    if anim.HasTag("Boobjob")
        buffer += "giving a blowjob to"
    elseif anim.HasTag("Vaginal")
        buffer += "having vaginal sex with"
    elseif anim.hasTag("Fisting")
        buffer += "having having her pussy fisted by"
    elseif anim.hasTag("Anal")
        buffer += "having anal sex with"
    elseif anim.HasTag("Oral")
        buffer += "giving a blowjob to"
    elseif anim.HasTag("Spanking")
        buffer += " being spanked by"
    elseif anim.HasTag("Masturbation")
        buffer += " masturbating furiously"
    else
        buffer += " having sex with "
    endif

    String pantingDec = sub_name
    if actors.Length > 1
        buffer += " " + dom_name
        pantingDec += " and " + dom_name
    endif 
    buffer += ". "+ pantingDec +" will include 'oh','ah', and 'uh' in what they say. "
    if anim.HasTag("aggressive")
        buffer += sub_name + " will also include 'please', 'stop', 'please stop' and 'no' in what they say."
    endif 

    buffer += "\n"+dom_name+"'s and "+sub_name+"'s sex can be described as: "
    int i = 0
    String[] tags = anim.GetRawTags()
    while i < tags.Length
        if tags[i] != "Billyy"
            if i != 0
                buffer += ", "
            endif 
            buffer += tags[i]
            i += 1
        endif 
    endwhile
    buffer += ".\n"
    Debug.Trace("sexlab: "+buffer)
    return buffer
endFunction
;----------------------------------------------------------------------------------------------------
; Actions
;----------------------------------------------------------------------------------------------------
Bool Function SexTarget_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.TraceAndBox("[SexLab_SkyrimNet] SetTarge_IsEigible: SexLab is None")
        return false  
    endif
    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if akTarget == None
        Debug.TraceAndBox("[SexLab_SkyrimNet] SetTarge_IsEigible: akTarget is None")
        return false
    endif
    ;if akActor.IsInFaction(main.SexLabAnimatingFaction) 
        ;Debug.Notification("[SexWithPlayer_IsEligible "+akActor.GetLeveledActorBase().GetName()+"] is sexting")
        ;return False 
    ;endif
    if !SexLab.IsValidActor(akActor)
        Debug.TraceAndBox("[SexLab_SkyrimNet] SexTarget_IsEligible: Invalid actor: " + akActor.GetLeveledActorBase().GetName())
        return False
    endif
    if !SexLab.IsValidActor(akTarget)
        Debug.TraceAndBox("[SexLab_SkyrimNet] SexTarget_IsEligible: Invalid actor: " + akTarget.GetLeveledActorBase().GetName())
        return False
    endif

    Debug.Trace("[SexTarget_IsEligible] " + akActor.GetLeveledActorBase().GetName() + " is eligible for sex with " + akTarget.GetLeveledActorBase().GetName())
    return True
EndFunction


Function SexTarget_Execute(Actor akActor, string contextJson, string paramsJson) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.TraceAndBox("[SexLab_SkyrimNet] GetThreadDecoration: SexLab is None")
        return
    endif
    
    ;Debug.TraceAndBox("[SexTarget_Execute] Starting got sexlab")
    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    ;Debug.Notification("[SexTarget_Execute] Starting sex with " + akActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())

    sslThreadModel thread = sexlab.NewThread()
    if thread == None
        Debug.TraceAndBox("[SexTarget_Execute] Failed to create thread")
        return  
    endif
    ;Debug.TraceAndBox("[SexTarget_Execute] Starting got target")
    if thread.addActor(akActor) < 0   
        Debug.Notification("[SexTarget_Execute] Starting sex couldn't add " + akActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    if thread.addActor(akTarget) < 0   
        Debug.Notification("[SexTarget_Execute] Starting sex couldn't add " + akTarget.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    
    ;Debug.TraceAndBox("[SexTarget_Execute] Starting ")
    Debug.Trace("[SexLab_SkyrimNet] SexTarget_Executer: Starting")
    thread.StartThread() 
EndFunction

;----------------------------------------------------------------------------------------------------
; Prompts 
;----------------------------------------------------------------------------------------------------
event SexLab_SexStart(int ThreadID, bool HasPlayer)
    ;Debug.TraceAndBox("SexLab_SkyrimNet_Main: SexStart called with ThreadID: " + ThreadID + ", HasPlayer: " + HasPlayer)    
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab != None
        ; Get the thread that triggered this event via the thread id
        sslThreadController thread = SexLab.GetController(ThreadID)
        sslBaseAnimation anim = thread.Animation
        ; Get our list of actors that were in this animation thread.
        Actor[] actors = thread.Positions
        String name1 = actors[0].GetLeveledActorBase().GetName()
        String name2 = actors[1].GetLeveledActorBase().GetName()

        String eventType = "sexual"
        String sexDec = name1
        if anim.HasTag("aggressive")
            eventType = "sexual assault"
            sexDec += " is being forced to "
        endif 

        if anim.HasTag("Boobjob")
            sexDec += " giving a blowjob to"
        elseif anim.HasTag("Vaginal")
            sexDec += " having vaginal sex with"
        elseif anim.hasTag("Fisting")
            sexDec += " having having her pussy fisted by"
        elseif anim.hasTag("Anal")
            sexDec += " having anal sex with"
        elseif anim.HasTag("Oral")
            sexDec += " giving a blowjob to"
        elseif anim.HasTag("Spanking")
            sexDec += " being spanked by"
        elseif anim.HasTag("Masturbation")
            sexDec += " masturbating furiously"
        else
            sexDec += " sex with "
        endif

        String pantingDec = name1
        if actors.Length > 1
            sexDec += " " + name2
            pantingDec += " and " + name2
        endif 
        sexDec += ". "+ pantingDec +" will include 'oh','ah', and 'uh' in what they say. "
        if anim.HasTag("aggressive")
            sexDec += name1 + " will also include 'please', 'stop', 'please stop' and 'no' in what they say."
        endif 

        sexDec += "\n This sex can be described as: "
        int i = 0
        String[] tags = anim.GetRawTags()
        while i < tags.Length
            if tags[i] != "Billyy"
                if i != 0
                    sexDec += ", "
                endif 
                sexDec += tags[i]
                i += 1
            endif 
        endwhile
        sexDec += ".\n"

        ;SkyrimNetApi.RegisterShortLivedEvent("SexLab_SkyrimNet_"+ThreadID, eventType, sexDec, sexDec, 1000000, actors[1], actors[0])
        SkyrimNetApi.RegisterEvent(eventType, sexDec, actors[1], actors[0])
        Debug.Trace("sexlab: "+sexDec)
    endif 
endEvent

; Our AnimationStart hook, called from the RegisterForModEvent("HookAnimationEnd_MatchMaker", "AnimationEnd") in TriggerSex()
;  -  HookAnimationEnd is sent by SexLab called once the sex animation has fully stopped.
event SexLab_SexEnd(int ThreadID, bool HasPlayer)
	; Get the thread that triggered this event via the thread id
	 ;sslThreadController Thread = SexLab.GetController(ThreadID)
	; Get our list of actors that were in this animation thread.
	;Actor[] actors = Thread.Positions
    ;actors[0].StartCombat(actors[1])
    ;actors[1].StartCombat(actors[0])
endEvent