Scriptname SkyrimNet_SexLab_Stages extends Quest 

sslThreadSlots ThreadSlots = None
Actor player = None 

String Property animations_folder = "Data/SkyrimNet_SexLab/animations" Auto
String Property local_folder =      "" Auto

String VERSION_1_0 = "1.0"

String desc_input = "" 

Function Trace(String msg, Bool notification=False) global
    msg = "[SkyrimNet_SexLab_Stages] "+msg
    Debug.Trace(msg)
    if notification
        Debug.Notification(msg)
    endif 
EndFunction


Function Setup()
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
                String source = JMap.getStr(desc_info, "description")
                return Description_Add_Actors(actors, "["+source+"] "+desc)
            endif 
            stage -= 1
        endwhile 
    endif 
    return ""
EndFunction 

String Function Description_Add_Actors(Actor[] actors, String desc) global
    if desc == ""
        return ""
    endif 
    if actors.length == 1 
        return actors[0].GetDisplayName()+" "+desc
    else 
        return actors[1].GetDisplayName()+" "+desc+" "+actors[0].GetDisplayName() 
    endif 
EndFunction 

Function EditDescriptions()
    local_folder =      "Data/SkyrimNet_SexLab/animations/_local_"
    sslThreadController thread = GetThread() 
    if thread == None 
        return 
    endif 
    Actor[] actors = thread.Positions

    int undefined = -1
    int replace = 0 
    int cancel = 1

    String fname = GetFilename(thread)
    int anim_info = GetAnim_Info(animations_folder, fname)
    JValue.writeToFile(anim_info, animations_folder+"/anim_info.json")
    String stage_id = "stage "+thread.stage
    int desc_info = JMap.getObj(anim_info, stage_id)
    if desc_info != 0 
        String desc = JMap.getStr(desc_info, "description")
        if desc != ""
            String[] buttons = new String[2]
            buttons[replace ] = "Replace"
            buttons[cancel] = "Cancel"
            String full = Description_Add_Actors(actors, desc)
            int button = SkyMessage.ShowArray(full, buttons, getIndex = true) as int  
            if button == cancel - 1
                return 
            endif 
        endif 
    endif 

    EditorDescription(fname, actors, stage_id)

EndFunction 

; ------------------------------------
; Editor Functions 
; ------------------------------------
int Function EditorDescription(String fname, Actor[] actors, String stage_id)
    uiextensions.InitMenu("UITextEntryMenu")
    uiextensions.OpenMenu("UITextEntryMenu")
    desc_input = UIExtensions.GetMenuResultString("UITextEntryMenu")
    if desc_input != ""
        int undefined = -1
        int accept = 0
        int replace = 1 
        int cancel = 2
        String[] buttons = new String[3]
        buttons[accept] = "Accept"
        buttons[replace] = "Replace"
        buttons[cancel] = "Cancel"

        String full = Description_Add_Actors(actors, desc_input)
        int button = SkyMessage.ShowArray(full, buttons, getIndex = true) as int  

        if button == accept 
            SaveAnimInfo(fname, stage_id)
        elseif button == replace
            EditorDescription(fname, actors, stage_id)
        endif 
    endif 
EndFunction

Function SaveAnimInfo(String fname, String stage_id) 
    String path = local_folder+"/"+fname
    int anim_info = JValue.readFromFile(path)
    int stage_info = JMap.object() 
    if anim_info == 0 
        anim_info = JMap.object()
    endif
    JMap.setStr(stage_info,"id",stage_id) 
    JMap.setStr(stage_info,"version",VERSION_1_0)
    JMap.setStr(stage_info,"description",desc_input)
    JMap.setObj(anim_info, stage_id, stage_info)

    Debug.Notification("saving "+fname)
    JValue.writeToFile(anim_info, path)
    JValue.writeToFile(anim_info, animations_folder+"/last.json")
EndFunction 


; ------------------------------------
; Helper functions
; ------------------------------------

sslThreadcontroller Function GetThread() 
    if threadSlots == None 
        return None 
    endif 
    sslThreadController[] threads = ThreadSlots.Threads

    ; Get the active thread that contains the player or actor in the crossHair
    Actor target = Game.GetCurrentCrosshairRef() as Actor 
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
    int i = folders.Length - 1
    while 0 <= i
        String fn = animations_folder+"/"+folders[i]+"/"+fname
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
        i -= 1
    endwhile 
    return anim_info
EndFunction 

String Function GetFilename(sslThreadController thread) global
    sslBaseAnimation anim = thread.animation
    return anim.name+".json"
EndFunction 

