Scriptname SkyrimNet_SexLab_Main extends Quest

import JContainers
import UIExtensions
import SkyrimNet_SexLab_Decorators
import SkyrimNet_SexLab_Actions
import SkyrimNet_SexLab_Stages
import StorageUtil

ReferenceAlias[] Property nude_refs Auto


int Property BUTTON_YES Auto        ; 0
int Property BUTTON_YES_RANDOM Auto ; 1
int Property BUTTON_NO_SILENT Auto  ; 2
int Property BUTTON_NO Auto         ; 3

GlobalVariable Property sexlab_active_sex Auto
Bool Property active_sex 
    Bool Function Get()
        return sexlab_active_sex.GetValueInt() == 1
    EndFunction 
    Function Set(Bool value)
        if value
            sexlab_active_sex.SetValue(1.0)
        else
            sexlab_active_sex.SetValue(0.0)
        endif
    EndFunction 
EndProperty

Function Trace(String msg, Bool notification=False) global
    if notification
        Debug.Notification(msg)
    endif 
    msg = "[SkyrimNet_SexLab.Main] "+msg
    Debug.Trace(msg)
EndFunction

bool Property rape_allowed = true Auto
bool Property sex_edit_tags_player = true Auto 
bool Property sex_edit_tags_nonplayer = False Auto

int Property actorLock = 0 Auto 
float Property actorLockTimeout = 0.00069444444 Auto ;  1 day / (24 hours  * 60 minutes ) 

int Property group_info = 0 Auto
int Property group_ordered = 0 Auto

int skynet_tag_sex_lock = 0 

String Property storage_items_key = "skyrimnet_sexlab_storage_items" Auto
String Property storage_arousal_key = "skyrimnet_sexlab_arousal_level" Auto

SkyrimNet_SexLab_Stages Property stages Auto

Event OnInit()
    Trace("OnInit")
    rape_allowed = true

    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()

    ; Set up the Buttons 
    BUTTON_YES = 0 
    BUTTON_YES_RANDOM = 1
    BUTTON_NO_SILENT = 2 
    BUTTON_NO = 3

    Trace("SetUp")

    ; Setup related Scripts 
    if stages == None
        stages = (self as Quest) as SkyrimNet_SexLab_Stages
    endif 
    stages.Setup() 
    active_sex = false

    SkyrimNet_SexLab_MCM mcm = (self as Quest) as SkyrimNet_SexLab_MCM
    mcm.Setup() 

    if actorLock == 0 
        actorLock = JFormMap.object() 
        JValue.retain(actorLock)
        ActorLockTimeout = 60.0
    elseif JFormMap.count(actorLock) > 0
        Form[] forms = JFormMap.allKeysPArray(actorLock)
        if forms != None 
            int i = forms.Length
            while i >= 0
                ReleaseActorLock(forms[i] as Actor)
                i -= 1
            endwhile 
        endif
    endif 

    if group_info == 0
        group_info = JValue.readFromFile("Data/SkyrimNet_Sexlab/group_tags.json")
        JValue.retain(group_info)
    else
        int group_info_new = JValue.readFromFile("Data/SkyrimNet_Sexlab/group_tags.json")
        Jvalue.releaseAndRetain(group_info, group_info_new)
        group_info = group_info_new
    endif

    RegisterSexlabEvents()
    SkyrimNet_SexLab_Actions.RegisterActions()
    SkyrimNet_SexLab_Decorators.RegisterDecorators() 

EndFunction
;----------------------------------------------------------------------------------------------------
; Stripped Items Storage
;----------------------------------------------------------------------------------------------------

Function StoreStrippedItems(Actor akActor, Form[] forms)
    if akActor == None || forms.Length == 0
        return 
    endif 
    Trace("AddStrippedItems: "+akActor.GetDisplayName()+" num_items:"+forms.Length)
    StorageUtil.FormListClear(akActor, storage_items_key)
    int i = 0
    while i < forms.Length
        StorageUtil.FormListAdd(akActor, storage_items_key, forms[i])
        i += 1
    endwhile

    i = nude_refs.Length - 1
    while 0 <= i 
        if nude_refs[i].GetActorReference() == None 
            nude_refs[i].ForceRefTo(akActor) 
            i = -1
        endif 
        i -= 1 
    endwhile 
EndFunction 

