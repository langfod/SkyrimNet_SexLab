Scriptname SkyrimNet_SexLab_Actions 


Function Trace(String msg, Bool notification=False) global
    msg = "[SkyrimNet_SexLab_Actions] "+msg
    Debug.Trace(msg)
    if notification
        Debug.Notification(msg)
    endif 
EndFunction

;----------------------------------------------------------------------------------------------------
; Actions
;----------------------------------------------------------------------------------------------------
Function RegisterActions() global
    Trace("RegisterActions called")
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main

    String[] types = GetTypes()
    int i = 0
    int count = types.Length 
    String type = ""
    while i < count 
        if type != "any" && type != "bondge"
            if type != "" 
                type += "|"
            endif 
            type += types[i]
        endif 
        i += 1
    endwhile 

    ; ------------------------
    SkyrimNetApi.RegisterAction("SexLabSexTarget", \
            "Start having consensual sex with {target}.", \
            "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
            "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", 1, \
            "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":false, \"victim\":true}")
    SkyrimNetApi.RegisterAction("SexLabSexMasturbation", \
            "Start masturbating.",\
            "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
            "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", 1, \
            "{\"type\":\"masturbation\", \"rape\":{true|false}}")

    ; ------------------------
    SkyrimNetApi.RegisterAction("SexLabDress", \
            "Start to dress in clothing.",\
            "SkyrimNet_SexLab_Actions", "Dress_IsEligible",  \
            "SkyrimNet_SexLab_Actions", "Dress_Execute",  \
            "", "PAPYRUS", 1, \
            "")
    SkyrimNetApi.RegisterAction("SexLabUndress", \
            "Start to undress clothing.",\
            "SkyrimNet_SexLab_Actions", "Undress_IsEligible",  \
            "SkyrimNet_SexLab_Actions", "Undress_Execute",  \
            "", "PAPYRUS", 5, \
            "")

    ; ------------------------
    if main.rape_allowed
        SkyrimNetApi.RegisterAction("SexLabRapeTarget", \
                "Start to sexually assualt {target}.",\
                "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
                "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
                "", "PAPYRUS", 1, \
                "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":true, \"victim\":false}")
        SkyrimNetApi.RegisterAction("SexLab_RapedByTarget", \
                "Starts being sexually assulted by {target}.",\
                "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
                "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
                "", "PAPYRUS", 1, \
                "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":true, \"victim\":true}")
    endif 

EndFunction

; -------------------------------------------------
; ACtions 
; -------------------------------------------------

String[] Function GetTypes() global
    String[] types = new String[12]
    types[0] = "bondage"
    types[1] = "oral"
    types[2] = "boobjob"
    types[3] = "thighjob"
    types[4] = "vaginal"
    types[5] = "fisting"
    types[6] = "anal"
    types[7] = "dildo"
    types[9] = "fingering"
    types[10] = "footjob"
    types[11] = "handjob"
    return types
EndFunction



Bool Function SexTarget_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    Trace("SexTaget_IsEligible: attempting "+akActor.GetDisplayName())
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if SexLab == None || main == None 
        return false
    endif 

    if !SexLab.IsValidActor(akActor) || akActor.IsDead() || akActor.IsInCombat() || SexLab.IsActorActive(akActor) || main.IsActorLocked(akActor)
        Trace("SexTarget_IsEligible: akActor: " + akActor.GetDisplayName()+" can't have sex")
        return False
    endif

    Trace("SexTarget_IsEligible: " + akActor.GetDisplayName()+" is eligible for sex")
    return True
EndFunction

