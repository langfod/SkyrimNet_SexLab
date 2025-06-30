Scriptname SexLab_SkyrimNet_Actions

;----------------------------------------------------------------------------------------------------
; Actions
;----------------------------------------------------------------------------------------------------
Function RegisterActions() global
    Debug.Trace("SexLab_SkyrimNet_Main: RegisterActions called")
    SkyrimNetApi.RegisterAction("SexTarget", \
            "Have {type} sex, or make love,  with {target}.", \
            "SexLab_SkyrimNet_Actions", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"target\": \"Actor\", \"type\":\"vaginal|anal|oral|fingering\", \"rape\":false}")
    SkyrimNetApi.RegisterAction("RapeTarget", \
            "Starts being {type} raped by {target}.", \
            "SexLab_SkyrimNet_Actions", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"target\": \"Actor\", \"type\":\"vaginal|anal|oral|fingering\", \"rape\":true}")
    SkyrimNetApi.RegisterAction("SexMasturbation", \
            "Start masturbating.", \
            "SexLab_SkyrimNet_Actions", "SexTarget_IsEligible",  \
            "SexLab_SkyrimNet_Actions", "SexTarget_Execute",  \
            "", "PAPYRUS", \
            1, "{\"type\":\"masturbation\", \"rape\":{true|false}}")
EndFunction

Bool Function SexTarget_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Debug.Notification("[SexLab_SkyrimNet] SetTarge_IsEigible: SexLab is None")
        Debug.Trace("[SexLab_SkyrimNet] SetTarge_IsEigible: SexLab is None")
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

    sslThreadModel thread = sexlab.NewThread()
    if thread == None
        Debug.Notification("[SexTarget_Execute] Failed to create thread")
        Debug.Trace("[SexTarget_Execute] Failed to create thread")
        return  
    endif
    if thread.addActor(akActor) < 0   
        Debug.Trace("[SexTarget_Execute] Starting sex couldn't add " + akActor.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
        return
    endif  
    int num_actors = 1
    if akTarget != None 
        num_actors = 2
        if thread.addActor(akTarget) < 0   
            Debug.Trace("[SexTarget_Execute] Starting sex couldn't add " + akTarget.GetLeveledActorBase().GetName() + " and target: " + akTarget.GetLeveledActorBase().GetName())
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
        String[] types = new String[14]
        types[0] = "any"
        types[1] = "oral"
        types[2] = "boobjob"
        types[3] = "thighjob"
        types[4] = "vaginal"
        types[5] = "fisting"
        types[6] = "anal"
        types[7] = "spanking"
        types[8] = "fingering"
        types[9] = "footjob"
        types[10] = "handjob"
        types[11] = "kissing"
        types[12] = "headpat"
        types[13] = "dildo"
        uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") AS uilistmenu
        int i =  0
        int count = types.Length
        while i < count
            listMenu.AddEntryItem(types[i])
            i += 1
        endwhile
        listMenu.OpenMenu()
        return listmenu.GetResultString()
    endif 
    return "No"
EndFunction