Scriptname SkyrimNet_SexLab_Main extends Quest

import JContainers
import UIExtensions
import SkyrimNet_SexLab_Decorators
import SkyrimNet_SexLab_Actions

bool Property rape_allowed = true Auto
bool Property public_sex_accepted = false Auto 

int Property actorLock = 0 Auto 
float Property actorLockTimeout = 60.0 Auto

int Property group_tags = 0 Auto
int Property group_ordered = 0 Auto

Event OnInit()
    rape_allowed = true
    Debug.Trace("[SkyrimNet_SexLab] OnInit")
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent



Function Setup()
    Debug.Trace("[SkyrimNet_SexLab] SetUp")

    if actorLock == 0 
        actorLock = JFormMap.object() 
        JValue.retain(actorLock)
        ActorLockTimeout = 60.0
    Else
        Form[] forms = JFormMap.allKeysPArray(actorLock)
        int i = forms.Length
        while i >= 0
            ReleaseActorLock(forms[i] as Actor)
            i -= 1
        endwhile 
    endif 

    if group_tags == 0
        group_tags = JValue.readFromFile("Data/SkyrimNet_Sexlab/group_tags.json")
        group_ordered
        JValue.retain(group_tags)
    else
        int group_tags_new = JValue.readFromFile("Data/SkyrimNet_Sexlab/group_tags.json")
        Jvalue.releaseAndRetain(group_tags, group_tags_new)
        group_tags = group_tags_new
    endif

    RegisterSexlabEvents()
    SkyrimNet_SexLab_Actions.RegisterActions()
    SkyrimNet_SexLab_Decorators.RegisterDecorators() 
    RegisterSexLabEvents()

    Debug.Trace("SkyrimNet_SexLab_Main Finished registration")

EndFunction
;----------------------------------------------------------------------------------------------------
; Utility function
;----------------------------------------------------------------------------------------------------

Function Trace(String msg, Bool notification=False) global
    msg = "[SkyrimNet_SexLab_Main] "+msg
    Debug.Trace(msg)
    if notification
        Debug.Notification(msg)
    endif 
EndFunction


;----------------------------------------------------------------------------------------------------
; Actor Lock
;----------------------------------------------------------------------------------------------------

Bool Function IsActorLocked(Actor akActor) 
    bool locked = False
    if akActor == None 
        if JFormMap.hasKey(actorLock, akActor) 
            float time = JFormMap.getFlt(actorLock, akActor) 
            if Utility.GetCurrentGameTime() - time > actorLockTimeout
                JFormMap.removeKey(actorLock, akActor)
                locked = False
            else
                locked = True
            endif 
        endif 
        Trace("IsActorLocked: "+akActor.GetDisplayName()+" "+locked)
    endif 
    return locked 
EndFunction

Function SetActorLock(Actor akActor) 
    if akActor == None 
        return 
    endif 
    Trace("SetActorLock: "+akActor.GetDisplayName())
    JFormMap.setFlt(actorLock, akActor, Utility.GetCurrentGameTime())
EndFunction

Function ReleaseActorLock(Actor akActor) 
    if akActor == None 
        return 
    endif 
    Trace("ReleaseActorLock: "+akActor.GetDisplayName())
    JFormMap.removeKey(actorLock, akActor)
EndFunction

;----------------------------------------------------------------------------------------------------
; SexLab Events
;----------------------------------------------------------------------------------------------------
Function RegisterSexlabEvents() 
    Debug.Trace("SkyrimNet_SexLab_Main: RegisterSexlabEvents called")
    ; SexLabFramework sexlab = Game.GetForm

    UnRegisterForModEvent("HookAnimationStart")
    RegisterForModEvent("HookAnimationStart", "AnimationStart")
    ;UnRegisterForModEvent("HookStageStart")
    ;RegisterForModEvent("HookStageStart", "StageStart")
    ;UnRegisterForModEvent("HookStageEnd")
    ;RegisterForModEvent("HookStageEnd", "SexLab_StageEnd")
    UnRegisterForModEvent("HookOrgasmStart")
    RegisterForModEvent("HookOrgasmStart", "OrgasmStart")
    UnRegisterForModEvent("HookAnimationEnd")
    RegisterForModEvent("HookAnimationEnd", "AnimationEnd")
EndFunction 

event AnimationStart(int ThreadID, bool HasPlayer)
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SkyrimNet_SexLab] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions
    ReleaseActorLock(actors[0])
    ReleaseActorLock(actors[1])

;    Sex_Dialog(ThreadID, true, HasPlayer )
endEvent

