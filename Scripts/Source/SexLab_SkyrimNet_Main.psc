Scriptname SexLab_SkyrimNet_Main extends Quest

import JContainers

int property creature_description_map Auto

String creature_description_fname = "Data/SexLab_SkyrimNet/creature-descriptions.json"

Event OnInit()
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()
    Debug.Trace("SexLab_SkyrimNet_Main: Startup called")

    RegisterSexlabEvents()
    RegisterDecorators() 
    RegisterActions()

    Debug.Trace("SexLab_SkyrimNet_Main Finished registration")

    if creature_description_map != 0
        JValue.release(creature_description_map)
    endif 

    creature_description_fname = "Data/SexLab_SkyrimNet/creature-descriptions.json"
    ; Debug.Notification("loading "+creature_description_fname)
    creature_description_map = JValue.readFromFile(creature_description_fname)
    JValue.retain(creature_description_map)

EndFunction
;----------------------------------------------------------------------------------------------------
; SexLab Events
;----------------------------------------------------------------------------------------------------
Function RegisterSexlabEvents()
    Debug.Trace("SexLab_SkyrimNet_Main: RegisterSexlabEvents called")
    ; SexLabFramework sexlab = Game.GetForm

    UnRegisterForModEvent("HookAnimationStart")
    RegisterForModEvent("HookAnimationStart", "AnimationStart")
    ;UnRegisterForModEvent("HookStageStart")
    ;RegisterForModEvent("HookStageStart", "StageStart")
    ;UnRegisterForModEvent("HookStageEnd")
    ;RegisterForModEvent("HookStageEnd", "SexLab_StageEnd")
    UnRegisterForModEvent("HookOrgasmStart")
    RegisterForModEvent("HookOrgasmStart", "SexLab_OrgasmStart")
    UnRegisterForModEvent("HookAnimationEnd")
    RegisterForModEvent("HookAnimationEnd", "SexLab_AnimationEnd")
EndFunction 


event AnimationStart(int ThreadID, bool HasPlayer)
    Sex_Dialog(ThreadID, true )
endEvent

Event OrgasmStart(int ThreadID, bool HasPlayer)
    Orgasm_Dialog(ThreadID)
EndEvent

; Our AnimationStart hook, called from the RegisterForModEvent("HookAnimationEnd_MatchMaker", "AnimationEnd") in TriggerSex()
;  -  HookAnimationEnd is sent by SexLab called once the sex animation has fully stopped.
event AnimationEnd(int ThreadID, bool HasPlayer)
    Sex_Dialog(ThreadID, false )
endEvent

Function Sex_Dialog(int ThreadID, Bool starting) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions
    String dom_name = actors[1].GetLeveledActorBase().GetName()
    String sub_name = actors[0].GetLeveledActorBase().GetName()
    String type = ""
    if starting
        type = " starts "
    else
        type = " finished "
    endif
    if thread.IsAggressive
        type += " raping "
    else
        type += " having sex with "
    endif
    String dialog = "*"+dom_name+type+sub_name+".*"
    SkyrimNetApi.RegisterDialogue(actors[0], dialog)
EndFunction

Function Orgasm_Dialog(int ThreadID) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions
    String dom_name = actors[0].GetLeveledActorBase().GetName()
    String sub_name = actors[1].GetLeveledActorBase().GetName()
    SkyrimNetApi.RegisterDialogueToListener(actors[1], actors[0], "I'm cumming")
EndFunction  

;----------------------------------------------------------------------------------------------------
; Decorators 
;----------------------------------------------------------------------------------------------------
Function RegisterDecorators()
    Debug.Trace("SexLab_SkyrimNet_Main: RegisterDecorattors called")
    SkyrimNetApi.RegisterDecorator("sexlab_get_threads", "SexLab_SkyrimNet_Main", "Get_Threads")
EndFunction

String Function Get_Threads(Actor akActor) global
    Debug.Trace("[SexLab_SkyrimNet] Get_Threads called for "+akActor.GetLeveledActorBase().GetName())
    sslThreadSlots ThreadSlots = Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadSlots
    if ThreadSlots == None
        Debug.Notification("[SexLab_SkyrimNet] GetSexLab_Prompt: ThreadSlots is None")
        return ""
    endif

    sslThreadController[] threads = ThreadSlots.Threads

    Debug.Trace("[SexLab_SkyrimNet] Before loop")
    int i = 0
    String threads_str = ""
    while i < threads.length
        if (threads[i] as sslThreadModel).GetState() == "animating"
            if threads_str != ""
                threads_str += ", "
            endif 
            threads_str += Thread_Json(threads[i])
        endif 
        i += 1
    endwhile
    return "{\"threads\":["+threads_str+"]}"
EndFunction 

