Scriptname SkyrimNet_SexLab_MCM extends SKI_ConfigBase

int rape_toggle
int ublic_sex_toggle
String[] Pages 

SkyrimNet_SexLab_Main Property main Auto  
SkyrimNet_SexLab_Stages Property stages Auto 

bool sex_key_toggle = False 
int sex_key = 40

bool description_edit_toggle = False 
int description_edit_key = 39

Function Trace(String msg, Bool notification=False) global
    msg = "[SkyrimNet_SexLab_MCM] "+msg
    Debug.Trace(msg)
    if notification
        Debug.Notification(msg)
    endif 
EndFunction


Event OnConfigOpen()

    Pages = None ; new String[0]
    ;pages[0] = "options"

EndEvent

int sex_key = 26

Event OnPageReset(string page)

    if stages == None 
       stages = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Stages
    endif


    SetCursorFillMode(LEFT_TO_RIGHT)
    SetCursorPosition(0)
    
    AddHeaderOption("Options")
    AddHeaderOption("")

    Debug.MessageBox("key: "+stages.description_edit_key)

    Debug.MessageBox("key: "+stages.description_edit_key)
    AddToggleOptionST("RapeAllowedToggle","Add rape actions (must toggle/save/reload)",main.rape_allowed)
    AddToggleOptionST("PublicSexAcceptedToggle","Public sex accepted",main.public_sex_accepted)
    AddToggleOptionST("SexEditTagsPlayer","show tags editor for player sex",main.sex_edit_tags_player)
    AddToggleOptionST("SexEditTagsNonPlayer","show tags editor for nonplayer sex",main.sex_edit_tags_nonplayer)
    AddToggleOptionST("SexKeyToggle","Enable sex hotkey",sex_key_toggle)
    AddKeyMapOptionST("SexKeySet", "Start Sex hot key", sex_key)
    AddKeyMapOptionST("DescriptionEditKeyMap", "Edit Stage Descriptions", stages.description_edit_key)
EndEvent

State RapeAllowedToggle
    Event OnSelectST()
        main.rape_allowed = !main.rape_allowed
        SetToggleOptionValueST(main.rape_allowed)
    EndEvent
    Event OnHighlightST()
        SetInfoText("Adds/Removes the NPC rape Actions. Request you save and reload.")
    EndEvent
EndState
State PublicSexAcceptedToggle
    Event OnSelectST()
        main.public_sex_accepted = !main.public_sex_accepted
        SetToggleOptionValueST(main.public_sex_accepted)
    EndEvent
    Event OnHighlightST()
        SetInfoText("Makes public sex a socially accepted activity..")
    EndEvent
EndState

State SexEditTagsPlayer
    Event OnSelectST()
        main.sex_edit_tags_player = !main.sex_edit_tags_player
        SetToggleOptionValueST(main.sex_edit_tags_player)
    EndEvent
    Event OnHighlightST()
        SetInfoText("Opens a tag editor when sex does not include the player.")
    EndEvent
EndState

State SexEditTagsNonPlayer
    Event OnSelectST()
        main.sex_edit_tags_nonplayer = !main.sex_edit_tags_nonplayer
        SetToggleOptionValueST(main.sex_edit_tags_nonplayer)
    EndEvent
    Event OnHighlightST()
        SetInfoText("Opens a tag editor when sex includes the player.")
    EndEvent
EndState

; --------------------------------------------
; Sex Start Hot Key
; --------------------------------------------

State SexKeyToggle
    Event OnSelectST()
        sex_key_toggle = !sex_key_toggle
        SetToggleOptionValueST(sex_key_toggle)
        if !sex_key_toggle
            UnregisterForKey(sex_key)
        else
            RegisterForKey(sex_key)
        endif
        ForcePageReset()
    EndEvent
    Event OnHighlightST()
        SetInfoText("Enables a start sex hot key")
    EndEvent
EndState

