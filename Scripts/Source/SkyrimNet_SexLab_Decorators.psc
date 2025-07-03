Scriptname SkyrimNet_SexLab_Decorators

;----------------------------------------------------------------------------------------------------
; Decorators 
;----------------------------------------------------------------------------------------------------
Function RegisterDecorators() global
    Debug.Trace("SkyrimNet_SexLab_Decorators: RegisterDecorattors called")
    SkyrimNetApi.RegisterDecorator("sexlab_get_threads", "SkyrimNet_SexLab_Decorators", "Get_Threads")
    SkyrimNetApi.RegisterDecorator("sexlab_get_arousal", "SkyrimNet_SexLab_Decorators", "Get_Arousal")
EndFunction

String Function Get_Arousal(Actor akActor) global
    Debug.Trace("[SkyrimNet_SexLab] Get_Arousal called for "+akActor.GetLeveledActorBase().GetName())

    slaFrameworkScr sla = Game.GetFormFromFile(0x4290F, "SexLabAroused.esm") as slaFrameworkScr
    int arousal
    if sla == None
        Debug.Notification("[SkyrimNet_SexLab] Get_Arousal: slaFrameworkScr is None")
        arousal = -1 
    else
        arousal =  sla.GetActorArousal(akActor)
    endif
    return "{\"arousal\":"+arousal+"}"
EndFunction

String Function Get_Threads(Actor akActor) global
    Debug.Trace("[SkyrimNet_SexLab] Get_Threads called for "+akActor.GetLeveledActorBase().GetName())

    sslThreadSlots ThreadSlots = Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadSlots
    if ThreadSlots == None
        Debug.Notification("[SkyrimNet_SexLab] Get_Threads: ThreadSlots is None")
        return ""
    endif

    sslThreadController[] threads = ThreadSlots.Threads

    Debug.Trace("[SkyrimNet_SexLab] Before loop")
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

    String[] gears = SkyrimNet_SexLab_Actions.GetBondages()
    int j = 0 
    int num = gears.Length
    String gear = "" 
    while j < num
        if anim.HasTag(gears[j])
            gear  = " with a "+gears[j]
            j = num 
        endif 
        j += 1
    endwhile
    thread_str += "\"bondage_gear\": \""+gear+"\", "

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
    String position = ""
    while i < positions.Length && position == ""
        if anim.HasTag(positions[i])
            position = positions[i]
            found = true
        endif
        i += 1
    endwhile
    thread_str += "\"position\":\""+position+"\","
    

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

    String loc = "floor"
    i = 0
    while i < on_furniture.Length && loc == "floor"
        if anim.HasTag(on_furniture[i])
            loc = on_furniture[i]+" "
        endif
        i += 1
    endwhile
    
    if loc == ""
        int bed = thread.BedTypeId
        if bed == 0
            loc = "floor"
        elseif bed == 1
            loc = "bedroll "
        elseif bed == 2
            loc = "single bed "
        elseif bed == 3
            loc = "double bed "
        endif 
    endif 

    if anim.HasTag("Cage")
        loc += " in a cage"
    elseif anim.HasTag("Gallows")
        loc += " in a gallows"
    elseif anim.HasTag("coffin")
        loc += " in a coffin"
    elseif anim.HasTag("floating")
        loc += " floating in air"
    elseif anim.HasTag("tentacles")
        loc += " with tentacles"
    elseif anim.HasTag("gloryhole") || anim.HasTag("gloryholem")
        loc += " through a gloryhole"
    endif
    thread_str += "\"location\":\""+loc+"\","

    String emotion = ""
    if anim.HasTag("rough")
        emotion += " roughly"
    elseif anim.HasTag("loving")
        emotion += " lovingly"
    endif
    thread_str += "\"emotion\":\""+emotion+"\","

    Actor[] actors = thread.Positions
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