Function SexTarget_Execute(Actor akActor, string contextJson, string paramsJson) global
    Trace("SexTarget_Execute: "+paramsJson)
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Trace("SexTarget_Execute: SexLab is None", true)
        return
    endif
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if main == None
        Trace("SexTarget_Execute: main is None", true)
        return
    endif

    bool rape = SkyrimNetApi.GetJsonBool(paramsJson, "rape", false)
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type","")
    Actor akTarget = None
    if type != "masturbation" && type != "masturbate"
        akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", None)
        if akTarget == None 
            if SkyrimNetApi.GetJsonBool(paramsJson, "target_is_player", false)
                akTarget = Game.GetPlayer() 
            endif 
        endif 
    endif 
    if akActor == akTarget
        type = "masturbation"
        akTarget = None
    endif 

    if !main.SetActorLock(akActor) 
        main.ReleaseActorLock(akActor) 
        return 
    endif 
    if akTarget != None && !main.SetActorLock(akTarget)
        main.ReleaseActorLock(akActor)
        main.ReleaseActorLock(akTarget) 
    endif 

    Actor player = Game.GetPlayer()
    Bool victim = SkyrimNetApi.GetJsonBool(paramsJson, "victim", true)
    Debug.Trace("[SkyrimNet_SexLab] SexTarget_Execute type:"+type+" akTarget:"+akTarget)
    Actor subActor = akActor 
    Actor domActor = akTarget
    if akTarget != None && !victim 
        subActor = akTarget
        domActor = akActor
    endif

    int YES = 0
    int YES_RANDOM = 1
    int NO_SILENT = 2
    int NO = 3
    String[] buttons = new String[4]
    buttons[YES] = "Yes "
    buttons[YES_RANDOM] = "Yes (Random)"
    buttons[NO_SILENT] = "No (Silent)"
    buttons[NO] = "No "

    int button = YES
    if subActor == player || (domActor != None && domActor == player)
        button = YesNoDialog(buttons, YES, type, rape, domActor, subActor, player)
        if button == NO || button == NO_SILENT
            Trace("SexTarget_Execute: User declined")
            main.ReleaseActorLock(akActor)
            main.ReleaseActorLock(akTarget)
            if button == NO 
                if !rape
                    String msg = "*"+akTarget.GetDisplayName()+" refuses "+akActor.GetDisplayName()+"'s sex request*"
                    SkyrimNetApi.RegisterEvent("sex refuses", msg, akTarget, akActor)
                elseif domActor == player 
                    String msg = "*"+akTarget.GetDisplayName()+" refuses to rape "+akActor.GetDisplayName()+".*"
                    SkyrimNetApi.RegisterEvent("rape refuses", msg, akTarget, akActor)
                else
                    String msg = "*"+akTarget.GetDisplayName()+" refuses "+akActor.GetDisplayName()+"'s rape attempt.*"
                    SkyrimNetApi.RegisterEvent("rape refuses", msg, akTarget, akActor)
                endif
            endif
            return 
        endif 
    endif

    int num_actors = 1
    if domActor != None
        num_actors = 2
    endif 

    bool failure = False
    if button != YES_RANDOM
        if type == "kissing"
            String tagSupress = "oral,vaginal,anal,spanking,masturbate,handjob,footjob,masturbation,breastfeeding,fingering"
            sslBaseAnimation[] anims =  SexLab.GetAnimationsByTags(num_actors, type, tagSupress, true)
            if anims.length > 0
                thread.SetAnimations(anims)
                thread.addTag(type)
            else
                Debug.Notification("No kissing animation found")
                return 
            endif 
        else
            bool includes_player = akActor == player || (akTarget != None && akTarget == player )
            if (includes_player && main.sex_edit_tags_player) || (!includes_player && main.sex_edit_tags_nonplayer)
                Actor[] actors = PapyrusUtil.ActorArray(num_actors)
                if num_actors == 1
                    actors[0] = subActor
                else
                    actors[0] = subActor
                    actors[1] = domActor
                endif
                sslBaseAnimation[] anims = AnimsDialog(sexlab, actors, type)
                if anims[0] == None 
                    failure = true
                else
                    thread.SetAnimations(anims)
                endif 
            endif 
        endif 
    endif 

    
    sslThreadModel thread = None 
    if !failure 
        thread = sexlab.NewThread()
        if thread == None
            Trace("SexTarget_Execute: Failed to create thread")
            failure = true 
        endif
        if !failure && thread.addActor(subActor) < 0   
            Trace("SexTarget_Execute: Starting sex couldn't add " + subActor.GetDisplayName())
            failure = true 
        endif  
        if !failure && domActor != None 
            if thread.addActor(domActor) < 0   
                Trace("SexTarget_Execute: Starting sex couldn't add " + domActor.GetDisplayName())
                failure = true 
            endif  
        endif 
    endif 
    
    if failure
        main.ReleaseActorLock(akActor)
        main.ReleaseActorLock(akTarget)
        return
    endif

    ; Debug.Notification(subActor.GetDisplayName()+" will have sex with "+akTarget.GetDisplayName())
    if rape
        thread.SetVictim(subActor)
    endif 
    Trace("SexTarget_Executer: Starting type:"+type+" aggressive:"+thread.IsAggressive)

    thread.StartThread() 
