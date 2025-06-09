Scriptname SexLab_SkyrimNet_Main extends Quest

Event OnInit()
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()
    Debug.Trace("SexLab_SkyrimNet_Main: Startup called")

    ; RegisterForModEvent("HookAnimationStart", "SexLab_SexStart")
    RegisterForModEvent("HookAnimationEnd", "SexLab_SexEnd")

    SkyrimNetApi.RegisterDecorator("get_active_sex_events_prompt", "SexLab_SkyrimNet_Main", "GetActiveSexEvents_Prompt")
    SkyrimNetApi.RegisterDecorator("get_active_sex_events_count", "SexLab_SkyrimNet_Main", "GetActiveSexEvents_Count")

    SkyrimNetApi.RegisterAction("SexTarget", \
            "Have sex with the target or after agreeing to sex with target.", \
            "SexLab_SkyrimNet_Main", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Main", "SexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"target\": \"Actor\"}")

EndFunction

;----------------------------------------------------------------------------------------------------
; Prompts 
;----------------------------------------------------------------------------------------------------
String Function GetActiveSexEvents_Prompt(Actor akActor) global
    sslThreadSlots ThreadSlots = Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadSlots
    if ThreadSlots == None
        Debug.Notification("[SexLab_SkyrimNet] GetSexLab_Prompt: ThreadSlots is None")
        return ""
    endif

    sslThreadController[] threads = ThreadSlots.Threads

    int i = 0
    String prompt = ""
    while i < threads.length
        if (threads[i] as sslThreadModel).GetState() != "Unlocked"
            prompt += SexLab_GetThreadDecoration(threads[i])
        endif 
        i += 1
    endwhile
    Debug.Trace("[SexLab_SkyrimNet] GetSexLab_Prompt"+prompt)
    return prompt 
EndFunction

int Function GetActiveSexEvents_Count(Actor akActor) global
    sslThreadSlots ThreadSlots = Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadSlots
    if ThreadSlots == None
        Debug.Notification("[SexLab_SkyrimNet] GetSexLab_Prompt: ThreadSlots is None")
        return -1
    endif

    sslThreadController[] threads = ThreadSlots.Threads

    int i = 0
    int num_threads = 0
    String prompt = ""
    while i < threads.length
        if (threads[i] as sslThreadModel).GetState() != "Unlocked"
            num_threads += 1
        endif 
        i += 1
    endwhile
    Debug.Trace("[SexLab_SkyrimNet] GetActiveSexEvents_Count: "+num_threads)
    return num_threads 
EndFunction

String Function SexLab_GetThreadDecoration(sslThreadController thread) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] GetThreadDecoration: SexLab is None")
        return ""  
    endif

    ; Get the thread that triggered this event via the thread id
    sslBaseAnimation anim = thread.Animation
    ; Get our list of actors that were in this animation thread.
    Actor[] actors = thread.Positions
    String sub_name = actors[0].GetLeveledActorBase().GetName()
    String dom_name = actors[1].GetLeveledActorBase().GetName()

    Debug.Trace("[SexLab_SkyrimNet] sub: "+sub_name+" dom: "+dom_name+" count: "+actors.Length)

    String buffer = "- "
    if anim.HasTag("aggressive")
        buffer += dom_name+" is sexually assaulting "+ sub_name + ". "
    else 
        buffer += dom_name+" and "+ sub_name + " are having a sexual activity. "
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
    endif 
    ;buffer += ". Therefor both "+ pantingDec +" will include at least one of these words when they speak: 'oh','ah', and 'uh'. "
    buffer += ". They will show they are having sex by including words like 'oh god', 'uh', and 'fuck me!' in thier next response."
    if anim.HasTag("aggressive")
        buffer += sub_name + " will also include 'please', 'stop', 'please stop' and 'no' in what they say."
    endif 

    buffer += "This sex can be described as: "
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
    buffer += ".\n\n"
    return buffer
endFunction
;----------------------------------------------------------------------------------------------------
; Actions
;----------------------------------------------------------------------------------------------------
Bool Function SexTarget_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] SetTarge_IsEigible: SexLab is None")
        return false  
    endif
    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if akTarget == None
        Debug.Notification("[SexLab_SkyrimNet] SetTarge_IsEigible: akTarget is None")
        return false
    endif
    ;if akActor.IsInFaction(main.SexLabAnimatingFaction) 
        ;Debug.Notification("[SexWithPlayer_IsEligible "+akActor.GetLeveledActorBase().GetName()+"] is sexting")
        ;return False 
    ;endif
    if !SexLab.IsValidActor(akActor)
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_IsEligible: Invalid actor: " + akActor.GetLeveledActorBase().GetName())
        return False
    endif
    if !SexLab.IsValidActor(akTarget)
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_IsEligible: Invalid actor: " + akTarget.GetLeveledActorBase().GetName())
        return False
    endif

    Debug.Trace("[SexTarget_IsEligible] " + akActor.GetLeveledActorBase().GetName() + " is eligible for sex with " + akTarget.GetLeveledActorBase().GetName())
    return True
EndFunction


Function SexTarget_Execute(Actor akActor, string contextJson, string paramsJson) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] GetThreadDecoration: SexLab is None")
        return
    endif
    
    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())

    sslThreadModel thread = sexlab.NewThread()
    if thread == None
        Debug.Notification("[SexTarget_Execute] Failed to create thread")
        return  
    endif
    if thread.addActor(akActor) < 0   
        Debug.Notification("[SexTarget_Execute] Starting sex couldn't add " + akActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    if thread.addActor(akTarget) < 0   
        Debug.Notification("[SexTarget_Execute] Starting sex couldn't add " + akTarget.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    
    Debug.Notification(akActor.GetLeveledActorBase().GetName()+" will have sex with "+akTarget.GetLeveledActorBase().GetName())
    Debug.Trace("[SexLab_SkyrimNet] SexTarget_Executer: Starting")
    thread.StartThread() 
EndFunction

;----------------------------------------------------------------------------------------------------
; Prompts 
;----------------------------------------------------------------------------------------------------
;event SexLab_SexStart(int ThreadID, bool HasPlayer)
; endEvent

; Our AnimationStart hook, called from the RegisterForModEvent("HookAnimationEnd_MatchMaker", "AnimationEnd") in TriggerSex()
;  -  HookAnimationEnd is sent by SexLab called once the sex animation has fully stopped.
event SexLab_SexEnd(int ThreadID, bool HasPlayer)
	; Get the thread that triggered this event via the thread id
	 ;sslThreadController Thread = SexLab.GetController(ThreadID)
	; Get our list of actors that were in this animation thread.
	;Actor[] actors = Thread.Positions
    ;actors[0].StartCombat(actors[1])
    ;actors[1].StartCombat(actors[0])
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab != None
        ; Get the thread that triggered this event via the thread id
        sslThreadController thread = SexLab.GetController(ThreadID)
        sslBaseAnimation anim = thread.Animation
        ; Get our list of actors that were in this animation thread.
        Actor[] actors = thread.Positions

        String eventType = "sexual mutual"
        if anim.HasTag("aggressive")
            eventType = "sexual assault"
        endif 

        String prompt = SexLab_GetThreadDecoration(thread)

        SkyrimNetApi.RegisterShortLivedEvent("SexLab_SkyrimNet_"+threadID,\
            eventType, prompt, "", 180000,\
            actors[1], actors[0])
    endif 
endEvent