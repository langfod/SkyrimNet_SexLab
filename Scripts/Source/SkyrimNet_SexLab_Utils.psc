Scriptname SkyrimNet_SexLab_Utils

Function Trace(String func, String msg, Bool notification=false) global
    msg += "[SkyrimNet_SexLab_Utils."+func+"] "+msg 
    if notification 
        Debug.Notification(msg) 
    endif 
    Debug.Trace(msg)
EndFunction

; Allows the user to choose to accept the sex act choosen by the LLM 
; The value will between 
; 1 Yes with the editor 
; 2 Yes, but no tag editor 
; 3 No (silent), refused, but don't tell the LLM 
; 4 NO, tell the LLM 
int function YesNoSexDialog(String type, Bool rape, Actor domActor, Actor subActor, Actor player) global

    int YES = 0
    int YES_RANDOM = 1
    int NO_SILENT = 2
    int NO = 3
    String[] buttons = new String[4]
    buttons[YES] = "Yes "
    buttons[YES_RANDOM] = "Yes (Random)"
    buttons[NO_SILENT] = "No (Silent)"
    buttons[NO] = "No "

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
    if button == NO || button == NO_SILENT
        if button == NO 
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


sslBaseAnimation[] Function AnimsDialog(SexLabFramework sexlab, Actor[] actors, String tag) global
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main

    int i = 0
    int count = actors.Length
    String names = ""
    while i < count
        if names != ""
            names += "+" 
        endif
        names += actors[i].GetDisplayName()
        i += 1 
    endwhile
    names += " | "


    ; Current set of tags
    String[] tags = new String[10]
    int count_max = 10
    int next = 0
    if tag != ""
        tags[next] = tag
        next += 1
    endif 

    ; the order of the groups 
    int group_tags = JMap.getObj(main.group_tags,"group_tags",0)
    if group_tags == 0 
        Trace("AnimsDialog", "group_tags not found in group_tags.json")
        return None
    endif 

    int groups = JMap.getObj(main.group_tags,"groups",0)
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
                sslBaseAnimation[] empty = new sslBaseAnimation[1]
                empty[0] = None 
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
            Trace("SkyrimNet_SexLab_Utils","No animations found for: "+tags_str, true)
        endif 
    endwhile 
    sslBaseAnimation[] empty = new sslBaseAnimation[1]
    empty[0] = None 
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
