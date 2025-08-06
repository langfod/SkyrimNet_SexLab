Scriptname SkyrimNet_SexLab_Stages extends Quest 

import SkyrimNet_SexLab_Main

sslThreadSlots ThreadSlots = None
Actor player = None 

String Property animations_folder = "Data/SkyrimNet_SexLab/animations" Auto
String Property local_folder =      "" Auto

String VERSION_1_0 = "1.0"
String VERSION_2_0 = "2.0"

String desc_input = "" 

Function Trace(String msg, Bool notification=False) global
    msg = "[SkyrimNet_SexLab_Stages] "+msg
    Debug.Trace(msg)
    if notification
        Debug.Notification(msg)
    endif 
EndFunction


Function Setup()
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
; Edit Description Function 
; Returns True if there was a thread to edit
; ------------------------------------

Function EditDescriptions(sslThreadController thread)
    if thread == None 
        return
    endif 
    Actor[] actors = thread.Positions

    int undefined = -1
    int rewrite = 0 
    int cancel = 1

    String fname = GetFilename(thread)
    Trace("EditDescriptions thread: "+fname,true)
    int anim_info = GetAnim_Info(animations_folder, fname)
    String stage_id = "stage "+thread.stage
    int desc_info = JMap.getObj(anim_info, stage_id)
    if desc_info != 0 
        String desc = JMap.getStr(desc_info, "description")
        if desc != ""
            String[] buttons = new String[2]
            buttons[rewrite] = "replace"
            buttons[cancel] = "cancel"
            String source = JMap.getStr(desc_info, "source")
            String version = JMap.getStr(desc_info, "version")
            String full = "["+source+"] "+Description_Add_Actors(version, actors, desc)
            int button = SkyMessage.ShowArray(full, buttons, getIndex = true) as int  
            if button == cancel
                return
            endif 
        endif 
    endif 

    EditorDescription(fname, actors, stage_id)
    return
EndFunction 

; ------------------------------------
; Editor Functions 
; ------------------------------------
Function EditorDescription(String fname, Actor[] actors, String stage_id)
    uiextensions.InitMenu("UITextEntryMenu")
    uiextensions.OpenMenu("UITextEntryMenu")
    desc_input = UIExtensions.GetMenuResultString("UITextEntryMenu")
    String version = VERSION_2_0
    if desc_input != ""
        int undefined = -1
        int accept = 0
        int rewrite = 1 
        int cancel = 2
        String[] buttons = new String[3]
        buttons[accept] = "accept"
        buttons[rewrite] = "replace"
        buttons[cancel] = "cancel"

        String full = "On {the floor/a bed}, "+Description_Add_Actors(version, actors, desc_input)
        int button = SkyMessage.ShowArray(full, buttons, getIndex = true) as int  

        if button == accept 
            SaveAnimInfo(fname, stage_id, version)
        elseif button == rewrite
            EditorDescription(fname, actors, stage_id)
        endif 
    endif 
    desc_input = ""
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