String Function Thread_Json(sslThreadController thread) global
    Actor[] actors = thread.Positions
    String thread_str = "{" 
    if thread.IsAggressive
        thread_str += "\"is_aggressive\": true, "
    else
        thread_str += "\"is_aggressive\": false, "
    endif 

    sslBaseAnimation anim = thread.Animation
    int i = 0
    String[] tags = anim.GetRawTags()
    String tags_str = "" 
    while i < tags.Length
        if tags_str != ""
            tags_str += ", "
        endif 
        tags_str += "\""+tags[i]+"\""
        i += 1
    endwhile
    thread_str += "\"tags\": ["+tags_str+"], "
    thread_str += "\"sub_name\": \""+actors[0].GetLeveledActorBase().GetName()+"\", "
    thread_str += "\"dom_name\": \""+actors[1].GetLeveledActorBase().GetName()+"\" "
    thread_str += "}"
    return thread_str
EndFunction

bool Function SexLab_Thread_LOS(Actor akActor, sslThreadController thread) global
    Actor[] actors = thread.Positions
    int i = 0
    while i < actors.length 
        if akActor == actors[i] || akActor.HasLOS(actors[i])
            return true
        endif 
        i += 1
    endwhile 
    return false
endFunction 

;----------------------------------------------------------------------------------------------------
; Actions
;----------------------------------------------------------------------------------------------------
Function RegisterActions()
    Debug.Trace("SexLab_SkyrimNet_Main: RegisterActions called")
    SkyrimNetApi.RegisterAction("SexTarget", \
            "Start having or agree to have {type} sex with {target}.", \
            "SexLab_SkyrimNet_Main", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Main", "SexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"target\": \"Actor\", \"type\":\"vaginal|anal|oral\", \"aggressive\":\"false\"}")
    SkyrimNetApi.RegisterAction("RapeTarget", \
            "Starts being {type} raped by {target}.", \
            "SexLab_SkyrimNet_Main", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Main", "SexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"target\": \"Actor\", \"type\":\"vaginal|anal|oral\", \"aggressive\":\"true\"}")
    SkyrimNetApi.RegisterAction("SexMasturbation", \
            "Start masturbating.", \
            "SexLab_SkyrimNet_Main", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Main", "SexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"type\":\"masturbation\"}")
EndFunction

Bool Function SexTarget_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] SetTarge_IsEigible: SexLab is None")
        Debug.Trace("[SexLab_SkyrimNet] SetTarge_IsEigible: SexLab is None")
        return false  
    endif
    if !SexLab.IsValidActor(akActor)
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_IsEligible: akActor: " + akActor.GetLeveledActorBase().GetName()+" can't have sex")
        return False
    endif

    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if akTarget == None
        Debug.Trace("[SexLab_SkyrimNet] SetTarge_IsEigible: akTarget is None "+paramsJson)
        return false
    endif
    if !SexLab.IsValidActor(akTarget)
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_IsEligible: akTarget: " + akTarget.GetLeveledActorBase().GetName()+" can't have sex")
        return False
    endif

    Debug.Trace("[SexTarget_IsEligible] " + akActor.GetLeveledActorBase().GetName() + " is eligible for sex with " + akTarget.GetLeveledActorBase().GetName())
    return True
EndFunction


