Scriptname SexLab_SkyrimNet_Main extends Quest

import JContainers
import UIExtensions

Bool[] orgasmed_this_stage

int property creature_description_map Auto

String creature_description_fname = "Data/SexLab_SkyrimNet/creature-descriptions.json"

Event OnInit()
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()
    if orgasmed_this_stage == None
        orgasmed_this_stage = new Bool[15]
    endif 
    Debug.Trace("SexLab_SkyrimNet_Main: Startup called")

    RegisterSexlabEvents()
    SexLab_SkyrimNet_Decorators.RegisterDecorators() 
    SexLab_SkyrimNet_Actions.RegisterActions()
    RegisterSexLabEvents()

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
    UnRegisterForModEvent("HookStageStart")
    RegisterForModEvent("HookStageStart", "StageStart")
    ;UnRegisterForModEvent("HookStageEnd")
    ;RegisterForModEvent("HookStageEnd", "SexLab_StageEnd")
    UnRegisterForModEvent("HookOrgasmStart")
    RegisterForModEvent("HookOrgasmStart", "OrgasmStart")
    UnRegisterForModEvent("HookAnimationEnd")
    RegisterForModEvent("HookAnimationEnd", "AnimationEnd")
EndFunction 

event AnimationStart(int ThreadID, bool HasPlayer)
    Sex_Dialog(ThreadID, true )
endEvent

Event StartStage(int ThreadID, bool HasPlayer)
    orgasmed_this_stage[ThreadID] = false
EndEvent

Event OrgasmStart(int ThreadID, bool HasPlayer)
    orgasmed_this_stage[ThreadID] = true
    Orgasm_Dialog(ThreadID)
EndEvent

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

    String narration = thread_Narration(SexLab.GetController(ThreadID), starting)
    if actors.length < 2 || actors[0] == actors[1]
        SkyrimNetApi.RegisterDialogue(actors[0], "*"+narration+"*")
       ; SkyrimNetApi.DirectNarration(narration, actors[0])
    else
        SkyrimNetApi.RegisterDialogueToListener(actors[1], actors[0], "*"+narration+"*")
        ; SkyrimNetApi.DirectNarration(narration, actors[1], actors[0])
    endif 
EndFunction

Function PlaeHolder(int ThreadID, Bool starting) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions

    String narration = actors[1].GetLeveledActorBase().GetName()
    if starting
        narration += " starts "
    else
        narration += " finished "
    endif
    if actors.length == 1
        if thread.isAggressive 
            narration += " being forced "
        endif
        narration += " masturbating."
    else
        if thread.IsAggressive
            narration += " raping "
        else
            narration += " having sex with "
        endif
        narration += actors[0].GetLeveledActorBase().GetName()+"."
    endif 
    ;SkyrimNetApi.RegisterDialogueToListener(actors[0], actors[1], "*"+narration+"*")
    ;SkyrimNetApi.DirectNarration(dom_name+type+sub_name, actors[1], actors[0])
EndFunction

Function Orgasm_Dialog(int ThreadID) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions
    String[] names = new String[2]
    names[0] = actors[0].GetLeveledActorBase().GetName()
    names[1] = actors[1].GetLeveledActorBase().GetName()
    bool[] can_ejaculate = new Bool[2]
    can_ejaculate[0] = actors[0].GetLeveledActorBase().GetSex() != 1
    can_ejaculate[1] = actors[1].GetLeveledActorBase().GetSex() != 1

    sslBaseAnimation anim = thread.Animation

    int position = 0
    String narration = ""
    while position < actors.length
        int j = (position+1)%(names.length)

        Bool[] loc = new Bool[4]
        String[] loc_str = new String[4]
        int loc_anal = 0
        int loc_vaginal = 1
        int loc_oral = 2   
        int loc_chest = 3
        loc_str[loc_anal] = "ass"
        loc_str[loc_vaginal] = "pussy"     
        loc_str[loc_oral] = "mouth"
        loc_str[loc_chest] = "chest"

        if can_ejaculate[position]

            if anim.HasTag("anal")
                loc[loc_anal] = true
            elseif anim.HasTag("vaginal")
                loc[loc_vaginal] = true    
            elseif anim.HasTag("oral") || anim.HasTag("blowjob") || anim.HasTag("cunnilingus") || anim.HasTag("CumInMouth")
                loc[loc_oral] = true   
            elseif anim.HasTag("boobjob") 
                loc[loc_chest] = true      
            endif 

            int CumId = anim.GetCumId(position, thread.stage)
            if cumId > 0
                if cumId == sslObjectFactory.vaginal()
                    loc[loc_vaginal] = true
                elseif cumId == sslObjectFactory.oral()
                    loc[loc_oral] = true
                elseif cumId == sslObjectFactory.anal()
                    loc[loc_anal] = true
                elseif cumId == sslObjectFactory.VaginalOral()
                    loc[loc_vaginal] = true
                    loc[loc_oral] = true
                elseif cumId == sslObjectFactory.VaginalAnal()
                    loc[loc_vaginal] = true
                    loc[loc_anal] = true
                elseif cumId == sslObjectFactory.OralAnal()
                    loc[loc_oral] = true
                    loc[loc_anal] = true
                elseif cumId == sslObjectFactory.VaginalOralAnal()
                    loc[loc_vaginal] = true
                    loc[loc_oral] = true
                    loc[loc_anal] = true
                endif
            endif 
            if loc[loc_anal] || loc[loc_vaginal] || loc[loc_oral] || loc[loc_chest]
                narration += names[position] + " orgasmed, leaving warm sticky cum dripping from " + names[j] +"'s "

                int i = 0
                while i < loc_str.length
                    if loc[i]
                        narration += loc_str[i]
                        if i < loc_str.length - 1
                            narration += ", "
                        endif
                    endif
                    i += 1
                endwhile
                narration += ". "
            endif 
        else
            narration += names[position]+" orgasmed. "
        endif 
        position += 1
    endwhile
    if narration != ""
        narration = narration
    endif 
    ; SkyrimNetApi.DirectNarration(narration, actors[1], actors[0])
    SkyrimNetApi.RegisterDialogueToListener(actors[1], actors[0], " I'm cumming")
