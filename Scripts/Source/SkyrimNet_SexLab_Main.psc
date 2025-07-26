Scriptname SkyrimNet_SexLab_Main extends Quest

import JContainers
import UIExtensions
import SkyrimNet_SexLab_Decorators
import SkyrimNet_SexLab_Actions
import SkyrimNet_SexLab_Stages

GlobalVariable Property sexlab_public_sex_accepted Auto
Bool Property public_sex_accepted 
    Bool Function Get()
        return sexlab_public_sex_accepted.GetValue() == 1
    EndFunction 
    Function Set(Bool value)
        if value
            sexlab_public_sex_accepted.SetValue(1)
        else
            sexlab_public_sex_accepted.SetValue(0)
        endif
    EndFunction 
EndProperty

bool Property rape_allowed = true Auto
bool Property sex_edit_tags_player = true Auto 
bool Property sex_edit_tags_nonplayer = False Auto

int Property actorLock = 0 Auto 
float Property actorLockTimeout = 60.0 Auto

int Property group_tags = 0 Auto
int Property group_ordered = 0 Auto

;SexLabFramework SexLab = None
;SkyrimNet_SexLab_Stages stages = None

Event OnInit()
    Debug.Trace("[SkyrimNet_SexLab] OnInit")
    rape_allowed = true
    public_sex_accepted = False 

    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()
    Debug.Trace("[SkyrimNet_SexLab] SetUp")

    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    SkyrimNet_SexLab_Stages stages = (self as Quest) as SkyrimNet_SexLab_Stages
    stages.Setup() 

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

    Sex_Event(ThreadID, "start", HasPlayer )
endEvent

;Event StartStage(int ThreadID, bool HasPlayer)
;EndEvent

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
endEvent

Function Sex_Event(int ThreadID, String status, Bool HasPlayer ) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SkyrimNet_SexLab] Thread_Dialog: SexLab is None")
        return  
    endif
    sslThreadController thread = SexLab.GetController(ThreadID)
    Actor[] actors = thread.Positions

    String narration = Thread_Narration(SexLab.GetController(ThreadID), status)

    ; the Dialog narration is called so that it is stored in the timeline and captured in memories,
    ; and will be responded by t
    String eventType = "sex "+status
    ; narration = "*"+narration+"*"
    String s = (thread as sslThreadModel).GetState()
    ; Debug.MessageBox(status+" "+narration+" state:"+s)
    if actors.length < 2 || actors[0] == actors[1]
        if status == "start"
            SkyrimNetApi.DirectNarration(narration, actors[0], None)
        else
            SkyrimNetApi.RegisterEvent(eventType, narration, actors[0], None)
        endif 
    elseif actors.length == 2
        if status == "start"
            SkyrimNetApi.DirectNarration(narration, actors[1], actors[0])
        else
            SkyrimNetApi.RegisterEvent(eventType, narration, actors[1], actors[0])
        endif 
    else
        ;SkyrimNetApi.RegisterEvent(eventType, narration,None,None)
    endif 
EndFunction

Function Orgasm_Event(int ThreadID) global
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
    String desc = GetStageDescription(thread)
    if desc != ""
        narration = desc+" "+narration
    endif 

    ;SkyrimNetApi.DirectNarration(narration, actors[1], actors[0])
    SkyrimNetApi.DirectNarration(narration)
EndFunction  

;----------------------------------------------------
; Parses the tags
;----------------------------------------------------
String Function Thread_Narration(sslThreadController thread, String status) global
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
            String actors_str = ActorsToString(actors, status)
            if status == "start" 
                return actors_str+" start having sex."
            elseif status == "are"
                return actors_str+" are having sex."
            else 
                return actors_str+" stop having sex."
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
            String victims_str = ActorsToString(victims, status)
            String aggressors_str = ActorsToString(aggressors, status)
            if status == "start"
                return aggressors_str+" start raping "+victims_str+"."
            elseif status == "are"
                return aggressors_str+" are raping "+victims_str+"."
            else 
                return aggressors_str+" stop raping "+victims_str+"."   
            endif 
        endif 

    endif
EndFunction 
String Function ActorsToString(Actor[] actors, String status) global
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

