Scriptname SkyrimNet_SexLab_Stages extends Quest 

import SkyrimNet_SexLab_Main

Bool Property hide_help = false Auto

sslThreadSlots ThreadSlots = None
Actor player = None 

String Property animations_folder = "Data/SkyrimNet_SexLab/animations" Auto
String Property local_folder =      "" Auto

String VERSION_1_0 = "1.0"
String VERSION_2_0 = "2.0"

String desc_input = "" 

String tracking_db = ""

int tracking_thread_id = 0

Function Trace(String msg, Bool notification=False) global
    msg = "[SkyrimNet_SexLab_Stages] "+msg
    Debug.Trace(msg)
    if notification
        Debug.Notification(msg)
    endif 
EndFunction

Function Setup()
    String temp = "sl" ; attempt to set the caplitiization of sl 

    desc_input = ""
    animations_folder = "Data/SkyrimNet_SexLab/animations"
    local_folder =      animations_folder+"/_local_"
    if ThreadSlots == None 
        ThreadSlots = Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadSlots
        player = Game.GetPlayer()
    endif 
    if ThreadSlots == None
        Debug.Notification("[SkyrimNet_SexLab] Thread_Dialog: ThreadSlots is None")
        return  
    endif

    if tracking_thread_id <= 0 
        tracking_thread_id = JIntMap.object() 
        JValue.retain(tracking_thread_id)
    endif 
EndFunction

String Function GetStageDescription(sslThreadController thread) global
    SkyrimNet_SexLab_Stages stages = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Stages
    if thread == None 
        Trace("GetStageDescription: thread is None", true)
        return ""
    endif 
    String fname = GetFilename(thread)
    int stage = thread.stage
    int anim_info = GetAnim_Info(stages.animations_folder, fname)
    if anim_info != 0
        while 0 <= stage 
            String stage_id = "stage "+stage
            int desc_info = JMap.getObj(anim_info, stage_id)
            if desc_info != 0 
                Actor[] actors = thread.Positions
                String desc = JMap.getStr(desc_info, "description")
                String version = JMap.getStr(desc_info, "version")
                return stages.Description_Add_Actors(version, actors, desc)
            endif 
            stage -= 1
        endwhile 
    endif 
    return ""
EndFunction 

String Function Description_Add_Actors(String version, Actor[] actors, String desc)
    Trace("Description_Add_Actors: version "+version+" actors:"+actors.length+" desc:"+desc+" ")
    if desc == ""
        return ""
    endif 
    if version == VERSION_1_0
        if actors.length == 1 
            desc = actors[0].GetDisplayName()+" "+desc+"."
            String last_char = StringUtil.GetNthChar(desc,StringUtil.GetLength(desc) - 1)
            if !StringUtil.IsPunctuation(last_char)
                desc += "."
            endif
        else
            desc = actors[1].GetDisplayName()+" "+desc+" "+actors[0].GetDisplayName()+"."
        endif 
       return desc
    elseif version == VERSION_2_0
        String actors_json = SkyrimNet_SexLab_Main.ActorsToJson(actors)
        String result = SkyrimNetApi.ParseString(desc, "sl", "{\"actors\":"+actors_json+"}")
        return result 
    else 
        Trace("Description_Add_Actors: Unknown version "+version, true)
        return "" 
    endif 
EndFunction 
; ------------------------------------
; Tracking Function 
; ------------------------------------
Function StartThreadTracking(int thread_id)
    JIntMap.setInt(tracking_thread_id, thread_id, 1)
EndFunction

Function StopThreadTracking(int thread_id)
    JIntMap.removeKey(tracking_thread_id, thread_id)
EndFunction 

function ToggleThreadTracking(int thread_id)
    if IsThreadTracking(thread_id)
        StopThreadTracking(thread_id)
    else
        StartThreadTracking(thread_id)
    endif
EndFunction

bool Function IsThreadTracking(int thread_id)
    return JIntmap.hasKey(tracking_thread_id, thread_id)
EndFunction

