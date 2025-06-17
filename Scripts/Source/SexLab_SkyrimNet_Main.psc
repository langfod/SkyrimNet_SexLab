Scriptname SexLab_SkyrimNet_Main extends Quest

Event OnInit()
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()
    Debug.Trace("SexLab_SkyrimNet_Main: Startup called")

    UnRegisterForModEvent("HookStageStart")
    RegisterForModEvent("HookStageStart", "SexLab_StageStart")
    ;UnRegisterForModEvent("HookStageEnd")
    ;RegisterForModEvent("HookStageEnd", "SexLab_StageEnd")
    UnRegisterForModEvent("HookOrgasmStart")
    RegisterForModEvent("HookOrgasmStart", "SexLab_OrgasmStart")
    UnRegisterForModEvent("HookAnimationEnd")
    RegisterForModEvent("HookAnimationEnd", "SexLab_AnimationEnd")

    SkyrimNetApi.RegisterDecorator("get_active_sex_events_prompt", "SexLab_SkyrimNet_Main", "GetActiveSexEvents_Prompt")
    SkyrimNetApi.RegisterDecorator("get_active_sex_events_count", "SexLab_SkyrimNet_Main", "GetActiveSexEvents_Count")

    SkyrimNetApi.RegisterAction("StartSexTarget", \
            "Start having <type> sex with <target>.", \
            "SexLab_SkyrimNet_Main", "StartSexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Main", "StartSexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"target\": \"Actor\", \"type\":\"vaginal|anal|oral\"}")
    SkyrimNetApi.RegisterAction("StartSexMasturbation", \
            "Start masturbating.", \
            "SexLab_SkyrimNet_Main", "StartSexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Main", "StartSexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"type\":\"masturbation\"}")

    Debug.Trace("SexLab_SkyrimNet_Main Finished registration")

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
    String buffer

    If anim.HasTag("aggressive")
        buffer = domName + " is sexually assaulting " + subName + ". "
    Else
        buffer = ""
    EndIf
    buffer += subName + " is"

    If anim.HasTag("rough")
        buffer += " roughly"
    ElseIf anim.HasTag("loving")
        buffer += " lovingly"
    EndIf

    If anim.HasTag("cowgirl")
        buffer += ", cowgirl position,"
    ElseIf anim.HasTag("missionary")
        buffer += ", missionary position,"
    ElseIf anim.HasTag("kneeling")
        buffer += ", kneeling position,"
    ElseIf anim.HasTag("standing")
        buffer += ", standing position,"
    EndIf

    If anim.HasTag("anal")
        buffer += " having anal sex with"
    ElseIf anim.HasTag("assjob")
        buffer += " having a assjob by"
    ElseIf anim.HasTag("boobjob")
        buffer += " giving a blowjob to"
    ElseIf anim.HasTag("thighjob")
        buffer += " givingt a thighjob to"
    ElseIf anim.HasTag("vaginal")
        buffer += " having vaginal sex with"
    ElseIf anim.HasTag("fisting")
        buffer += " having having her pussy fisted by"
    ElseIf anim.HasTag("oral") || anim.HasTag("blowjob") || anim.HasTag("cunnilingus")
        buffer += " giving a blowjob to"
    ElseIf anim.HasTag("spanking")
        buffer += " being spanked by"
    ElseIf anim.HasTag("masturbation")
        buffer += " masturbating furiously"
    ElseIf anim.HasTag("fingering")
        buffer += " being fingered by"
    ElseIf anim.HasTag("footjob")
        buffer += " giving a footjob to"
    ElseIf anim.HasTag("handjob")
        buffer += " giving a handjob to"
    ElseIf anim.HasTag("kissing")
        buffer += " kissing with"
    ElseIf anim.HasTag("headpat")
        buffer += " having head patted by"
    ElseIf anim.HasTag("hugging")
        buffer += " hugging"
    Else
        buffer += " having sex with"
        Debug.Trace("no match!!!!!!!!!!!!!!")
    EndIf

    If actors.Length > 1
        buffer += " " + domName
    EndIf
    buffer += "."
    ;buffer += ". Therefor both "+ pantingDec +" will include at least one of these words when they speak: 'oh','ah', and 'uh'. "
    ;if anim.HasTag("aggressive")
    ;    buffer += sub_name + " will also include 'please', 'stop', 'please stop' and 'no' in what they say."
    ;endif 

    ;buffer += "This sex can be described as: "
    ;int i = 0
    ;String[] tags = anim.GetRawTags()
    ;while i < tags.Length
    ;    if tags[i] != "Billyy"
    ;        if i != 0
    ;            buffer += ", "
    ;        endif 
    ;        buffer += tags[i]
    ;        i += 1
    ;    endif 
    ;endwhile
    buffer += ".\n\n"
    return buffer
