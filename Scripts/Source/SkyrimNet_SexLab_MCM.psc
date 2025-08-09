Scriptname SkyrimNet_SexLab_MCM extends SKI_ConfigBase

import SkyrimNet_SexLab_Actions

int rape_toggle
GlobalVariable Property sexlab_public_sex_accepted Auto

SkyrimNet_SexLab_Main Property main Auto  
SkyrimNet_SexLab_Stages Property stages Auto 

bool hot_key_toggle = False 
int sex_edit_key = 40 ; 26

Function Trace(String msg, Bool notification=False) global
    msg = "[SkyrimNet_SexLab_MCM] "+msg
    Debug.Trace(msg)
    if notification
        Debug.Notification(msg)
    endif 
EndFunction

Event OnConfigOpen()

    ;Pages = new String[1]
    ;pages[0] = "options"

EndEvent

Event OnPageReset(string page)

    if stages == None 
       stages = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Stages
    endif

    SetCursorFillMode(LEFT_TO_RIGHT)
    SetCursorPosition(0)
    
    AddHeaderOption("Options")
    AddHeaderOption("")
    AddToggleOptionST("RapeAllowedToggle","Add rape actions (must toggle/save/reload)",main.rape_allowed)
    AddToggleOptionST("PublicSexAcceptedToggle","Public sex accepted",sexlab_public_sex_accepted.GetValue() == 1.0)
    AddToggleOptionST("SexEditTagsPlayer","Show Tags_Editor for player sex",main.sex_edit_tags_player)
    AddToggleOptionST("SexEditTagsNonPlayer","Show Tags_Editor for nonplayer sex",main.sex_edit_tags_nonplayer)

    AddHeaderOption("")
    AddHeaderOption("")
    AddToggleOptionST("HotKeyToggle","Enable the Start Sex / Edit Stage hot key",hot_key_toggle)
    AddKeyMapOptionST("SexEditKeySet", "Start Sex / Edit Stage Description", sex_edit_key)

    if hot_key_toggle 
        RegisterForKey(sex_edit_key)
    endif 

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
        Bool public_bool = False
        if sexlab_public_sex_accepted.GetValue() == 1.0
            public_bool = False
            sexlab_public_sex_accepted.SetValue(0.0)
        else
            public_bool = True
            sexlab_public_sex_accepted.SetValue(1.0)
        endif 
        SetToggleOptionValueST(public_bool)
        Trace("PublicSexAcceptedToggle: sexlab_public"+sexlab_public_sex_accepted.GetValue(),true)
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
; Hot Keys 
; --------------------------------------------

State HotKeyToggle
    Event OnSelectST()
        hot_key_toggle = !hot_key_toggle
        SetToggleOptionValueST(hot_key_toggle)
        if !hot_key_toggle
            UnregisterForKey(sex_edit_key)
        else
            RegisterForKey(sex_edit_key)
        endif
        ForcePageReset()
    EndEvent
    Event OnHighlightST()
        SetInfoText("Enables the Sex Edit Hotkey.\n")
    EndEvent
EndState

State SexEditKeySet
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
            UnregisterForKey(sex_edit_key)
            sex_edit_key = keyCode
            RegisterForKey(sex_edit_key)
            SetKeymapOptionValueST(sex_edit_key)
        endif 
    EndEvent
    Event OnHighlightST()
        SetInfoText( \
            "For an actor in the crosshair and not in a sex animation, it will allow you to start a sex animation.\n" \
          + "For an actor in the crosshair and in a sex animation, it will open a stage description editor for that animation.\n" \
          + "Without any actor in the crosshair, it will allow you to start sex between a near by set of eligible actors.")
    EndEvent
EndState

; --------------------------------------------
; Handles OnKeyDown 
; --------------------------------------------

