Scriptname SkyrimNet_SexLab_NudeRef extends ReferenceAlias

String storage_key = "skyrimnet_sexlab_storage_items"

sslSystemConfig Config 
sslActorLibrary Lib 

Function Trace(String msg, Bool notification=False) global
    if notification
        Debug.Notification(msg)
    endif 
    msg = "[SkyrimNet_SexLab.NudeRef] "+msg
    Debug.Trace(msg)
EndFunction

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
    Trace("OnObjectEquipped "+akBaseObject+" ref:"+akReference)
    Actor akActor = GetActorRef()
	if !Config
		Quest q = Game.GetFormFromFile(0xD62, "SexLab.esm") as Quest 
		Config = q as sslSystemConfig 
		Lib = q as sslActorLibrary
	endIf
	bool IsFemale = Lib.GetGender(akActor) == 1
	bool[] Strip = Config.GetStrip(IsFemale, false, false, false) 

	; check that they didn't equip armour
	int i = 31
	while i >= 0
		; Grab item in slot
		Form ItemRef = akActor.GetWornForm(Armor.GetMaskForSlot(i + 30))
		if ContinueStrip(ItemRef, strip[i])
			if !StorageUtil.FormListHas(akActor, storage_key, ItemRef)
				StorageUtil.FormListAdd(akActor, storage_key, ItemRef)
			endif 
			akActor.UnequipItemEX(ItemRef, 0, false)
		endif 
		i -= 1
	endWhile
EndEvent

bool function ContinueStrip(Form ItemRef, bool DoStrip = true)
	; Sexlab 
	if StorageUtil.FormListHas(none, "AlwaysStrip", ItemRef) || SexLabUtil.HasKeywordSub(ItemRef, "AlwaysStrip")
		if StorageUtil.GetIntValue(ItemRef, "SometimesStrip", 100) < 100
			if !DoStrip
				return (StorageUtil.GetIntValue(ItemRef, "SometimesStrip", 100) >= Utility.RandomInt(76, 100))
			endIf
			return (StorageUtil.GetIntValue(ItemRef, "SometimesStrip", 100) >= Utility.RandomInt(1, 100))
		endIf
		return True
	endIf
	return (DoStrip && !(StorageUtil.FormListHas(none, "NoStrip", ItemRef) || SexLabUtil.HasKeywordSub(ItemRef, "NoStrip")))
endFunction