EndFunction  

;----------------------------------------------------------------------------------------------------
; Thread Prompt 
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
    
    ;String[] desc_names = SexLab_GetThreadDescription(thread, ongoing)
    ;String eventDesc = desc_names[0]
    ;String[] names = new String[2]
    ;names[0] = desc_names[1]
    ;names[1] = desc_names[2]
    ;Debug.Notification(eventDesc)
    ;SkyrimNetApi.RegisterShortLivedEvent("SexLab_SkyrimNet_"+threadID,\
        ;eventType, eventDesc, "", 10000,\
        ;actors[1], actors[0])

            
endFunction 


;----------------------------------------------------
; Parses the tags
;----------------------------------------------------
String Function Thread_Narration(sslThreadController thread,bool ongoing=False) global
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

    String narration = "" 
    int i = 0
    while i < actors.length
        Race r = actors[i].GetLeveledActorBase().GetRace()
        if JMap.hasKey(main.creature_description_map, r.getName())
            narration += actors[i].GetLeveledActorBase().GetName()+" is a "+r.getName()+". "\
                +JMap.getStr(main.creature_description_map, r.getName())
            names[i] = "a "+r.getName() 
        endif
        i += 1
    endwhile
    String sub_name = names[0]
    String dom_name = names[1]
    Debug.Trace("[SexLab_SkyrimNet] sub: "+sub_name+" dom: "+dom_name+" count: "+actors.Length)


    narration += dom_name
    if ongoing
        narration += " starts "
    else
        narration += " finished "
    endif 
    if anim.HasTag("rough")
        narration += " roughly"
    elseif anim.HasTag("loving")
        narration += " lovingly"
    endif

    if anim.HasTag("bestiality")
        narration += " bestiality "
    endif
    if anim.HasTag("behind")
        narration += " from behind"
    endif

    String sexing = " fucking "
    if thread.IsAggressive
        sexing = " raping "
    endif


    string type = "" 
    if anim.HasTag("anal") || anim.HasTag("assjob")
        type = " the ass of "
    elseif anim.HasTag("boobjob")
        type = " getting a boobjob from"
    elseif anim.HasTag("thighjob")
        type = " by a getting a thighjob from"
    elseif anim.HasTag("vaginal")
        type = " pussy of "
    elseif anim.HasTag("fisting")
        type = " by fisting pussy of "
    elseif anim.HasTag("oral") || anim.HasTag("blowjob") || anim.HasTag("cunnilingus")
        type = " the mouth of "
    elseif anim.HasTag("spanking")
        if thread.IsAggressive
            sexing = " sexually assulting by "
        else
            sexing = " sexually "
        endif 
        type = " spanking the bottom of " 
    elseif anim.HasTag("masturbation")
        sexing = " masturbating furiously."
    elseif anim.HasTag("fingering")
        type = " by fingered the pussy of "
    elseif anim.HasTag("footjob")
        type = " by getting a footjob from "
    elseif anim.HasTag("handjob")
        type = " by getting a handjob from "
    elseif anim.HasTag("kissing")
        type = " kisses with "
    elseif anim.HasTag("headpat")
        type = " by patting the head of "
    elseif anim.HasTag("hugging")
        type = " by hugging with "
    elseif anim.HasTag("dildo")
        type = " with a dildo "
        if actors.Length > 1
            type = " into "
        endif
    else
        type = " sex with"
    endif

    if anim.HasTag("bound")
        narration += " bound"
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
            narration += ", " + positions[i] + " position,"
            found = true
        endif
        i += 1
    endwhile

    if actors.Length > 1
        narration += sexing+type + sub_name
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
            narration += " on a " + on_furniture[i]+" "
            found = true
        endif
        i += 1
    endwhile
    
    if !found 
        int bed = thread.BedTypeId
        if bed == 0
            narration += " on the floor "
        elseif bed == 1
            narration += " on a bedroll "
        elseif bed == 2
            narration += " on a single bed "
        elseif bed == 3
            narration += " on a double bed "
        endif 
    endif 

    if anim.HasTag("Cage")
        narration += " in a cage"
    elseif anim.HasTag("Gallows")
        narration += " in a gallows"
    elseif anim.HasTag("coffin")
        narration += " in a coffin"
    elseif anim.HasTag("floating")
        narration += " floating in air"
    elseif anim.HasTag("tentacles")
        narration += " with tentacles"
    elseif anim.HasTag("gloryhole") || anim.HasTag("gloryholem")
        narration += " through a gloryhole"
    elseif !found && anim.HasTag("Furniture")
        Debug.Trace("miss furniture")
    endif
    narration += "."

    return narration
endFunction