Form[] Function UnStoreStrippedItems(Actor akActor)
    Trace("UnStoreStrippedItems: "+akActor.GetDisplayName()+" attempting to undress")
    int i = nude_refs.length - 1
    while 0 <= i 
        if nude_refs[i].GetActorReference() == akActor 
            nude_refs[i].Clear() 
            Utility.Wait(1.00)
            i = -1
        endif 
        i -= 1 
    endwhile 
    if !HasStrippedItems(akActor)
        return None
    endif
    Form[] forms = StorageUtil.FormListToArray(akActor, storage_items_key)
    StorageUtil.FormListClear(akActor, storage_items_key)
    return forms
EndFunction

Bool Function HasStrippedItems(Actor akActor)
    if akActor == None || StorageUtil.FormListCount(akActor, storage_items_key) == 0
        return False
    endif 
    return true 
EndFunction

;----------------------------------------------------------------------------------------------------
; Actor Lock
;----------------------------------------------------------------------------------------------------

Bool Function IsActorLocked(Actor akActor) 
    bool locked = False
    if akActor != None 
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

bool Function SetActorLock(Actor akActor) 
    if akActor == None || IsActorLocked(akActor)
        return false 
    endif 
    Trace("SetActorLock: "+akActor.GetDisplayName())
    JFormMap.setFlt(actorLock, akActor, Utility.GetCurrentGameTime())
    return true
EndFunction

Function ReleaseActorLock(Actor akActor) 
    if akActor == None 
        return 
    endif 
    Trace("ReleaseActorLock: "+akActor.GetDisplayName())
    JFormMap.removeKey(actorLock, akActor)
EndFunction

;----------------------------------------------------------------------------------------------------
bool Function Tag_SexAnimation(Actor akActor) 
    if akActor == None 
        return false 
    endif 
    if MiscUtil.FileExists("Data/SexLab.esm") 
        SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
        return SexLab.AnimSlots.IsRegistered(akActor)
    endif
    return false
EndFunction