endFunction
;----------------------------------------------------------------------------------------------------
; Actions
;----------------------------------------------------------------------------------------------------
Bool Function StartSexTarget_IsEligible(Actor akActor, string contextJson, string paramsJson) global
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
        Debug.Trace("[SexLab_SkyrimNet] StartSexTarget_IsEligible: Invalid actor: " + akActor.GetLeveledActorBase().GetName())
        return False
    endif
    if !SexLab.IsValidActor(akTarget)
        Debug.Trace("[SexLab_SkyrimNet] StartSexTarget_IsEligible: Invalid actor: " + akTarget.GetLeveledActorBase().GetName())
        return False
    endif

    Debug.Trace("[StartSexTarget_IsEligible] " + akActor.GetLeveledActorBase().GetName() + " is eligible for sex with " + akTarget.GetLeveledActorBase().GetName())
    return True
EndFunction


Function StartSexTarget_Execute(Actor akActor, string contextJson, string paramsJson) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] GetThreadDecoration: SexLab is None")
        return
    endif
    
    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "none")
    Debug.TraceAndBox("StartSexTarget_Execte:"+type)


    sslThreadModel thread = sexlab.NewThread()
    if thread == None
        Debug.Notification("[StartSexTarget_Execute] Failed to create thread")
        return  
    endif
    if thread.addActor(akActor) < 0   
        Debug.Notification("[StartSexTarget_Execute] Starting sex couldn't add " + akActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    if thread.addActor(akTarget) < 0   
        Debug.Notification("[StartSexTarget_Execute] Starting sex couldn't add " + akTarget.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    
    Debug.Notification(akActor.GetLeveledActorBase().GetName()+" will have sex with "+akTarget.GetLeveledActorBase().GetName())
    Debug.Trace("[SexLab_SkyrimNet] StartSexTarget_Executer: Starting")
    thread.StartThread() 
EndFunction

;----------------------------------------------------------------------------------------------------
; Prompts 
;----------------------------------------------------------------------------------------------------
Function Thread_Event(int ThreadID, Bool orgasm)
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions

    sslBaseAnimation anim = thread.Animation
    Debug.Trace("[SexLab_SkyrimNet] sub: "+sub_name+" dom: "+dom_name+" count: "+actors.Length)

    String sub_name = actors[0].GetLeveledActorBase().GetName()
    String dom_name 
    if actors.length > 1
        dom_name = actors[1].GetLeveledActorBase().GetName()
    endif 
    
    String eventType
    String eventDesc = sub_name
    if orgasm 
        if actors.length > 1
            eventDesc += " and "+ dom_name
        endif 
        eventDesc += " orgasmed after "+sub_name
        if thread.IsAggressive
            eventType = "raping "
            eventDesc += " was forced to "
        else
            eventType = "sexing " 
            eventDesc += " was "
        endif 
    else
        if thread.IsAggressive
            eventType = "raping "
            eventDesc += " is forced to "
        else
            eventType = "sex " 
            eventDesc += " is "
        endif 
    endif 

    if anim.HasTag("Masturbation") || actors.length == 1
        eventType += "masturbating"
        eventDesc += " masturbating furiously "
    elseif anim.HasTag("Boobjob")
        eventType += "boobjob"
        eventDesc += " giving a boobjob to "
    elseif anim.HasTag("Vaginal")
        eventType += "vaginal"
        eventDesc += " having vaginal sex with "
    elseif anim.hasTag("Fisting")
        eventType += "fisting"
        eventDesc += " having her pussy fisted by "
    elseif anim.hasTag("Anal")
        eventType += "anal"
        eventDesc += " having anal sex with "
    elseif anim.HasTag("Oral")
        eventType += "oral"
        eventDesc += " giving a blowjob to "
    elseif anim.HasTag("Spanking")
        eventType += "spanking"
        eventDesc += " being spanked by "
    endif
    if actors.Length > 1
        eventDesc += dom_name
    endif 
    eventDesc += "."

    if orgasm 
        eventType = "orgasm"
    endif 

    Debug.Notification(eventDesc)
    SkyrimNetApi.RegisterShortLivedEvent("SexLab_SkyrimNet_"+threadID,\
        eventType, eventDesc, "", 10000,\
        actors[1], actors[0])
endFunction 

Event SexLab_StageStart(int ThreadID, bool HasPlayer)
    Thread_Event(ThreadID, false )
EndEvent
Event SexLab_OrgasmStart(int ThreadID, bool HasPlayer)
    Thread_Event(ThreadID, true )
EndEvent

event SexLab_AnimationStart(int ThreadID, bool HasPlayer)
endEvent

; Our AnimationStart hook, called from the RegisterForModEvent("HookAnimationEnd_MatchMaker", "AnimationEnd") in TriggerSex()
;  -  HookAnimationEnd is sent by SexLab called once the sex animation has fully stopped.
event SexLab_AnimationEnd(int ThreadID, bool HasPlayer)
    Thread_Event(ThreadID, true )
endEvent
Int Property NewProperty  Auto  
