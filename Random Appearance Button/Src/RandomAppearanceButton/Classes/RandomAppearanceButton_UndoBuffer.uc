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

class RandomAppearanceButton_UndoBuffer extends Object
	dependson(RandomAppearanceButton_Utilities);

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

struct AppearanceState {
	var array<int> Trait;
};

var array<AppearanceState> Buffer;

var UICustomize_Menu CustomizeMenuScreen;

const MAX_UNDO_BUFFER_SIZE = 10;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

simulated function Init(const out UICustomize_Menu Screen)
{
	ClearTheBuffer();

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

simulated function PushOnToBuffer(const out AppearanceState StateToStore)
{
	if (Buffer.Length == MAX_UNDO_BUFFER_SIZE) {
		PopBackOffTheBuffer();
	}

	Buffer.AddItem(StateToStore);
}

simulated function AppearanceState PopBackOffTheBuffer()
{
	local AppearanceState Back;

	Back = Buffer[0];

	Buffer.Remove(0, 1);

	return Back;
}

simulated function AppearanceState PopFrontOffTheBuffer()
{
	local AppearanceState Front;

	Front = Buffer[Buffer.Length - 1];
	Buffer.Remove(Buffer.Length - 1, 1);

	return Front;
}

simulated function AppearanceState GetFrontOfBuffer()
{
	return Buffer[Buffer.Length - 1];
}

simulated function ClearTheBuffer()
{
	Buffer.Length = 0;
}

simulated function StoreCurrentState()
{
	local AppearanceState	CurrentState;
	local AppearanceState	BufferFront;

	/*
		Iterate over all trait categories, get their current values, store them
		into an AppearanceState struct, then push it onto the buffer.
	*/

	`log("UNDO BUFFER: Storing current state.");

	CurrentState = AppearanceStateSnapshot(CustomizeMenuScreen);
	BufferFront = GetFrontOfBuffer();


	/*
		We only want to store the current state if it's NOT identical to the
		one already at the front of the buffer.
		
		If they're different, store it.

		If there's an identical state already on the buffer, we don't want to
		duplicate, so we just ignore this.

		This provides support for cases where the user's changed the soldier's
		appearance with the normal UI and wants our UNDO button to do what
		you'd expect it to do.
	*/

	if ( !CompareAppearanceStates( CurrentState, BufferFront) ) {
		`log("UNDO BUFFER: Current state isn't at the front of the buffer; storing it.");
		PushOnToBuffer(CurrentState);
	} else {
		`log("UNDO BUFFER: CurrentState matches BufferFront, NOT STORING.");
	}

	`log("UNDO BUFFER: Buffer size now" @ Buffer.Length);
}


simulated static function AppearanceState AppearanceStateSnapshot(const out UICustomize_Menu Screen)
{
	local AppearanceState	CurrentState;
	local int				iCategoryIndex;

	for (iCategoryIndex = 0; iCategoryIndex <= eUICustomizeCat_MAX; iCategoryIndex++)
		CurrentState.Trait[iCategoryIndex] = class'RandomAppearanceButton'.static.GetTrait(Screen, EUICustomizeCategory(iCategoryIndex));

	return CurrentState;
}


simulated static function bool CompareAppearanceStates(const out AppearanceState left, const out AppearanceState right)
{
	local int iCategoryIndex;

	/*
		Iterate over all traits, compare the ones we care about; if any of them are changed,
		return false; otherwise return true.

		NOTE: UE3 doesn't support operator overloading as far as I can tell.
	*/

	`log("UNDO BUFFER: in CompareAppearanceStates");

	for (iCategoryIndex = 0; iCategoryIndex <= eUICustomizeCat_MAX; iCategoryIndex++){
		switch( class'RandomAppearanceButton_Utilities'.static.GetCategoryType(iCategoryIndex) ) {
			case eCategoryType_Prop:
			case eCategoryType_Color:
			case eCategoryType_Gender:
				if (left.Trait[iCategoryIndex] != right.Trait[iCategoryIndex]) {
					`log("UNDO BUFFER: Compare" @ string(iCategoryIndex) @ "NO MATCH:");
					return false;
				} else {
					`log("UNDO BUFFER: Compare" @ string(iCategoryIndex) @ "match");
				}
				break;

			case eCategoryType_IGNORE:
			case eCategoryType_UNKNOWN:
			default:
				`log("UNDO BUFFER: Compare" @ string(iCategoryIndex) @ "ignored/unknown");
				break;
		}
	}

	return true;
}