; ------------------------------------
; Edit Description Function 
; Returns True if there was a thread to edit
; ------------------------------------

Function EditDescriptions(sslThreadController thread)
    if thread == None 
        return
    endif 
    Actor[] actors = thread.Positions

    sslBaseAnimation anim = thread.animation
    Debug.Notification("stage "+thread.stage+" of "+anim.StageCount())


    String fname = GetFilename(thread)
    Trace("EditDescriptions thread: "+fname,true)
    int anim_info = GetAnim_Info(animations_folder, fname)
    String stage_id = "stage "+thread.stage
    int desc_info = JMap.getObj(anim_info, stage_id)
    if desc_info == 0 
        if !hide_help && !IsThreadTracking(thread.tid)
            String help_message = "You will enter a description of the current stage. An example:\n" 
            help_message += BuildExample(actors)

            int ok = 0 
            int stop_showing = 1
            int cancel = 2
            String[] buttons = new String[3]
            buttons[ok] = "ok"
            buttons[stop_showing] = "never show again"  
            buttons[cancel] = "cancel"
            int button = SkyMessage.ShowArray(help_message, buttons, getIndex = true) as int  
            if button == cancel
                return
            elseif button == stop_showing 
                hide_help = true 
            endif 
        endif 
    else
        String desc = JMap.getStr(desc_info, "description")
        if desc != ""
            String[] buttons = new String[3]
            int rewrite = 0 
            int tracking = 1
            int cancel = 2
            buttons[rewrite] = "replace"

            if IsThreadTracking(thread.tid)
                buttons[tracking] = "Stop Tracking"
            else
                buttons[tracking] = "Start Tracking"
            endif 
            buttons[cancel] = "cancel"
            String source = JMap.getStr(desc_info, "source")
            String version = JMap.getStr(desc_info, "version")
            String full = "["+source+"] "+Description_Add_Actors(version, actors, desc)
            int button = SkyMessage.ShowArray(full, buttons, getIndex = true) as int  
            if button == cancel
                return
            elseif button == tracking 
                ToggleThreadTracking(thread.tid)
                return 
            endif 
        endif 
    endif 

    EditorDescription(thread.tid, fname, actors, stage_id)
    return
EndFunction 

; ------------------------------------
; Editor Functions 
; ------------------------------------
Function EditorDescription(int thread_id, String fname, Actor[] actors, String stage_id)
    uiextensions.InitMenu("UITextEntryMenu")
    uiextensions.OpenMenu("UITextEntryMenu")
    desc_input = UIExtensions.GetMenuResultString("UITextEntryMenu")
    String version = VERSION_2_0
    if desc_input != ""
        String desc = Description_Add_Actors(version, actors, desc_input)
        if desc != ""
            int undefined = -1
            int accept = 0
            int rewrite = 1 
            int tracking = 2
            int cancel = 3
            String[] buttons = new String[4]
            buttons[accept] = "accept"
            buttons[rewrite] = "replace"
            if IsThreadTracking(thread_id)
                buttons[tracking] = "Stop Tracking"
            else
                buttons[tracking] = "Start Tracking"
            endif 
            buttons[cancel] = "cancel"
            String full = "On {the floor/a bed}, "+desc 

            int button = SkyMessage.ShowArray(full, buttons, getIndex = true) as int  

            if button == accept 
                StartThreadTracking(thread_id)
                SaveAnimInfo(fname, stage_id, version)
            elseif button == rewrite
                EditorDescription(thread_id, fname, actors, stage_id)
            elseif button == Tracking
                ToggleThreadTracking(thread_id)
            endif 
        else
            String msg = "Your description wasn't parsed correctly.\n"
            int i = 0 
            int count = actors.length
            while i < count
                msg += "{{sl.actors."+i+"}}: "+actors[i].GetDisplayName()+"\n"
                i += 1
            endwhile 
            msg += BuildExample(actors)

            String[] buffers = new String[2]
            int ok = 0 
            int tracking = 1
            int cancel = 2
            String[] buttons = new String[3]    
            buttons[ok] = "ok"
            if IsThreadTracking(thread_id)
                buttons[tracking] = "Stop Tracking"
            else
                buttons[tracking] = "Start Tracking"
            endif 
            buttons[cancel] = "cancel"
            int button = SkyMessage.ShowArray(msg, buttons, getIndex = true) as int  

            if button == ok
                EditorDescription(thread_id, fname, actors, stage_id)
            elseif button == tracking
                StopThreadTracking(thread_id)
            endif 
        endif 
    endif 
    desc_input = ""