State SexKeySet
    Event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
        bool continue = True
        if conflictControl != "" 
            String msg = None 
            if (conflictName != "")
                msg = "This key is already mapped to:\n'" + conflictControl + "'\n(" + conflictName + ")\n\nAre you sure you want to continue?"
            else
                msg = "This key is already mapped to:\n'" + conflictControl + "'\n\nAre you sure you want to continue?"
            endIf

            continue = ShowMessage(msg, true, "$Yes", "$No")
        endif 
        if continue 
            UnregisterForKey(sex_key)
            sex_key = keyCode
            RegisterForKey(sex_key)
            SetKeymapOptionValueST(sex_key)
        endif 
    EndEvent
    Event OnHighlightST()
        SetInfoText("Will start sex between the player and the actor in the crosshairs")
    EndEvent
EndState

; --------------------------------------------
; Edit Stage Description 
; --------------------------------------------

State DescriptionEditToggle
    Event OnSelectST()
        description_edit_toggle = !description_edit_toggle
        SetToggleOptionValueST(description_edit_toggle)
        if !description_edit_toggle
            UnregisterForKey(description_edit_key)
        else
            RegisterForKey(description_edit_key)
        endif
        ForcePageReset()
    EndEvent
    Event OnHighlightST()
        SetInfoText("Enables hot key used to edit stage descriptions")
    EndEvent
EndState

State DescriptionEditKey
    Event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
        bool continue = True
        if conflictControl != "" 
            String msg = None 
            if (conflictName != "")
                msg = "This key is already mapped to:\n'" + conflictControl + "'\n(" + conflictName + ")\n\nAre you sure you want to continue?"
            else
                msg = "This key is already mapped to:\n'" + conflictControl + "'\n\nAre you sure you want to continue?"
            endIf

            continue = ShowMessage(msg, true, "$Yes", "$No")
        endif 
        if continue 
            UnregisterForKey(description_edit_key)
            description_edit_key = keyCode
            RegisterForKey(description_edit_key)
            SetKeymapOptionValueST(description_edit_key)
        endif 
    EndEvent
    Event OnHighlightST()
        SetInfoText("Hot key will bring up the stage desciption editor.")
    EndEvent
EndState

; --------------------------------------------
; Handles OnKeyDown 
; --------------------------------------------

