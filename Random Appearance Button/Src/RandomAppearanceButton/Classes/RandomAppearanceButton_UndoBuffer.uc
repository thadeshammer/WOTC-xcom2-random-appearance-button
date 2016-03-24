/*

	RandomAppearanceButton Mod Undo Feature

	When one of the generator buttons in the mod is clicked, those callbacks
	create 'appearance states' which are stored on the undo buffer up to a max
	of MAX_UNDO_BUFFER_SIZE (defined below).

	As states are generated they're pushed onto the buffer; the most recent state is
	at the FRONT of the buffer (index Buffer.Length - 1).

	If adding states to the buffer would exceed max length, the BACK of the buffer
	(index 0) is dropped to make space.

	NOTES

	If the buffer is empty (either because it hasn't been initialized OR because
	the user has clicked Undo and backstepped through the entire buffer) then
	the button should be disabled. Since this doesn't handle the button (the
	screen listener will) it should have a function that reports whether the
	array (of queues) is empty or not.

	Undo can safely be spam-called with an empty buffer with no ill effect, so
	the disable is really just to communicate to the user what's up.

	TODO.

	The Undo button needs to grey-out when it won't work.
*/

class RandomAppearanceButton_UndoBuffer extends Object;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

struct AppearanceState {
	var array<int> Trait;
};

var array<AppearanceState> Buffer;

var UICustomize_Menu CustomizeMenuScreen;

const MAX_UNDO_BUFFER_SIZE = 5;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

