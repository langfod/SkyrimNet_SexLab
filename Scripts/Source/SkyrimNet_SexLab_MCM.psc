Scriptname SkyrimNet_SexLab_MCM extends SKI_ConfigBase

int rape_toggle
int public_sex_toggle
String[] Pages 

SkyrimNet_SexLab_Main Property main Auto  

Event OnConfigOpen()

    Pages = None ; new String[0]
    ;pages[0] = "options"

EndEvent

Event OnPageReset(string page)

    SetCursorFillMode(LEFT_TO_RIGHT)
    SetCursorPosition(0)
    
    AddHeaderOption("Options")
    AddHeaderOption("")

    rape_toggle = AddToggleOption("Enable rape action (must save then reload)",main.rape_allowed)
    public_sex_toggle = AddToggleOption("Public sex accepted",main.public_sex_accepted)

EndEvent

Event OnOptionSelect(int option)

    if option == rape_toggle
        main.rape_allowed = !main.rape_allowed
        SetToggleOptionValue(option, main.rape_allowed)
    endif
    if option == public_sex_toggle
        main.public_sex_accepted = !main.public_sex_accepted
        SetToggleOptionValue(option, main.public_sex_accepted)
    endif

EndEvent