Event OnKeyDown(int key_code)

    if UI.IsTextInputEnabled()
        return 
    endif 

    if description_editor_key == key_code 
        stages.EditDescription() 
    elseif sex_key == key_code

        ; Both players need to be in the crosshair to have SkyrimNet load them into the cache
        ; so the parseJsonActor works
        Actor target = Game.GetCurrentCrosshairRef() as Actor 
        Actor player = Game.GetPlayer() 
        if target != None 
            int mastrubation = 0
            int sex = 1
            String[] buttons = new String[2]
            buttons[mastrubation] = "mastrubate"
            buttons[sex] = "have sex with player"
            int button = SkyMessage.ShowArray("Should "+target.getDisplayName()+":", buttons, getIndex = true) as int  

            if button == mastrubation
                SkyrimNet_SexLab_Actions.SexTarget_Execute(target, "", "{\"type\":\"masturbation\"}")
            else 
                SkyrimNet_SexLab_Actions.SexTarget_Execute(target, "", "{\"target\":\""+player.GetDisplayName()+"\",\"target_is_player\":true}")
            endif 
            return 
        endif 

        Actor[] actors = MiscUtil.ScanCellActors(player, 1000)
        String[] names = Utility.CreateStringArray(actors.length)

        int i = 0 
        int num_actors = actors.Length
        while i < num_actors 
            names[i] = actors[i].GetDisplayName()
            i += 1
        endwhile 

        String[] members = new String[3]

        String remove = "<remove"
        String cancel = "<cancel>"
        String type = "sex>"

        int next = 0 
        bool building_list = true 
        int index = 1
        uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") AS uilistmenu
        ; I couldn't compare directly to the strings button in some case
        ; so fell back on next and index :(
        while next == 0 || index != 0
            listMenu.ResetMenu()
            i = 0
            String start = ""
            if next > 0
                while i < next
                    if start != ""
                        start += "+"
                    endif
                    start += members[i]
                    i += 1
                endwhile 
                start = "<start with: "+start+">"
                listMenu.AddEntryItem(start)
                listMenu.AddEntryItem(remove)
            endif 
            listmenu.AddEntryItem(type)

            if next < members.length
                i = 0 
                while i < num_actors
                    bool found = false 
                    int j = next - 1
                    while 0 <= j  && !found
                        if names[i] == members[j]
                            found = True
                        endif 
                        j -= 1
                    endwhile
                    if !found
                        if SkyrimNet_SexLab_Actions.SexTarget_IsEligible(actors[i], "", "") 
                            listMenu.AddEntryItem(names[i])
                        endif 
                    endif 
                    i += 1
                endwhile 
            endif 
            listMenu.AddEntryItem(cancel)

            listMenu.OpenMenu()
            String button = listMenu.GetResultString()
            index = listMenu.GetResultInt()
            if next == 0 || index != 0
                index = 1
                if button == remove 
                    next -= 1
                elseif button == type
                    type = SexRapeSelection()
                elseif button == cancel
                    return 
                else
                    members[next] = button
                    next += 1
                endif
            endif 
        endwhile

        Actor[] mActors =  new Actor[5]
        i = 0 
        while i < next 
            int j = 0 
            while j < num_actors 
                if members[i] == names[j] 
                    mActors[i] = actors[j] 
                    j = num_actors
                endif 
                j += 1
            endwhile 
            i += 1 
        endwhile 

        StartSex(mActors, next, type == "rape>")
    endif 
EndEvent 

Function StartSex(Actor[] actors, int num_actors, bool is_rape) 
    Trace("SexTarget_Execute: "+actors+" num_actors:"+num_actors+" is_rape:"+is_rape)
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Trace("SexTarget_Execute: SexLab is None", true)
        return
    endif

    ; Check the lock 
    int i = 0
    while i < num_actors 
        if main.IsActorLocked(actors[i])
            return 
        endif 
        i += 1
    endwhile

    ; Lock the actors 
    i = 0
    while i < num_actors 
        main.SetActorLock(actors[i])
        i += 1
    endwhile

    sslThreadModel thread = sexlab.NewThread()
    if thread == None
        Trace("StartSex: Failed to create thread")
        return 
    endif
    ; Lock the actors 
    i = 0
    while !failure && i < num_actors 
        main.SetActorLock(actors[i])
        i += 1
    endwhile 

    ; Attempt to add the actors 
    bool failure = false 
    i = 0
    while !failure && i < num_actors 
        if thread.addActor(actors[i]) < 0   
            Trace("StartSex: Starting sex couldn't add "+i+" "+actors[i].GetDisplayName())
            failure = true 
        endif  
        i += 1
    endwhile

    if failure
        i = 0 
        while i <= num_actors 
            main.ReleaseActorLock(actors[i])
            i += 1 
        endwhile 
        return
    endif

    sslBaseAnimation[] anims = SkyrimNet_SexLab_Actions.AnimsDialog(sexlab, 2, "")
    if anims != None && anims.length > 0
        thread.SetAnimations(anims)
    endif

    if is_rape
        thread.IsAggressive = true
    else
        thread.IsAggressive = false
    endif 

    thread.StartThread() 
EndFunction 

String Function SexRapeSelection()
    uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") AS uilistmenu
    listMenu.ResetMenu()
    listMenu.AddEntryItem("sex")
    listMenu.AddEntryItem("rape")
    listMenu.OpenMenu()
    if listMenu.GetResultInt() == 0
        return "sex>"
    else
        return "rape>"
    endif
EndFunction