simulated function Init(UICustomize_Menu Screen)
{
	Buffer.Length = 0;

	CustomizeMenuScreen = Screen;

	`log("");
	`log("* * * * * * * * * * * * * * * * * *");
	`log("");
	`log("UNDO BUFFER: Initialized.");
	`log("");
	`log("* * * * * * * * * * * * * * * * * *");
	`log("");
}

simulated function bool BufferIsEmpty()
{
	// All of the queues need to always be the same length.

	if (Buffer.Length == 0)
		return true;
	else
		return false;
}

simulated function bool CanUndo()
{
	if (!BufferIsEmpty())
		`log("UNDO BUFFER: Able to undo (there's stuff in the buffer).");
	else
		`log("UNDO BUFFER: Can't undo (the buffer is empty).");

	return !BufferIsEmpty();
}

simulated function PushOnToBuffer(AppearanceState StateToStore)
{
	if (Buffer.Length == MAX_UNDO_BUFFER_SIZE) {
		PopBackOffTheBuffer();
	}

	Buffer.AddItem(StateToStore);
}

simulated function PopBackOffTheBuffer()
{
	Buffer.Remove(0, 1);
}

simulated function PopFrontOffTheBuffer()
{
	Buffer.Remove(Buffer.Length - 1, 1);
}

simulated function AppearanceState GetFrontOfBuffer()
{
	return Buffer[Buffer.Length - 1];
}

simulated function StoreCurrentState()
{
	local AppearanceState	CurrentState;

	/*
		Iterate over all trait categories, get their current values, store them
		into an AppearanceState struct, then push it onto the buffer.
	*/

	`log("UNDO BUFFER: Storing current state.");

	CurrentState = AppearanceStateSnapshot(CustomizeMenuScreen);
	PushOnToBuffer(CurrentState);

	`log("UNDO BUFFER: Buffer size now" @ Buffer.Length);
}

simulated static function AppearanceState AppearanceStateSnapshot(UICustomize_Menu Screen)
{
	local AppearanceState	CurrentState;
	local int				iCategoryIndex;

	for (iCategoryIndex = 0; iCategoryIndex <= eUICustomizeCat_MAX; iCategoryIndex++)
		CurrentState.Trait[iCategoryIndex] = class'RandomAppearanceButton'.static.GetTrait(Screen, EUICustomizeCategory(iCategoryIndex));

	return CurrentState;
}

simulated static function ApplyAppearanceStateSnapshot(UICustomize_Menu Screen, AppearanceState AppearanceSnapshot)
{
	local int		iCategoryIndex;
	local int		iDirection;
	local bool		bSkipThisTrait;

	bSkipThisTrait = false;

	for (iCategoryIndex = 0; iCategoryIndex <= eUICustomizeCat_MAX; iCategoryIndex++) {
		switch (iCategoryIndex)
		{
			/*
				Non-color appearance props and attributes require a "Direction"
				of 0. I'm not clear on why but that's how they're handled.
			*/
			case eUICustomizeCat_Face:
			case eUICustomizeCat_Hairstyle:
			case eUICustomizeCat_Race:
			case eUICustomizeCat_Arms:
			case eUICustomizeCat_Torso:
			case eUICustomizeCat_Legs:
			case eUICustomizeCat_FacialHair:
			case eUICustomizeCat_FaceDecorationUpper:
			case eUICustomizeCat_FaceDecorationLower:
			case eUICustomizeCat_Helmet:
			case eUICustomizeCat_ArmorPatterns:
			case eUICustomizeCat_WeaponPatterns:
			case eUICustomizeCat_Scars:
			case eUICustomizeCat_FacePaint:
			case eUICustomizeCat_LeftArmTattoos:
			case eUICustomizeCat_RightArmTattoos:
			case eUICustomizeCat_LeftArmDeco:
			case eUICustomizeCat_RightArmDeco:
			case eUICustomizeCat_LeftArm:
			case eUICustomizeCat_RightArm:
				bSkipThisTrait = false;
				iDirection = 0;
				break;

			/*
				Colors require a "Direction" of -1.
			*/
			case eUICustomizeCat_HairColor:
			case eUICustomizeCat_EyeColor:
			case eUICustomizeCat_PrimaryArmorColor:
			case eUICustomizeCat_SecondaryArmorColor:
			case eUICustomizeCat_WeaponColor:
			case eUICustomizeCat_TattooColor:
				bSkipThisTrait = false;
				iDirection = -1;
				break;

			/*
				These aren't randomized by this mod (because they're not appearance traits)
				so skip em. (Not skipping them had the fascinating effect of swapping the
				soldier's gender to female and assigning it whatever outfit the male would've
				received upon Undo click. I can definitely use this with the switch gender
				button.)
			*/
			case eUICustomizeCat_FirstName:
			case eUICustomizeCat_LastName:
			case eUICustomizeCat_NickName:
			case eUICustomizeCat_WeaponName:
			case eUICustomizeCat_Personality:
			case eUICustomizeCat_Country:
			case eUICustomizeCat_Voice:
			case eUICustomizeCat_Gender:
			case eUICustomizeCat_Class:
			case eUICustomizeCat_AllowTypeSoldier:
			case eUICustomizeCat_AllowTypeVIP:
			case eUICustomizeCat_AllowTypeDarkVIP:
			case eUICustomizeCat_DEV1:
			case eUICustomizeCat_DEV2:
				bSkipThisTrait = true;

		}
		
		//simulated static function ForceSetTrait(UICustomize_Menu Screen, EUICustomizeCategory eCategory, int iDirection, int iSetting)
		if (!bSkipThisTrait) {
			class'RandomAppearanceButton'.static.ForceSetTrait(Screen, EUICustomizeCategory(iCategoryIndex), iDirection, AppearanceSnapshot.Trait[iCategoryIndex]);
		}

	}
}

simulated function bool Undo()
{
	`log("UNDO BUFFER: In Undo.");
	`log("UNDO BUFFER: Buffer size now" @ Buffer.Length);

	if (Buffer.Length == 0)
		return false;

	//ApplyAppearanceStateSnapshot(CustomizeMenuScreen, Buffer[Buffer.Length - 1]);
	ApplyAppearanceStateSnapshot(CustomizeMenuScreen, GetFrontOfBuffer());

	// pop the recovered layer off of the buffer
	PopFrontOffTheBuffer();

	`log("UNDO BUFFER: Buffer size now" @ Buffer.Length);

	return true;
}

defaultproperties
{

}