Scriptname SexLab_SkyrimNet_Actions

;----------------------------------------------------------------------------------------------------
; Actions
;----------------------------------------------------------------------------------------------------
Function RegisterActions() global
    Debug.Trace("SexLab_SkyrimNet_Main: RegisterActions called")
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
    SkyrimNetApi.RegisterAction("SexTarget", \
            "{{ {{ decnpc(npc.UUID).name }} is/will have {type} consensual sex/love with {target}.", \
            "SexLab_SkyrimNet_Actions", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", 1, \
            "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":false, \"victum\":true}")
    SkyrimNetApi.RegisterAction("RapedByTarget", \
            " {target} starts to {type} rape {{ decnpc(npc.UUID).name }}. {{ decnpc(npc.UUID).name }} must select if implied by narration.", \
            "SexLab_SkyrimNet_Actions", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", 1, \
            "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":true, \"victum\":true}")
    SkyrimNetApi.RegisterAction("RapeTarget", \
            " {{ decnpc(npc.UUID).name }} is/will {type} rape {target}.", \
            "SexLab_SkyrimNet_Actions", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", 1, \
            "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":true, \"victum\":false}")
    SkyrimNetApi.RegisterAction("SexMasturbation", \
            " {{ decnpc(npc.UUID).name }} is/will masturbate.", \
            "SexLab_SkyrimNet_Actions", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", 1, \
            "{\"type\":\"masturbation\", \"rape\":{true|false}}")
EndFunction

String[] Function GetTypes() global
    String[] types = new String[15]
    types[0] = "any"
    types[1] = "bondage"
    types[2] = "oral"
    types[3] = "boobjob"
    types[4] = "thighjob"
    types[5] = "vaginal"
    types[6] = "fisting"
    types[7] = "anal"
    types[8] = "spanking"
    types[9] = "fingering"
    types[10] = "footjob"
    types[11] = "handjob"
    types[12] = "kissing"
    types[13] = "headpat"
    types[14] = "dildo"
    return types
EndFunction

String[] Function GetBondages() global
    string[] bondages = new String[9]
    bondages[0] = "armbinder"
    bondages[1] = "cuffs"
    bondages[2] = "cuffed"
    bondages[3] = "yoke"
    bondages[4] = "pillory"
    bondages[5] = "gallows"
    bondages[6] = "hogtied"
    bondages[7] = "chastity"
    bondages[8] = "chasitybelt"
    return bondages
EndFunction

Bool Function SexTarget_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    Debug.Trace("[SexTarget_IsEligible] attempting "+akActor.GetLeveledActorBase().GetName())
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] SetTarge_IsEigible: SexLab is None")
        return false  
    endif
    if !SexLab.IsValidActor(akActor) || akActor.IsDead() || akActor.IsInCombat() || SexLab.IsActorActive(akActor)
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_IsEligible: akActor: " + akActor.GetLeveledActorBase().GetName()+" can't have sex")
        return False
    endif

    Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if akTarget == None
        Debug.Trace("[SexLab_SkyrimNet] SetTarge_IsEigible: akTarget is None "+paramsJson)
    else    
        if !SexLab.IsValidActor(akTarget) || akTarget.IsDead() || akTarget.IsInCombat() || SexLab.IsActorActive(akTarget)
            Debug.Trace("[SexLab_SkyrimNet] SexTarget_IsEligible: akTarget: " + akTarget.GetLeveledActorBase().GetName()+" can't have sex")
            return False
        endif
    endif

    Debug.Trace("[SexTarget_IsEligible] " + akActor.GetLeveledActorBase().GetName() + " is eligible for sex with " + akTarget.GetLeveledActorBase().GetName())
    return True
EndFunction


Function SexTarget_Execute(Actor akActor, string contextJson, string paramsJson) global
    Debug.Notification("[SexLab_SkyrimNet] SexTarget_Execute called with params: "+paramsJson)
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] SexTarget_Execute: SexLab is None")
        return
    endif
    
    bool rape = SkyrimNetApi.GetJsonBool(paramsJson, "rape", false)
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type","vaginal")
    Debug.Trace("SexTarget_Execte:"+type)
    Actor akTarget = None
    if type != "masturbation" && type != "masturbate"
        akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", None)
    endif 
    if akActor == akTarget
        type = "masturbation"
        akTarget = None
    endif 

    Actor player = Game.GetPlayer()
    if akActor == player || akTarget == player
        type = YesNoDialog(rape, akTarget, akActor, player)
        if type == "No"
            Debug.Trace("[SexLab_SkyrimNet] SexTarget_Execute: User declined")
            return 
        endif 
    endif
    
    Actor subActor = akActor 
    Actor domActor = akTarget
    Bool victum = SkyrimNetApi.GetJsonBool(paramsJson, "victum", true)
    if !victum 
        subActor = akTarget
        domActor = akActor
    endif

    sslThreadModel thread = sexlab.NewThread()
    if thread == None
        Debug.Notification("[SexTarget_Execute] Failed to create thread")
        Debug.Trace("[SexTarget_Execute] Failed to create thread")
        return  
    endif
    if thread.addActor(subActor) < 0   
        Debug.Trace("[SexTarget_Execute] Starting sex couldn't add " + subActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    int num_actors = 1
    if akTarget != None 
        num_actors = 2
        if thread.addActor(domActor) < 0   
            Debug.Trace("[SexTarget_Execute] Starting sex couldn't add " + domActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
            return
        endif  
    endif 

    if type != "any"
        sslBaseAnimation[] anims =  SexLab.GetAnimationsByTags(num_actors, type, "", true)
        if anims.length > 0
            thread.SetAnimations(anims)
        endif 
    endif 
    
    ; Debug.Notification(akActor.GetLeveledActorBase().GetName()+" will have sex with "+akTarget.GetLeveledActorBase().GetName())
    Debug.Trace("[SexLab_SkyrimNet] SexTarget_Executer: Starting")
    thread.addTag(type)
    if rape
        thread.IsAggressive = true
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_Execute: Thread is aggressive")
    else
        thread.IsAggressive = false
        Debug.Trace("[SexLab_SkyrimNet] SexTarget_Execute: Thread is not aggressive")
    endif 
    thread.StartThread() 
EndFunction

String function YesNoDialog(Bool rape, Actor domActor, Actor subActor, Actor player) global
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
    else
        question = "Would like to have sex "+name+"?"
    endif 
    
    String result = SkyMessage.Show(question, "Yes","No")
    if result == "Yes"
        String[] types = GetTypes() 
        uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") AS uilistmenu
        int i =  0
        int count = types.Length
        while i < count
            listMenu.AddEntryItem(types[i])
            i += 1
        endwhile
        listMenu.OpenMenu()
        String type =  listmenu.GetResultString()
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
