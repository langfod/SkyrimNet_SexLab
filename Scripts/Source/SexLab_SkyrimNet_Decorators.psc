Scriptname SexLab_SkyrimNet_Decorators

;----------------------------------------------------------------------------------------------------
; Decorators 
;----------------------------------------------------------------------------------------------------
Function RegisterDecorators() global
    Debug.Trace("SexLab_SkyrimNet_Decorators: RegisterDecorattors called")
    SkyrimNetApi.RegisterDecorator("sexlab_get_threads", "SexLab_SkyrimNet_Decorators", "Get_Threads")
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