EndFunction

String Function BuildExample(Actor[] actors)
    String example = "{{sl.actors.1}} are having sex {{sl.actors.0}}."
    if actors.length == 1
        example = "{{sl.actors.0}} is masturbating."
    elseif actors.length > 3
        example = "{{sl.actors.2}}, {{sl.actors.1}}, and {{sl.actors.0}} are having an orgy."
    endif 
    String desc = Description_Add_Actors(VERSION_2_0, actors, example)
    return "\""+example+"\"\n"+ "\""+desc+"\""
EndFunction

Function SaveAnimInfo(String fname, String stage_id, String version)
    String path = local_folder+"/"+fname
    int anim_info = 0
    if MiscUtil.FileExists(path)
        anim_info = JValue.readFromFile(path)
    else 
        anim_info = JMap.object()
    endif 
    int stage_info = JMap.object() 
    JMap.setStr(stage_info,"id",stage_id) 
    JMap.setStr(stage_info,"version",version)
    JMap.setStr(stage_info,"description",desc_input)
    JMap.setObj(anim_info, stage_id, stage_info)

    Debug.Notification("saving "+fname)
    JValue.writeToFile(anim_info, path)
    JValue.writeToFile(anim_info, animations_folder+"/last.json")
EndFunction 


; ------------------------------------
; Helper functions
; ------------------------------------

sslThreadcontroller Function GetThread(Actor target)
    if threadSlots == None 
        return None 
    endif 
    sslThreadController[] threads = ThreadSlots.Threads

    ; Get the active thread that contains the player or actor in the crossHair
    sslThreadController thread = None
    bool has_player = false 
    int i = threads.length - 1
    while 0 <= i 
        if (threads[i] as sslThreadModel).GetState() == "animating"
            Actor[] actors = threads[i].Positions
            int j = actors.Length - 1
            while 0 <= j 
                if !has_player && actors[j] == target
                    thread = threads[i]
                elseif actors[j] == player 
                    thread = threads[i]
                    has_player = true 
                endif
                j -= 1 
            endwhile 
        endif 
        i -= 1
    endwhile
    return thread
EndFunction 

int Function GetAnim_Info(String animations_folder, String fname) global
    ; This will hold a map between the Stage nad the descriptions 
    int anim_info = JMap.object() 

    String[] folders = MiscUtil.FoldersInfolder(animations_folder)

    ; Make sure the local folder is processed last
    int i = folders.length - 1
    while 0 <= i && folders[i] != "_local_"
        i -= 1
    endwhile 
    if 0 < i 
        folders[i] = folders[0]
        folders[0] = "_local_"
    endif

    i = folders.Length - 1
    while 0 <= i
        String fn = animations_folder+"/"+folders[i]+"/"+fname
        if MiscUtil.FileExists(fn)
            int info = JValue.readFromFile(fn)
            if info != 0
                String[] keys = JMap.allKeysPArray(info)
                int k = keys.length - 1
                while 0 <= k
                    int desc_info = JMap.getObj(info, keys[k])
                    JMap.setStr(desc_info, "source", folders[i])
                    String stage_id = JMap.getStr(desc_info, "id")
                    String desc = JMap.getStr(desc_info, "description")
                    JMap.setObj(anim_info, stage_id, desc_info)
                    k -= 1
                endwhile 
            endif 
        endif
        i -= 1
    endwhile 
    return anim_info
EndFunction 

String Function GetFilename(sslThreadController thread) global
    sslBaseAnimation anim = thread.animation
    return anim.name+".json"
EndFunction 