Function SexTarget_Execute(Actor akActor, string contextJson, string paramsJson) global
    Debug.Trace("[SexLab_SkyrimNet] SexTarget_Execute called with params: "+paramsJson+"SexLab_SkyrimNet")
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] SexTarget_Execute: SexLab is None")
        return
    endif
    
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type","vaginal")
    Debug.Trace("SexTarget_Execte:"+type)
    Actor akTarget = None
    if type != "masturbation" && type != "masturbate"
        akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer()) 
    endif 

    sslThreadModel thread = sexlab.NewThread()
    if thread == None
        Debug.Notification("[SexTarget_Execute] Failed to create thread")
        Debug.Trace("[SexTarget_Execute] Failed to create thread")
        return  
    endif
    if thread.addActor(akActor) < 0   
        Debug.Trace("[SexTarget_Execute] Starting sex couldn't add " + akActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    if akTarget != None 
        if thread.addActor(akTarget) < 0   
            Debug.Trace("[SexTarget_Execute] Starting sex couldn't add " + akTarget.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
            return
        endif  
    endif 
    
    ; Debug.Notification(akActor.GetLeveledActorBase().GetName()+" will have sex with "+akTarget.GetLeveledActorBase().GetName())
    Debug.Trace("[SexLab_SkyrimNet] SexTarget_Executer: Starting")
    thread.addTag(type)
    if SkyrimNetApi.GetJsonString(paramsJson, "aggressive", "false") == "true"
        thread.IsAggressive = true
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_Execute: Thread is aggressive")
    else
        thread.IsAggressive = false
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_Execute: Thread is not aggressive")
    endif 
    thread.StartThread() 
EndFunction

;----------------------------------------------------------------------------------------------------
; Prompts 
;----------------------------------------------------------------------------------------------------
Function Thread_Event(int ThreadID, Bool orgasm, Bool ongoing)
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    sslThreadController thread = SexLab.GetController(ThreadID)
    sslBaseAnimation anim = thread.Animation
    Actor[] actors = thread.Positions

    String eventType = "" 
    if thread.IsAggressive
        eventType = "rape: "
    else
        eventType = "sex: " 
    endif 
    int i = 0
    String[] tags = anim.GetRawTags()
    while i < tags.Length
        if tags[i] != "Billyy"
            if i != 0
                eventType += ", "
            endif 
            eventType += tags[i]
            i += 1
        endif 
    endwhile
    
    String[] desc_names = SexLab_GetThreadDescription(thread, ongoing)
    String eventDesc = desc_names[0]
    String[] names = new String[2]
    names[0] = desc_names[1]
    names[1] = desc_names[2]
    Debug.Notification(eventDesc)
    SkyrimNetApi.RegisterShortLivedEvent("SexLab_SkyrimNet_"+threadID,\
        eventType, eventDesc, "", 10000,\
        actors[1], actors[0])

    if orgasm
        int position = 0
        while position < actors.length
            int j = (position+1)%(names.length)
            int CumId = anim.GetCumId(position, thread.stage)
            if cumId > 0
                String cum_type = "" 
                if cumId == sslObjectFactory.vaginal()
                    cum_type="cum dripping from pussy"
                elseif cumId == sslObjectFactory.oral()
                    cum_type="cum dripping from mouth"
                elseif cumId == sslObjectFactory.anal()
                    cum_type="cum dripping from ass"
                elseif cumId == sslObjectFactory.VaginalOral()
                    cum_type="cum dripping from pussy and mouth"
                elseif cumId == sslObjectFactory.VaginalAnal()
                    cum_type="cum dripping from pussy and ass"
                elseif cumId == sslObjectFactory.OralAnal()
                    cum_type="cum dripping from mouth and ass"
                elseif cumId == sslObjectFactory.OralAnal()
                    cum_type="cum dripping from pussy, mouth, and ass"
                endif
                if cum_type != "" 
                    String cum_desc = names[position]+" has "+names[j]+"'s "+cum_type
                    SkyrimNetApi.RegisterShortLivedEvent("SexLab_SkyrimNet_cum"+cumId+"_"+threadID,\
                        cum_type, cum_desc, "", 60000,\
                        actors[j], actors[position])
                    SkyrimNetApi.RegisterShortLivedEvent("SexLab_SkyrimNet_orgasm"+cumId+"_"+threadID,\
                        "orgasmed", names[j]+" orgasmed", "", 60000,\
                        actors[j],None)
                    SkyrimNetApi.RegisterShortLivedEvent("SexLab_SkyrimNet_orgasm"+cumId+"_"+threadID,\
                        "orgasmed", names[position]+" orgasmed", "", 60000,\
                        actors[position],None)
                    SkyrimNetApi.RegisterDialogueToListener(actors[position], actors[j], "I'm cumming")
                endif 
            endif 
            position += 1
        endwhile
    endif 
            
endFunction 


;----------------------------------------------------
; Parses the tags
;----------------------------------------------------
String[] Function SexLab_GetThreadDescription(sslThreadController thread,bool ongoing=False) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] GetThreadDescription: SexLab is None")
        return None
    endif
    SexLab_SkyrimNet_Main main = Game.GetFormFromFile(0x800, "SexLab_SkyrimNet.esp") as SexLab_SkyrimNet_Main

    ; Get the thread that triggered this event via the thread id
    sslBaseAnimation anim = thread.Animation
    ; Get our list of actors that were in this animation thread.
    Actor[] actors = thread.Positions
    String[] names = new String[2]
    names[0] = actors[0].GetLeveledActorBase().GetName()
    names[1] = actors[1].GetLeveledActorBase().GetName()

    String desc = "" 
    int i = 0
    while i < actors.length
        Race r = actors[i].GetLeveledActorBase().GetRace()
        if JMap.hasKey(main.creature_description_map, r.getName())
            desc += actors[i].GetLeveledActorBase().GetName()+" is a "+r.getName()+". "\
                +JMap.getStr(main.creature_description_map, r.getName())
            names[i] = "a "+r.getName() 
        endif
        i += 1
    endwhile
    String sub_name = names[0]
    String dom_name = names[1]
    Debug.Trace("[SexLab_SkyrimNet] sub: "+sub_name+" dom: "+dom_name+" count: "+actors.Length)

    if thread.IsAggressive
        desc += dom_name + " is sexually assaulting " + sub_name + ". "
    Else
        desc += ""
    EndIf
    desc += sub_name + " is"

    if anim.HasTag("bound")
        desc += " bound"
    endif

    if anim.HasTag("rough")
        desc += " roughly"
    elseif anim.HasTag("loving")
        desc += " lovingly"
    endif

    if anim.HasTag("bestiality")
        desc += " bestiality "
    endif

    String[] positions = new String[7]
    positions[0] = "69"
    positions[1] = "cowgirl"
    positions[2] = "missionary"
    positions[3] = "kneeling"
    positions[4] = "doggy"
    positions[5] = "sitting"
    positions[6] = "standing"

    i = 0
    bool found = false
    while i < positions.Length && !found
        if anim.HasTag(positions[i])
            desc += ", " + positions[i] + " position,"
            found = true
        endif
        i += 1
    endwhile

    if anim.HasTag("behind")
        desc += " from behind"
    endif

    String[] on_furniture = new String[21]
    on_furniture[0] = "Table"
    on_furniture[1] = "LowTable"
    on_furniture[2] = "JavTable"
    on_furniture[3] = "Pole"
    on_furniture[4] = "wall"
    on_furniture[5] = "horse"
    on_furniture[6] = "Pillory"
    on_furniture[7] = "PilloryLow"
    on_furniture[8] = "Cage"
    on_furniture[9] = "Haybale"
    on_furniture[10] = "Xcross"
    on_furniture[11] = "WoodenPony"
    on_furniture[12] = "EnchantingWB"
    on_furniture[13] = "AlchemyWB"
    on_furniture[14] = "FuckMachine"
    on_furniture[15] = "chair"
    on_furniture[16] = "wheel"
    on_furniture[17] = "DwemerChair"
    on_furniture[18] = "NecroChair"
    on_furniture[19] = "Throne"
    on_furniture[20] = "Stockade"
    ; Add more if needed

    i = 0
    found = false
    while i < on_furniture.Length
        if anim.HasTag(on_furniture[i])
            desc += " on a " + on_furniture[i]
            found = true
        endif
        i += 1
    endwhile

    if anim.HasTag("Cage")
        desc += " in a cage"
    elseif anim.HasTag("Gallows")
        desc += " in a gallows"
    elseif anim.HasTag("coffin")
        desc += " in a coffin"
    elseif anim.HasTag("floating")
        desc += " floating in air"
    elseif anim.HasTag("tentacles")
        desc += " with tentacles"
    elseif anim.HasTag("gloryhole") || anim.HasTag("gloryholem")
        desc += " through a gloryhole"
    elseif !found && anim.HasTag("Furniture")
        Debug.Trace("miss furniture")
    endif

    String have = " had"
    String give = " gave"
    String is = " was"
    if ongoing
        have= " having"
        give = " giving"
        is = " is"
    endif 

    if anim.HasTag("anal")
        desc += have+" anal sex with"
    elseif anim.HasTag("assjob")
        desc += have+" a assjob by"
    elseif anim.HasTag("boobjob")
        desc += give+" a blowjob to"
    elseif anim.HasTag("thighjob")
        desc += give+" a thighjob to"
    elseif anim.HasTag("vaginal")
        desc += have+" vaginal sex with"
    elseif anim.HasTag("fisting")
        desc += have+" her pussy fisted by"
    elseif anim.HasTag("oral") || anim.HasTag("blowjob") || anim.HasTag("cunnilingus")
        desc += give+" a blowjob to"
    elseif anim.HasTag("spanking")
        desc += have+" bottom spanked by"
    elseif anim.HasTag("masturbation")
        desc += have+" masturbating furiously"
    elseif anim.HasTag("fingering")
        desc += have+" genitals fingered by"
    elseif anim.HasTag("footjob")
        desc += give+" a footjob to"
    elseif anim.HasTag("handjob")
        desc += give+" a handjob to"
    elseif anim.HasTag("kissing")
        desc += give+" kisses with"
    elseif anim.HasTag("headpat")
        desc += have+" head patted by"
    elseif anim.HasTag("hugging")
        desc += have+" a hug"
    elseif anim.HasTag("dildo")
        desc += is+" using a dildo"
        if actors.Length > 1
            desc += " with"
        endif
    else
        desc += have+" sex with"
    endif

    if actors.Length > 1
        desc += " " + dom_name
    endif
    desc += "."

    String[] desc_names = new String[3]
    desc_names[0] = desc
    desc_names[1] = names[0]
    desc_names[2] = names[1]
    return desc_names
endFunction