EndFunction

int function YesNoDialog(String[] buttons, int YES, String type, Bool rape, Actor domActor, Actor subActor, Actor player) global
    String name = None 
    if subActor == player
        name = domActor.GetDisplayName()
    else
        name = subActor.GetDisplayName()
    endif
    String question = None
    if rape
        if domActor == player
            question = "Would like to rape "+name+"?"
        else
            question = "Would like to be raped by "+name+"?"
        endif 
    elseif type == "kissing"
        question = "Would like to kissing "+name+"?"
    else
        question = "Would like to have sex "+name+"?"
    endif 
    
    return SkyMessage.ShowArray(question, buttons, getIndex = true) as int  
EndFunction

; -------------------------------------------------
; Dress and Undress
; -------------------------------------------------

Bool Function Undress_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    Trace("Undress_IsEligible: attempting "+akActor.GetDisplayName())
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if SexLab == None || main == None 
        return false
    endif 

    if !SexLab.IsValidActor(akActor)
        Trace("Undress_IsEligible: akActor: " + akActor.GetDisplayName()+" can't undress")
        return False
    endif

    Trace("Undress_IsEligible: " + akActor.GetDisplayName()+" can undress")
    return True
EndFunction

Function Undress_Execute(Actor akActor, string contextJson, string paramsJson) global
    Trace("Undress_Execute: attempting "+akActor.GetDisplayName())
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if SexLab == None || main == None 
       return 
    endif 

    Trace("Undress_Execute: " + akActor.GetDisplayName()+" ")
    Form[] forms = sexlab.StripActor(akActor, akActor, false, false) 
    main.StoreStrippedItems(akActor, forms)
EndFunction

Bool Function Dress_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if SexLab == None || main == None 
        return false
    endif 

    if !SexLab.IsValidActor(akActor)
        Trace("Dress_IsEligible: akActor: " + akActor.GetDisplayName()+" can't dress")
        return False
    endif

    if !main.HasStrippedItems(akActor)
        Trace("Dress_IsEligible: akActor: " + akActor.GetDisplayName()+" has no stripped items")
        return False
    endif
    Trace("Dress_IsEligible: " + akActor.GetDisplayName()+" can dress")
    return True
EndFunction

Function Dress_Execute(Actor akActor, string contextJson, string paramsJson) global
    Trace("Dress_Execute: attempting "+akActor.GetDisplayName())
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if SexLab == None || main == None 
        return
    endif 

    Trace("Dress_Execute: Unstoring stripped items")
    Form[] forms = main.UnStoreStrippedItems(akActor)
    if forms.length > 0
        Trace("Dress_Execute: "+akActor.GetDisplayName()+" unstripping "+forms)
        sexlab.UnStripActor(akActor, forms, false) 
    else 
        Trace("Dress_Execute: "+akActor.GetDisplayName()+" has no stripped items")
    endif 
EndFunction

; -------------------------------------------------
; Tools
; -------------------------------------------------

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
        Trace("TagsDialog group_tags not found in group_tags.json")
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
                sslBaseAnimation[] anims = new sslBaseAnimation[1]
                anims[0] = None 
                return anims
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
            Debug.Notification("No animations found for: "+tags_str)
        endif 
    endwhile 
    return None
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

