Scriptname SkyrimNet_SexLab_Actions 

Function Trace(String msg, Bool notification=False) global
    if notification
        Debug.Notification(msg)
    endif 
    msg = "[SkyrimNet_SexLab.Actions] "+msg
    Debug.Trace(msg)
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
        if type != "any"
            if type != "" 
                type += "|"
            endif 
            type += types[i]
        endif 
        i += 1
    endwhile 

    ; ------------------------
    ; This also has a undress/dress action
    if MiscUtil.FileExists("Data/ArcaneSexBot.esl") 
        SkyrimNetApi.RegisterAction("SexLabSexTarget", \
                "Start having consensual sex with {target}.", \
                "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
                "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
                "", "PAPYRUS", 1, \
                "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":false, \"target_victim\":false}")
        SkyrimNetApi.RegisterAction("SexLabSexMasturbation", \
                "Start masturbating.",\
                "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
                "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
                "", "PAPYRUS", 1, \
                "{\"type\":\"masturbation\", \"rape\":{true|false}}")
    endif 

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
                "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":true, \"target_victim\":true}")
        SkyrimNetApi.RegisterAction("SexLab_RapedByTarget", \
                "Start being sexually assulted by {target}.",\
                "SkyrimNet_SexLab_Actions", "SexTarget_IsEligible",  \
                "SkyrimNet_SexLab_Actions", "SexTarget_Execute",  \
                "", "PAPYRUS", 1, \
                "{\"target\": \"Actor\", \"type\":\""+type+"\", \"rape\":true, \"target_victim\":false}")
    endif 

EndFunction

; -------------------------------------------------
; ACtions 
; -------------------------------------------------

String[] Function GetTypes() global
    String[] types = new String[11]
    types[0] = "handjob"
    types[1] = "oral"
    types[2] = "boobjob"
    types[3] = "thighjob"
    types[4] = "vaginal"
    types[5] = "fisting"
    types[6] = "anal"
    types[7] = "dildo"
    types[9] = "fingering"
    types[10] = "footjob"
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
    Trace("SexTarget_Execute: "+akActor.GetDisplayName()+" "+paramsJson)
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

    Actor player = Game.GetPlayer()
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type","")
    Actor akTarget = None
    if type != "masturbation" && type != "masturbate"
        akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", None)
        if akTarget == None 
            if SkyrimNetApi.GetJsonBool(paramsJson, "target_is_player", false)
                akTarget = player
            endif 
        endif 
        if akTarget == None 
            Trace("SexTarget type != masturbation, but target is None (likely in complete Actor name)", true )
            return 
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

    Actor domActor = akActor
    Actor subActor = akTarget 
    Bool target_is_victim = SkyrimNetApi.GetJsonBool(paramsJson, "target_is_victim", true)
    if akTarget != None && !target_is_victim 
        domActor = akTarget
        subActor = akActor
    endif

    int YES = 0
    int YES_RANDOM = 1
    int NO_SILENT = 2
    int NO = 3

    bool rape = SkyrimNetApi.GetJsonBool(paramsJson, "rape", false)
    int button = YES 
    if subActor == player || (domActor != None && domActor == player)
        button = SkyrimNet_SexLab_Utils.YesNoSexDialog(type, rape, domActor, subActor, player)
        if button == NO || button == NO_SILENT
            Trace("SexTarget_Execute: User declined")
            main.ReleaseActorLock(akActor)
            main.ReleaseActorLock(akTarget)
            return 
        endif 
    endif

    int num_actors = 1
    if domActor != None
        num_actors = 2
    endif 

    bool failure = False
    sslThreadModel thread = sexlab.NewThread()
    if thread == None
        Trace("SexTarget_Execute: Failed to create thread")
        failure = true 
    endif
    if button != YES_RANDOM
        if type == "kissing"
            String tagSupress = "oral,vaginal,anal,spanking,masturbate,handjob,footjob,masturbation,breastfeeding,fingering"
            sslBaseAnimation[] anims =  SexLab.GetAnimationsByTags(num_actors, type, tagSupress, true)
            if anims.length > 0
                thread.SetAnimations(anims)
                thread.addTag(type)
            else
                Trace("No kissing animation found",true)
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

                sslBaseAnimation[] anims = SkyrimNet_SexLab_Utils.AnimsDialog(sexlab, actors, "")
                if anims.length > 0 && anims[0] != None  
                    thread.SetAnimations(anims)
                endif 
    
            endif 
        endif 
    endif 
    
    if !failure 
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

    if rape
        thread.SetVictim(subActor)
    endif 
    Trace("SexTarget_Executer: Starting type:"+type+" aggressive:"+thread.IsAggressive)

    thread.StartThread() 
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
