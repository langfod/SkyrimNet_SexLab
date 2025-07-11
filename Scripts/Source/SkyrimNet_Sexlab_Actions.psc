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
;    SkyrimNetApi.RegisterTag("animation", "Skyrimet_SexLab_Actions", "Animation_IsEligible")

            ; "{{ {{ decnpc(npc.UUID).name }} is/will have {type} consensual sex/love with {target}.", \
    SkyrimNetApi.RegisterAction("SexTarget", \
            "have consensual sex", \
            "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
            "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", 1, \
            "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":false, \"victum\":true}")
    SkyrimNetApi.RegisterAction("SexMasturbation", \
            "masturbate",\
            "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
            "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", 1, \
            "{\"type\":\"masturbation\", \"rape\":{true|false}}")
    if main.rape_allowed
        SkyrimNetApi.RegisterAction("RapeTarget", \
                "be the assailant of nonconsensual sex",\
                "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
                "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
                "", "PAPYRUS", 1, \
                "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":true, \"victum\":false}")
        SkyrimNetApi.RegisterAction("RapedByTarget", \
                "be the victum of nonconsensual sex",\
                "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
                "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
                "", "PAPYRUS", 1, \
                "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":true, \"victum\":true}")
    endif 

EndFunction

; -------------------------------------------------
; Tags 
; -------------------------------------------------
Bool Function Animation_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None || main == None 
        return false
    endif 

    if SexLab.IsActorActive(akActor) || main.IsActorLocked(akActor)
        Trace("Animation_IsEligible: akActor: " + akActor.GetLeveledActorBase().GetName()+" is already captured by an animation")
        return False
    endif

    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if akTarget != None && (SexLab.IsActorActive(akTarget) || main.IsActorLocked(akTarget))
        Trace("Animation_IsEligible: akTarget: " + akTarget.GetLeveledActorBase().GetName()+" is already captured by an animation")
        return False
    endif

    String nameTarget = "" 
    if akTarget != None 
        nameTarget = akTarget.GetLeveledActorBase().GetName() 
    endif 
    Trace("Animation_IsEligible: " + akActor.GetLeveledActorBase().GetName()+" and "+nameTarget+" can have sex")
    return true 
EndFunction 

; -------------------------------------------------
; ACtions 
; -------------------------------------------------

String[] Function GetTypes() global
    String[] types = new String[14]
    types[0] = "bondage"
    types[1] = "oral"
    types[2] = "boobjob"
    types[3] = "thighjob"
    types[4] = "vaginal"
    types[5] = "fisting"
    types[6] = "anal"
    types[7] = "dildo"
    types[8] = "spanking"
    types[9] = "fingering"
    types[10] = "footjob"
    types[11] = "handjob"
    types[12] = "kissing"
    types[13] = "headpat"
    return types
EndFunction

String[] Function GetBondages() global
    string[] bondages = new String[9]
    bondages[0] = "armbinder"
    bondages[1] = "cuffs"
    bondages[2] = "cuffed"
    bondages[3] = "yoke"
    bondages[6] = "hogtied"
    bondages[7] = "chastity"
    bondages[8] = "chasitybelt"
    return bondages
EndFunction

Bool Function SexTarget_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    Trace("SexTaget_IsEligible: attempting "+akActor.GetLeveledActorBase().GetName())
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if SexLab == None || main == None 
        return false
    endif 

    if !SexLab.IsValidActor(akActor) || akActor.IsDead() || akActor.IsInCombat() || SexLab.IsActorActive(akActor) || main.IsActorLocked(akActor)
        Trace("SexTarget_IsEligible: akActor: " + akActor.GetLeveledActorBase().GetName()+" can't have sex")
        return False
    endif

    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if akTarget == None
        Trace("SetTarget_IsEigible: akTarget is None "+paramsJson)
    else    
        if !SexLab.IsValidActor(akTarget) || akTarget.IsDead() || akTarget.IsInCombat() || SexLab.IsActorActive(akTarget) || main.IsActorLocked(akTarget)
            Trace("SexTarget_IsEligible: akTarget: " + akTarget.GetLeveledActorBase().GetName()+" can't have sex")
            return False
        endif
    endif

    Trace("SexTarget_IsEligible: " + akActor.GetLeveledActorBase().GetName() + " is eligible for sex with " + akTarget.GetLeveledActorBase().GetName())
    return True