simulated static function ApplyAppearanceStateSnapshot(const out UICustomize_Menu Screen, const out AppearanceState AppearanceSnapshot/*, const out SoldierPropsLock PropCheckboxes*/)
{
	local int		iCategoryIndex;
	local int		iDirection;
	local bool		bSkipThisTrait;

	bSkipThisTrait = false;

	/*
		Gender needs to be applied FIRST, as ALL other indicies for props are
		relative to gender.

		Also, due to a discrepancy between the gender enum and all other enums
		in the source, we need to -1 the stored value prior to applying it.
		(Otherwise we always get a female no matter what.)

		Note that if Gender is changed, a prop is locked, then  Undo is clicked,
		if the given prop isn't shared across genders, things can get weird. :\
		Not sure how to address this yet. Other than going with "Toggle Gender
		kills the buffer" so I'll go that path for now.
	*/

	class'RandomAppearanceButton'.static.ForceSetTrait(Screen, EUICustomizeCategory(eUICustomizeCat_Gender), 0, AppearanceSnapshot.Trait[eUICustomizeCat_Gender] - 1);
	Screen.UpdateData();	

	for (iCategoryIndex = 0; iCategoryIndex <= eUICustomizeCat_MAX; iCategoryIndex++) {
		switch (class'RandomAppearanceButton_Utilities'.static.GetCategoryType(iCategoryIndex))
		{
			/*
				Non-color appearance props and attributes require a "Direction"
				of 0. I'm not clear on why but that's how they're handled.
			*/
			case eCategoryType_Prop:
				bSkipThisTrait = false;
				iDirection = 0;
				break;

			/*
				Colors require a "Direction" of -1.
			*/
			case eCategoryType_Color:
				bSkipThisTrait = false;
				iDirection = -1;
				break;

			/*
				These aren't randomized by this mod (because they're not appearance traits)
				so skip em. (Not skipping them had the fascinating effect of swapping the
				soldier's gender to female and assigning it whatever outfit the male would've
				received upon Undo click. I can definitely use this with the switch gender
				button.)

				Note that gender's special handling is taken care of before this loop.
			*/
			case eCategoryType_IGNORE:
			case eCategoryType_UNKNOWN:
			case eCategoryType_Gender:
				bSkipThisTrait = true;
				break;

		}
		
		if (!bSkipThisTrait) {
			class'RandomAppearanceButton'.static.ForceSetTrait(Screen, EUICustomizeCategory(iCategoryIndex), iDirection, AppearanceSnapshot.Trait[iCategoryIndex]);
		}

	}
}

simulated function bool Undo()
{
	local AppearanceState		CurrentAppearance;
	local AppearanceState		BufferFront;

	`log("UNDO BUFFER: In Undo.");
	`log("UNDO BUFFER: Buffer size now" @ Buffer.Length);

	if (Buffer.Length == 0)
		return false;

	/*
		If there have been state changes since the last snapshot, that means
		the user has made tweaks via the normal UI; in that case, UNDO should
		rollback to the top-level state without popping it off of the buffer.

		If there haven't been state changes since the last snapshot (i.e.
		the current state and the snapshot are identical) then we rollback
		to the previous snapshot and pop.

		Consider this situation:
		(1) There are TWO states on the buffer after two appearance gen clicks.
		(Uppercase reflects TRACKED/in the buffer).

		[A][B]

		(2) The user has changed the hair color manually, so we have a THIRD 
		UNTRACKED state (lower case reflects untracked/not in the buffer).

		[c]

		FIRST UNDO CLICK wants to get back to [B], so we apply & keep state
		[B], since [B] != [c].

		SECOND UNDO CLICK wants to get back to [A], so we dump [B] then
		apply [A].
	*/

	// local references to conform to further const out params in calls.
	CurrentAppearance = AppearanceStateSnapshot(CustomizeMenuScreen);
	BufferFront = GetFrontOfBuffer();

	if ( CompareAppearanceStates(CurrentAppearance, BufferFront) ) {
		// No state changes: dump *then* apply.
		PopFrontOffTheBuffer(); // This state is already applied and we want to UNDO it.
		BufferFront = GetFrontOfBuffer();
		ApplyAppearanceStateSnapshot(CustomizeMenuScreen, BufferFront);
	} else {
		// Nothing to pop as the thing we want to replace isn't in the buffer.
		ApplyAppearanceStateSnapshot(CustomizeMenuScreen, BufferFront);
	}

	`log("UNDO BUFFER: Buffer size now" @ Buffer.Length);

	return true;
}

defaultproperties
{

}