;Event StartStage(int ThreadID, bool HasPlayer)
;EndEvent

Event OrgasmStart(int ThreadID, bool HasPlayer)
    Orgasm_Dialog(ThreadID)
EndEvent

event AnimationEnd(int ThreadID, bool HasPlayer)
    Sex_Dialog(ThreadID, false, HasPlayer )
endEvent

Function Sex_Dialog(int ThreadID, bool starting, Bool HasPlayer ) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SkyrimNet_SexLab] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions

    String narration = thread_Narration(SexLab.GetController(ThreadID), starting)
    if starting && HasPlayer
        debug.Notification(narration)
    endif

    ; the Dialog narration is called so that it is stored in the timeline and captured in memories,
    ; and will be responded by t
    if actors.length < 2 || actors[0] == actors[1]
        SkyrimNetApi.RegisterDialogue(actors[0], "*"+narration+"*")
        ;SkyrimNetApi.RegisterEvent("SexLab", narration, actors[0], None)
    elseif actors.length == 2
        SkyrimNetApi.RegisterDialogueToListener(actors[1], actors[0], "*"+narration+"*")
        ;SkyrimNetApi.RegisterEvent("SexLab", narration, actors[1], actors[0])
    else
        SkyrimNetApi.RegisterDialogue(None, "*"+narration+"*")
        ;SkyrimNetApi.RegisterEvent("SexLab", narration,None,None)
    endif 
EndFunction

Function Orgasm_Dialog(int ThreadID) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SkyrimNet_SexLab] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions
    String[] names = new String[2]
    names[0] = actors[0].GetDisplayName()
    names[1] = actors[1].GetDisplayName()
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
    ;SkyrimNetApi.RegisterShortLivedEvent("sexLab orgasm "+threadId, narration, narration,
    ;    "", 60000, actors[1], actors[0])
    ; This adds it to the time line 
    ;SkyrimNetApi.RegisterDialogueToListener(actors[1], actors[0], narration)
    ; This makes the ackors respond
    SkyrimNetApi.DirectNarration(narration, actors[1], actors[0])
EndFunction  

;----------------------------------------------------
; Parses the tags
;----------------------------------------------------
String Function Thread_Narration(sslThreadController thread, bool starting) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SkyrimNet_SexLab] GetThreadDescription: SexLab is None")
        return None
    endif
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main

    ; Get the thread that triggered this event via the thread id
    sslBaseAnimation anim = thread.Animation
    ; Get our list of actors that were in this animation thread.
    Actor[] actors = thread.Positions

    ; Handle an orgy
    String narration = "" 
    if actors.length > 2
        int k = 0
        while k < actors.length
            if k == actors.length - 1
                narration += ", and "
            elseif k > 0
                narration += ", "
            endif 
            narration += actors[k].GetDisplayName()
            k += 1
        endwhile 
        if starting
            narration += " start "
        else
            narration += " finish "
        endif 
        narration += " having an orgry."
    endif 

    String[] names = new String[2]
    names[0] = actors[0].GetDisplayName()
    names[1] = actors[1].GetDisplayName()

    String sub_name = names[0]
    String dom_name = names[1]
    Debug.Trace("[SkyrimNet_SexLab] sub: "+sub_name+" dom: "+dom_name+" count: "+actors.Length)

    narration += dom_name
    if starting
        narration += " starts"
    else
        narration += " finishes "
    endif 
    narration += " having sex with "

    String bondage = "" 
    if anim.HasTag("bound")
        bondage += " a bound "
        String[] b_types = SkyrimNet_SexLab_Actions.GetBondages()
        int j = 0 
        int num = b_types.Length
        while j < num
            if anim.HasTag(b_types[j])
                bondage += " with a "+b_types[j]+" "
                j = num 
            endif 
            j += 1
        endwhile
        if actors.length == 0
            narration += bondage 
        endif 
    endif

    if anim.HasTag("rough")
        narration += " roughly "
    elseif anim.HasTag("loving")
        narration += " lovingly "
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



    String[] positions = new String[7]
    positions[0] = "69"
    positions[1] = "cowgirl"
    positions[2] = "missionary"
    positions[3] = "kneeling"
    positions[4] = "doggy"
    positions[5] = "sitting"
    positions[6] = "standing"

    int i = 0
    bool found = false
    while i < positions.Length && !found
        if anim.HasTag(positions[i])
            narration += ", " + positions[i] + " position,"
            found = true
        endif
        i += 1
    endwhile

    if actors.Length > 1
        narration += sexing+type + bondage + sub_name
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