Event OnKeyDown(int key_code)
    if UI.IsTextInputEnabled()
        return 
    endif 

    if sex_edit_key == key_code

        ; Both players need to be in the crosshair to have SkyrimNet load them into the cache
        ; so the parseJsonActor works
        Actor target = Game.GetCurrentCrosshairRef() as Actor 
        Actor player = Game.GetPlayer() 
        if target != None 
            if SexTarget_IsEligible(target,"","")
                int masturbate = 0
                int sex = 1
                int raped_by = 2
                int rapes = 3
                int clothing = 4
                int cancel = 5
                String[] buttons = new String[6]
                buttons[masturbate] = "masturbate"
                buttons[sex] = "have sex with player"
                buttons[raped_by] = "raped by player"
                buttons[rapes] = "rapes the player"
                if main.HasStrippedItems(target)
                    buttons[clothing] = "dress"
                else
                    buttons[clothing] = "undress"
                endif 
                buttons[cancel] = "cancel"
                int button = SkyMessage.ShowArray("Should "+target.getDisplayName()+":", buttons, getIndex = true) as int  

                if button == masturbate
                    SkyrimNet_SexLab_Actions.SexTarget_Execute(target, "", "{\"type\":\"masturbation\"}")
                elseif button == sex
                    SkyrimNet_SexLab_Actions.SexTarget_Execute(target, "", "{\"rape\":false, \"target\":\""+player.GetDisplayName()+"\",\"target_is_player\":true}")
                elseif button == rapes
                    SkyrimNet_SexLab_Actions.SexTarget_Execute(target, "", "{\"rape\":true, \"target\":\""+player.GetDisplayName()+"\",\"victim\":false, \"target_is_player\":true}")
                elseif button == raped_by
                    SkyrimNet_SexLab_Actions.SexTarget_Execute(target, "", "{\"rape\":true, \"target\":\""+player.GetDisplayName()+"\",\"victim\":true,\"target_is_player\":true}")
                elseif button == clothing
                    if main.HasStrippedItems(target)
                        SkyrimNet_SexLab_Actions.Dress_Execute(target, "", "")
                    else
                        SkyrimNet_SexLab_Actions.Undress_Execute(target, "", "")
                    endif
                else 
                    return 
                endif 
                return 
            else
                sslThreadController thread = stages.GetThread(target)
                if thread != None 
                    stages.EditDescriptions(thread) 
                endif 
                return 
            endif 
        endif 

        ; See if player is in a sex animation 
        sslThreadController thread = stages.GetThread(player)
        if thread != None 
            stages.EditDescriptions(thread) 
            return
        endif

        ; If not, then we allow them to start a sex animation with nearby actors
        Actor[] actors = MiscUtil.ScanCellActors(player, 1000)
        if actors.length < 2
            actors = MiscUtil.ScanCellActors(player, 2000)
            if actors.length == 0
                Debug.Notification("No eligible actors found in the area.")
                return
            endif 
        endif 
        Trace("Found "+actors.length+" actors in the area.")

        int i = 0 
        int num_actors = actors.Length
        String[] names = Utility.CreateStringArray(actors.length)
        while i < num_actors 
            names[i] = actors[i].GetDisplayName()
            i += 1
        endwhile 

        String[] members = new String[5]

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

        Actor[] mActors = PapyrusUtil.ActorArray(next)
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

        StartSex(mActors, type == "rape>")
    endif 
EndEvent 

Function StartSex(Actor[] actors, bool is_rape) 
    Trace("SexTarget_Execute: "+actors+" num_actors:"+num_actors+" is_rape:"+is_rape)
    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    if SexLab == None
        Trace("SexTarget_Execute: SexLab is None", true)
        return
    endif

    ; Lock the actors 
    int num_actors = actors.length 
    int i = 0
    bool cancel = false
    while !cancel && i < num_actors 
        if !main.SetActorLock(actors[i])
            cancel = true
        endif 
        main.SetActorLock(actors[i])
        i += 1
    endwhile

    sslThreadModel thread = None 
    if !cancel
        thread = sexlab.NewThread()
        if thread == None
            Trace("StartSex: Failed to create thread")
            cancel = true
        endif
    endif 

    ; Attempt to add the actors 
    if !cancel
        sslBaseAnimation[] anims = SkyrimNet_SexLab_Actions.AnimsDialog(sexlab, actors, "")
        if anims.length > 0
            if anims[0] == None 
                cancel = true
            else 
                thread.SetAnimations(anims)
            endif 
        endif 
    endif

    i = 0
    while !cancel && i < num_actors 
        if thread.addActor(actors[i]) < 0   
            Trace("StartSex: Starting sex couldn't add "+i+" "+actors[i].GetDisplayName())
            cancel = true 
        endif  
        i += 1
    endwhile


    if cancel
        i = 0 
        while i <= num_actors 
            Debug.Notification("releasing actor "+actors[i].GetDisplayName())
            main.ReleaseActorLock(actors[i])
            i += 1 
        endwhile 
        return
    endif

    if is_rape
        thread.SetVictim(actors[0])
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