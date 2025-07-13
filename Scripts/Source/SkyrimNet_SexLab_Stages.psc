Scriptname SkyrimNet_SexLab_Stages extends Quest 

sslThreadSlots ThreadSlots

String animations_fold = "Data/SkyrimNet_SexLab/animations"

int _description_edit_key = 27
int Property description_edit_key 
    int Function get()
        return _description_edit_key
    EndFunction
    Function set(int key_code)
        UnregisterForKey(_description_edit_key)
        _description_edit_key = key_code
        RegisterForKey(_description_edit_key)
    EndFunction
EndProperty

Function Setup()
    ThreadSlots = Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadSlots
    if ThreadSlots == None
        Debug.Notification("[SkyrimNet_SexLab] Thread_Dialog: ThreadSlots is None")
        return  
    endif
   
    if _description_edit_key == 0
        _description_edit_key = 27
    endif 
    RegisterForKey(_description_edit_key)
EndFunction

Event OnKeyDown(int key_code) 
    if key_code == _description_edit_key; && !UI.IsTextInputEnabled()
        sslThreadController[] threads = ThreadSlots.Threads

        ; Get the active thread that contains the player or actor in the crossHair
        Actor target = Game.GetCurrentCrosshairRef() as Actor 
        Actor player = Game.GetPlayer()
        sslThreadController thread = None
        bool has_player = false 
        int i = threads.length - 1
        while 0 <= i 
            if (threads[i] as sslThreadModel).GetState() == "animating"
                Actor[] actors = threads[i].Positions
                int j = actors.Length
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
        if thread == None 
            return 
        endif 
        sslBaseAnimation anim = thread.animation
        String fname = GetFilename(anim)

        ; This will hold a map between the Stage nad the descriptions 
        int stage_descs = JMap.object() 

        String[] folders = MiscUtil.FoldersInfolder(animations_fold)
        i = folders.Length - 1
        while 0 <= i
            String fn = animations_fold+"/"+folders[i]+"/"+fname
            int anim_descs = JValue.readFromFile(fn)
            if anim_descs != 0
                int descs = JMap.getObj(anim_descs,"descriptions")
                int j = 0 
                int count = JArray.count(descs) - 1 
                while j < count 
                    int desc = JArray.GetObj(descs, j)
                    if desc != 0
                        JMap.setStr(desc, "id",fname) 
                        JMap.setStr(desc,"sources",folders[i])
                        String stage = JMap.getInt(desc,"stage") as String
                        int ds = JMap.getObj(stage_descs, stage)
                        if ds == 0 
                            ds = JArray.object() 
                            JMap.setObj(stage_descs, stage, ds)
                        endif 
                        JArray.addObj(ds, desc)
                    endif 
                endwhile 
            endif 
            i -= 1
        endwhile 
        JValue.writeToFile(stage_descs, animations_fold+"/"+fname)

;        Debug.MessageBox(folders)
    endif 
EndEvent 

String Function GetFilename(sslBaseAnimation anim) 

    String id_str = ""
    String[] tags = anim.GetRawTags()
    int j  = 0
    int count = tags.length
    while j < count 
        if j != 0
            id_str += "_"
        endif 
        id_str += tags[j]
        j += 1
    endwhile 
    return anim.Name+"_"+id_str+".json"
EndFunction 
