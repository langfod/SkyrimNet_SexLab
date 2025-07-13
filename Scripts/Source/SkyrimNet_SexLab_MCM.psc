Scriptname SkyrimNet_SexLab_MCM extends SKI_ConfigBase

String[] Pages 

SkyrimNet_SexLab_Main Property main Auto  
SkyrimNet_SexLab_Stages Property stages Auto 

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

    AddToggleOptionST("RapeAllowedToggle","Add rape actions (must toggle/save/reload)",main.rape_allowed)
    AddToggleOptionST("PublicSexAcceptedToggle","Public sex accepted",main.public_sex_accepted)
    AddKeyMapOptionST("DescriptionEditKeyMap", "Edit Stage Descriptions", stages.description_edit_key)
    AddKeyMapOptionST("StartSex", "Start Sex", sex_key)
    Debug.MessageBox("key: "+stages.description_edit_key)

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

State DescriptionEditKeyMap
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
            stages.description_edit_key = keyCode
            Debug.MessageBox("keyCode: "+stages.description_edit_key+" "+keycode)
            SetKeymapOptionValueST(keyCode)
        endif 
    EndEvent
    Event OnHighlightST()
        SetInfoText("Edit the stage's description")
    EndEvent
EndState

