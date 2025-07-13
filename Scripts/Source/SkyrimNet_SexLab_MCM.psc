Scriptname SkyrimNet_SexLab_MCM extends SKI_ConfigBase

int rape_toggle
int ublic_sex_toggle
String[] Pages 

SkyrimNet_SexLab_Main Property main Auto  

bool sex_key_toggle = False 
int sex_key = 40

Event OnConfigOpen()

    Pages = None ; new String[0]
    ;pages[0] = "options"

EndEvent

Event OnPageReset(string page)

    SetCursorFillMode(LEFT_TO_RIGHT)
    SetCursorPosition(0)
    
    AddHeaderOption("Options")
    AddHeaderOption("")

    AddToggleOptionST("RapeAllowedToggle","Add rape actions (must toggle/save/reload)",main.rape_allowed)
    AddToggleOptionST("PublicSexAcceptedToggle","Public sex accepted",main.public_sex_accepted)
    AddToggleOptionST("SexKeyToggle","Enable sex hotkey",sex_key_toggle)
    AddKeyMapOptionST("SexKeySet", "Start Sex hot key", sex_key)
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

; --------------------------------------------
; Sex Hot Key
; --------------------------------------------

State SexKeyToggle
    Event OnSelectST()
        sex_key_toggle = !sex_key_toggle
        SetToggleOptionValueST(sex_key_toggle)
        if !sex_key_toggle
            UnregisterForKey(sex_key)
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