;----------------------------------------------------------------------------------------------------
; SexLab Events
;----------------------------------------------------------------------------------------------------
Function RegisterSexlabEvents() 
    Trace("RegisterSexlabEvents called")
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
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Trace("[SkyrimNet_SexLab] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions

    int i = actors.length - 1
    while 0 <= i 
        ReleaseActorLock(actors[i])
        i -= 1
    endwhile 

    Sex_Event(ThreadID, "start", HasPlayer )
    active_sex = true
endEvent

Event StageStart(int ThreadID, bool HasPlayer)

    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Trace("[SkyrimNet_SexLab] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    AllowedDeniedOnlyIncrease(thread.positions, thread, "stage") 

    if !stages.IsThreadTracking(ThreadID)
        return
    endif 
    bool[] desc_denied = stages.HasDescriptionOrgasmDenied(thread)
    String desc = "" 
    if desc_denied[0]
        desc = "has description"
    endif
    if desc_denied[1]
        if desc != ""
            desc += " and "
        endif 
        desc += "orgasm denied"        
    endif
    Debug.Notification("stage "+thread.stage+" of "+ thread.animation.StageCount()+" "+desc)

EndEvent

Event OrgasmStart(int ThreadID, bool HasPlayer)
    Orgasm_Event(ThreadID)
EndEvent

event AnimationEnd(int ThreadID, bool HasPlayer)
    ; String desc = stages.GetStageDescription(SexLab.GetController(ThreadID))
    ; if desc != ""
        ; Actor[] actors = SexLab.GetController(ThreadID).Positions
        ; desc = stages.Description_Add_Actors(s, desc)
        ; Skyrim
    ; endif 
    Sex_Event(ThreadID, "stop", HasPlayer )

   sslThreadSlots ThreadSlots = Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadSlots
    if ThreadSlots == None
        Trace("[SkyrimNet_SexLab] Get_Threads: ThreadSlots is None", true)
        return
    endif

    sslThreadController[] threads = ThreadSlots.Threads

    int i = 0
    bool found = false
    while i < threads.length && !found
        String s = (threads[i] as sslThreadModel).GetState()
        if s == "animating" || s == "prepare"
            found = true
        endif 
    endwhile
    if found
        active_sex = true
    else 
        active_sex = false
    endif
endEvent

Function Sex_Event(int ThreadID, String status, Bool HasPlayer )
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Trace("[SkyrimNet_SexLab] Thread_Dialog: SexLab is None", true)
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions

    String narration = Thread_Narration(SexLab.GetController(ThreadID), status)

    ; the Dialog narration is called so that it is stored in the timeline and captured in memories,
    ; and will be responded by t
    String eventType = "sex "+status
    ; narration = "*"+narration+"*"
    if actors.length < 2 || actors[0] == actors[1]
        if status == "start"
            SkyrimNetApi.DirectNarration(narration, actors[0], None)
        else
            ;if actors.length == 1 || actors[0] == actors[1]
                ;SkyrimNetApi.RegisterDialogue(actors[0], "*"+narration+"*")
            ;else
                ;SkyrimNetApi.RegisterDialogueToListener(actors[1], actors[0], "*"+narration+"*")
            ;endif 
            SkyrimNetApi.RegisterEvent(eventType, "*"+narration+"*", actors[0], None)
        endif 
    elseif actors.length == 2
        if status == "start"
            SkyrimNetApi.DirectNarration(narration, actors[1], actors[0])
        else
            SkyrimNetApi.RegisterEvent(eventType, "*"+narration+"*", actors[1], actors[0])
            ;SkyrimNetApi.RegisterDialogueToListener(actors[1], actors[0], "*"+narration+"*")
        endif 
    else
        SkyrimNetApi.RegisterEvent(eventType, narration,None,None)
    endif 

    AllowedDeniedOnlyIncrease(actors, thread, status) 
EndFunction

Function AllowedDeniedOnlyIncrease(Actor[] actors, sslThreadController thread, String status)
    if !MiscUtil.FileExists("Data/SexLabAroused.esm") 
        return
    endif
    ; Store orgasm denied actor's arousal level before sex, It is not allowed to lower 
    ;q = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as Quest
    ;SkyrimNet_SexLab_main main = q as SkyrimNet_SexLab_Main
    ;SkyrimNet_SexLab_Stages stages_lib = q as SkyrimNet_SexLab_Stages
    int[] orgasm_denied = stages.GetOrgasmDenied(thread)
    int satisifcation_idx = slaInternalModules.RegisterStaticEffect("Orgasm")

    int i = orgasm_denied.length - 1
    while 0 <= i    
        float sat_value = slaInternalModules.GetStaticEffectValue(actors[i], satisifcation_idx)
        if orgasm_denied[i] == 1
            if status == "start"
                StorageUtil.SetFloatValue(actors[i], storage_arousal_key, sat_value)
            else
                float stored_value = StorageUtil.GetFloatValue(actors[i], storage_arousal_key)
                if stored_value < sat_value
                    StorageUtil.SetFloatValue(actors[i], storage_arousal_key, sat_value)
                elseif stored_value > sat_value
                    slaInternalModules.SetStaticArousalValue(actors[i], satisifcation_idx, stored_value)
                    Trace(actors[i].GetDisplayName()+" orgasm denied, so erasing orgasm satisifaction "+sat_value+" -> "+stored_value)
                endif 
            endif 
        endif 
        sat_value = slaInternalModules.GetStaticEffectValue(actors[i], satisifcation_idx)
        i -= 1
    endwhile
EndFunction

Function Orgasm_Event(int ThreadID)
    
    Quest q = Game.GetFormFromFile(0xD62, "SexLab.esm") as Quest 
    SexLabFramework SexLab = q  as SexLabFramework
    sslActorLibrary ActorLib = q as sslActorLibrary

    
    ; Store orgasm denied actor's arousal level before orgasm, we need to prevent the denied orgasm lower it 

    if SexLab == None
        Trace(" Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions

    AllowedDeniedOnlyIncrease(actors, thread, "orgasm") 

    String[] names = new String[2]
    names[0] = actors[0].GetDisplayName()
    if actors.length > 1
        names[1] = actors[1].GetDisplayName()
    endif 
    bool[] can_ejaculate = new Bool[2]
    can_ejaculate[0] = Actorlib.GetGender(actors[0]) != 1
    if actors.length > 1
        can_ejaculate[1] = Actorlib.GetGender(actors[1]) != 1
    endif 

    sslBaseAnimation anim = thread.Animation

    q = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as Quest
    SkyrimNet_SexLab_main main = q as SkyrimNet_SexLab_Main
    SkyrimNet_SexLab_Stages stages_lib = q as SkyrimNet_SexLab_Stages
    int[] orgasm_denied = stages_lib.GetOrgasmDenied(thread)

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

        if position < orgasm_denied.length && orgasm_denied[position] == 1
            narration += names[position]+" was denied orgasm. "
        elseif can_ejaculate[position]

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
    ;String desc = GetStageDescription(thread)
    ;if desc != ""
    ;    narration = desc+" "+narration
    ;endif 

    SkyrimNetApi.DirectNarration(narration)
EndFunction  

;----------------------------------------------------
; Parses the tags
;----------------------------------------------------
String Function Thread_Narration(sslThreadController thread, String status) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Trace("[SkyrimNet_SexLab] GetThreadDescription: SexLab is None")
        return None
    endif
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main

    ; Get the thread that triggered this event via the thread id
    sslBaseAnimation anim = thread.Animation
    ; Get our list of actors that were in this animation thread.
    Actor[] actors = thread.Positions

    if actors.length == 1 
        if status == "start"
            return actors[0].GetDisplayName()+" starts masturbating."
        elseif status == "are"
            return actors[0].GetDisplayName()+" is masturbating."
        else
            return actors[0].GetDisplayName()+" stops masturbating."
        endif 
    else
        int num_victims = 0
        int k = actors.length - 1
        while 0 <= k 
            if thread.IsVictim(actors[k])
                num_victims += 1   
            endif 
            k -= 1
        endwhile

        if num_victims == 0
            String actors_str = ActorsToString(actors)
            if status == "start" 
                return actors_str+" starts having sex."
            elseif status == "are"
                return actors_str+" is having sex."
            else 
                return actors_str+" stops having sex."
            endif 
        else
            Actor[] victims = PapyrusUtil.ActorArray(num_victims)
            Actor[] aggressors = PapyrusUtil.ActorArray(actors.length - num_victims)
            int v = 0
            int a = 0 
            k = actors.length - 1
            while 0 <= k 
                if thread.IsVictim(actors[k])
                    victims[v] = actors[k]
                    v += 1
                else 
                    aggressors[a] = actors[k]
                    a += 1
                endif 
                k -= 1
            endwhile
            String victims_str = ActorsToString(victims)
            String aggressors_str = ActorsToString(aggressors)
            if status == "start"
                return aggressors_str+" starts raping "+victims_str+"."
            elseif status == "are"
                return aggressors_str+" is raping "+victims_str+"."
            else 
                return aggressors_str+" stops raping "+victims_str+"."   
            endif 
        endif 

    endif
EndFunction 
String Function ActorsToString(Actor[] actors) global
    String names = ""
    int k = 0
    int count = actors.length
    while k < count 
        if k > 0
            if count > 2 && k > 0
                names += ", "
            endif
            if k == count - 1 
                names += " and "
            endif
        endif
        names += actors[k].GetDisplayName()
        k += 1
    endwhile 
    return names 
endFunction

String Function ActorsToJson(Actor[] actors) global
    String json = "["
    int i = 0
    int count = actors.length
    while i < count 
        if i > 0
            json += ", "
        endif 
        json += "\""+actors[i].GetDisplayName()+"\""
        i += 1
    endwhile 
    json += "]"
    return json 
EndFunction 

;----------------------------------------------------
; Yes No dialogue chooice for the player 
;----------------------------------------------------

; Allows the user to choose to accept the sex act choosen by the LLM 
; The value will between 
; 1 Yes with the editor 
; 2 Yes, but no tag editor 
; 3 No (silent), refused, but don't tell the LLM 
; 4 NO, tell the LLM 
int function YesNoSexDialog(String type, Bool rape, Actor domActor, Actor subActor, Actor player)

    if subActor != player && (domActor == None || domActor != player)
        return BUTTON_YES
    endif  

    String[] buttons = new String[4]
    buttons[BUTTON_YES] = "Yes "
    buttons[BUTTON_YES_RANDOM] = "Yes (Random)"
    buttons[BUTTON_NO_SILENT] = "No (Silent)"
    buttons[BUTTON_NO] = "No "

    String player_name = domActor.GetDisplayName()
    String npc_name = subActor.GetDisplayName()

    if subActor == player
        String temp = npc_name 
        npc_name = player_name 
        player_name = npc_name 
    endif
    String question = ""
    if rape
        if domActor == player
            question = "Would like to rape "+npc_name+"?"
        else
            question = "Would like to be raped by "+npc_name+"?"
        endif 
    elseif type == "kissing"
        question = "Would like to kissing "+npc_name+"?"
    else
        question = "Would like to have sex "+npc_name+"?"
    endif 
    
    int button = SkyMessage.ShowArray(question, buttons, getIndex = true) as int  
    if button == BUTTON_NO || button == BUTTON_NO_SILENT
        if button == BUTTON_NO 
            if !rape
                String msg = "*"+player_name+" refuses "+npc_name+"'s sex request*"
                SkyrimNetApi.RegisterEvent("sex refuses", msg, domActor, subActor)
            elseif domActor == player 
                String msg = "*"+player_name+" refuses to rape "+npc_name+".*"
                SkyrimNetApi.RegisterEvent("rape refuses", msg, domActor, subActor)
            else
                String msg = "*"+player_name+" refuses "+npc_name+"'s rape attempt.*"
                SkyrimNetApi.RegisterEvent("rape refuses", msg, subActor, domActor)
            endif
        endif
    endif 
    return button 
EndFunction


; This function returns the list of animations matching the requested animations
; If no animations were selected, it will return an array with a single None value `[None]`
; 
;   anims = AnmisDialog(sexlab. actors, tag) 
;   if anims.length > 0 && anims[0] != None 
;        thread.SetAnimations(anims)
;   endif 
;
sslBaseAnimation[] Function AnimsDialog(SexLabFramework sexlab, Actor[] actors, String tag)

    Actor player = Game.GetPlayer() 

    int i = 0
    int count = actors.Length
    String names = ""
    bool includes_player = False 
    while i < count
        if actors[i] == player 
            includes_player = True 
        endif 
        if names != ""
            names += "+" 
        endif
        names += actors[i].GetDisplayName()
        i += 1 
    endwhile
    names += " | "

    ; Check if enabled by MCM 
    sslBaseAnimation[] empty = new sslBaseAnimation[1]
    empty[0] = None 

    if (!includes_player || !sex_edit_tags_player) && (includes_player || sex_edit_tags_nonplayer)
        return empty 
    endif 

    ; Current set of tags
    String[] tags = new String[10]
    int count_max = 10
    int next = 0
    if tag != ""
        tags[next] = tag
        next += 1
    endif 

    ; the order of the groups 
    int group_tags = JMap.getObj(group_info,"group_tags",0)
    if group_tags == 0 
        Trace("AnimsDialog", "group_tags not found in group_tags.json")
        return None
    endif 

    int groups = JMap.getObj(group_tags,"groups",0)
    if groups == 0
        groups = JMap.allKeys(group_tags)
    endif 

    while True
        bool finished = false
        String tags_str= ""
        while next < count_max && !finished

            ; build the current tags
            tags_str = "" 
            i = 0
            while i < next
                if i > 0 
                    tags_str += ","
                endif 
                tags_str += tags[i]
                i += 1
            endwhile 


            uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") AS uilistmenu
            listMenu.ResetMenu()
            ; Use the current set of tags 
            String use_tags = names + " tags: "+tags_str
            listMenu.AddEntryItem(use_tags)
            ; Remove one tag 
            if 0 < next 
                listMenu.AddEntryItem("<remove")
            endif 

            ; Add groups
            count = JArray.count(groups)
            i =  0
            while i < count
                String group = JArray.getStr(groups,i)
                listMenu.AddEntryItem(group)
                i += 1
            endwhile


            ; add the actions 
            ;ListAddTags(listMenu, group_tags, "actions>") 

            ; just give up
            listMenu.AddEntryItem("<cancel>")

            listMenu.OpenMenu()
            String button =  listmenu.GetResultString()
            if JMap.hasKey(group_tags, button)
                button = GroupDialog(group_tags, button)
            endif 

            if button == "<cancel>"
                return empty
            elseif button == "<remove"
                next -= 1
            elseif button == use_tags
                finished = true
            elseif button != "-continue-"
                tags[next] = button 
                next += 1
            endif 
        endwhile 
        sslBaseAnimation[] anims =  SexLab.GetAnimationsByTags(actors.length, tags_str, "", true)
        if anims.length > 0
            return anims 
        else
            Trace("SkyrimNet_SexLab_Utils No animations found for: "+tags_str, true)
        endif 
    endwhile 
    return empty
EndFunction

Function ListAddTags(uilistmenu listMenu, int group_tags, String group) global
    int tags = JMap.getObj(group_tags, group, 0)
    if tags != 0 
        int i = 0
        int count = JArray.count(tags)
        while i < count
            String tag = JArray.getStr(tags, i, "")
            if tag != ""
                listMenu.AddEntryItem(tag)
            endif
            i += 1
        endwhile 
    endif 
EndFunction

String Function GroupDialog(int group_tags, String group)  global
    uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") AS uilistmenu
    listMenu.ResetMenu()
    listMenu.AddEntryItem("<back")
    ListAddTags(listMenu, group_tags, group) 
    listMenu.OpenMenu()
    String button =  listmenu.GetResultString()
    if button == "<back"
        button = "-continue-"
    endif 
    return button
EndFunction