EndFunction


Function SexTarget_Execute(Actor akActor, string contextJson, string paramsJson) global
    Debug.MessageBox(paramsJson)
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
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type","vaginal")
    Actor akTarget = None
    if type != "masturbation" && type != "masturbate"
        akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", None)
    endif 
    if akActor == akTarget
        type = "masturbation"
        akTarget = None
    endif 

    if main.IsActorLocked(akActor) || main.IsActorLocked(akTarget)
        return 
    endif 

    main.SetActorLock(akActor)
    main.SetActorLock(akTarget)

    Actor player = Game.GetPlayer()
    Debug.Trace("[SkyrimNet_SexLab] SexTarget_Execute type:"+type+" akTarget:"+akTarget)
    if akActor == player || (akTarget != None && akTarget == player)
        type = YesNoDialog(type, rape, akTarget, akActor, player)
    endif

    if type == "No"
        Trace("SexTarget_Execute: User declined")
        main.ReleaseActorLock(akActor)
        main.ReleaseActorLock(akTarget)
        return 
    endif 
    
    Actor subActor = akActor 
    Actor domActor = akTarget
    Bool victum = SkyrimNetApi.GetJsonBool(paramsJson, "victum", true)
    if !victum 
        subActor = akTarget
        domActor = akActor
    endif

    sslThreadModel thread = sexlab.NewThread()
    bool failure = false 
    if thread == None
        Trace("SexTarget_Execute: Failed to create thread")
        failure = true 
    endif
    if !failure && thread.addActor(subActor) < 0   
        Trace("SexTarget_Execute: Starting sex couldn't add " + subActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        failure = true 
    endif  
    int num_actors = 1
    if !failure && akTarget != None 
        num_actors = 2
        if thread.addActor(domActor) < 0   
            Trace("SexTarget_Execute: Starting sex couldn't add " + domActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
            failure = true 
        endif  
    endif 
    
    if type != "any"
        String tagSupress = ""
        if type == "kissing"
            tagSupress = "oral,vaginal,anal,spanking,mastrubate,handjob,footjob,masturbation,breastfeeding,fingering"
        endif 
        sslBaseAnimation[] anims =  SexLab.GetAnimationsByTags(num_actors, type, tagSupress, true)
        int k = anims.Length
        while k >= 0 
            Debug.MessageBox(anims[k].GetTags())
            k -= 1
        endwhile

        if anims.length > 0
            thread.SetAnimations(anims)
            thread.addTag(type)
        elseif type == "kissing"
            Debug.Notification("No kissing animation found")
            return 
        endif 
    endif 
    
    ; Debug.Notification(akActor.GetLeveledActorBase().GetName()+" will have sex with "+akTarget.GetLeveledActorBase().GetName())
    if rape
        thread.IsAggressive = true
    else
        thread.IsAggressive = false
    endif 
    Trace("SexTarget_Executer: Starting type:"+type+" aggressive:"+thread.IsAggressive)

    if failure
        main.ReleaseActorLock(akActor)
        main.ReleaseActorLock(akTarget)
        return
    endif

    thread.StartThread() 
EndFunction

String function YesNoDialog(String type, Bool rape, Actor domActor, Actor subActor, Actor player) global
    String name = None 
    if subActor == player
        name = domActor.GetLeveledActorBase().GetName()
    else
        name = subActor.GetLeveledActorBase().GetName()
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
    
    String result = SkyMessage.Show(question, "Yes","No")
    if result == "Yes"
        if type == "kissing"
            return type
        endif 

        String[] types = GetTypes() 
        uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") AS uilistmenu
        int i =  0
        int count = types.Length
        while i < count
            listMenu.AddEntryItem(types[i])
            i += 1
        endwhile
        listMenu.OpenMenu()
        type =  listmenu.GetResultString()
        if type == "bondage"
            String[] bondages = GetBondages()
            listMenu = uiextensions.GetMenu("UIListMenu") AS uilistmenu
            i =  0
            count = bondages.Length
            while i < count
                listMenu.AddEntryItem(bondages[i])
                i += 1
            endwhile
            listMenu.OpenMenu()
            type =  listmenu.GetResultString()
        endif 
        return type
    endif 
    return "No"
EndFunction
