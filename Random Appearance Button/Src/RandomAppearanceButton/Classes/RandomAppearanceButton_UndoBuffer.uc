/*

    RandomAppearanceButton Mod Undo Feature

    When one of the generator buttons in the mod is clicked, those callbacks
    create 'appearance states' which are stored on the undo buffer up to a max
    of MAX_UNDO_BUFFER_SIZE (defined below). The most recent state on the buffer
    is as recent as possible (the mod stores before AND after a new appearance
    is generated, but doesn't store duplicates) so that manual changes to the
    generated appearances can be undid.

    As states are generated they're pushed onto the buffer; the most recent state is
    at the FRONT of the buffer (index Buffer.Length - 1).

    If adding states to the buffer would exceed max length, the BACK of the buffer
    (index 0) is dropped to make space.

    Due to what appears to be a race condition between me and the Customize Menu
    itself, the undo button can't work until AFTER one of the mod's appearance
    generating buttons has been pressed. It's a bummer but that's the way of it.

    WOULD BE NICE

    If the button could be greyed out when it can't be used, though this is
    proving difficult with the way things are now. (The race condition described
    above kicks this right in the face.)

    If they ever fix it such that the color picker does fire focus events as
    we'd expect it to, then I can add the counter back to the Undo button
    and keep it up to date.

    TODO/BUGS

    (FIXED) Sometimes undo gets stuck.

    This was tied to incorrectly determining state changes, ultimately fixed
    with added Utility functions which determine whether DLC_1 components are
    involved.

*/

class RandomAppearanceButton_UndoBuffer extends Object
    dependson(RandomAppearanceButton_Utilities);

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

struct AppearanceState {
    var array<int>  Trait;
    var bool        bHasDLC1components;

    structdefaultproperties
    {
        bHasDLC1components = false;
    }
};

var array<AppearanceState> Buffer;
const MAX_UNDO_BUFFER_SIZE = 12;

var UICustomize_Menu CustomizeMenuScreen;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

simulated function Init(const out UICustomize_Menu Screen)
{
    CustomizeMenuScreen = Screen;

    /*
        If I init here, the intial snapsnot NEVER matches the soldier
        even if no changes have been made at all: the mod ALWAYS detects
        manual changes because this stored state doesn't actually reflect
        what the soldier actually looks like.

        This doesn't happen otherwise; appearance snapshots do typically
        reflect precisely what the soldier looks like.

        I believe when I init the buffer here I run into a race condition
        with the game: I think my class inits and is ready prior to the
        soldier actually loading in. The result is that clicking the Undo
        button prior to any changes DETECTS CHANGES because the state
        snapshot is taken of a partially or unloaded soldier.

        I need to lazily initialize (at the last second) instead of doing
        it right off the bat. This means my undo button won't work until
        one of my buttons has been pressed, unless I can find a way init
        after the soldier's loaded into the customize menu.

        Or I could set up a dumb timer to just wait but that seems super
        error prone and dumb.

        I do WANT to init here, which is why this breadcrumb remains
        (along with this oversized breadcrumb).
    */

    //InitTheBuffer();
}

simulated function bool BufferIsEmpty()
{
    // All of the queues need to always be the same length.

    if (Buffer.Length == 0)
        return true;
    else
        return false;
}

simulated function bool AppearanceStateIsEmpty(AppearanceState CurrentState)
{

    /*
        structs are special (they're not Objects nor Actors) and thus
        can't be set or compared to None, so here's special handling
        to deal with that.
    */

    if (CurrentState.Trait.Length == 0)
        return true;
    else
        return false;

}

simulated function bool NoChanges()
{
    local AppearanceState CurrentState;
    local AppearanceState BufferFront;

    `log("UNDO BUFFER: Taking snapshot in NoChanges().");
    CurrentState = TakeAppearanceSnapshot(CustomizeMenuScreen);
    BufferFront = GetFrontOfBuffer();

    if ( CompareAppearanceStates(CurrentState, BufferFront) ) {
        `log("UNDO BUFFER: No changes.");
        return true;
    } else {
        `log("UNDO BUFFER: Changes were made.");
        return false;
    }

}

simulated function bool ChangesWereMade()
{
    return !NoChanges();
}

simulated function bool CanUndo()
{
    /*
        If there's something in the buffer we can undo.
    */

    if (BufferIsEmpty()) {
        `log("UNDO BUFFER: CAN'T UNDO. Buffer's empty.");
        return false;
    } else if (Buffer.Length == 1 && NoChanges()) {
        `log("UNDO BUFFER: WON'T UNDO. Nothing to do: no changes, only one item in the buffer.");
        return false;
    } else if (Buffer.Length == 1 && ChangesWereMade()) {
        `log("UNDO BUFFER: CAN UNDO. Changes detected and one item in the buffer.");
        return true;
    } else if (NoChanges()) {
        `log("UNDO BUFFER: CAN UNDO. No changes detected. Items in buffer:" @ Buffer.Length @ ".");
        return true;
    } else if (ChangesWereMade()) {
        `log("UNDO BUFFER: CAN UNDO. Changes detected. Items in buffer:" @ Buffer.Length @ ".");
        return true;
    }

}

simulated function PushOnToBuffer(const out AppearanceState StateToStore)
{
    if (Buffer.Length == MAX_UNDO_BUFFER_SIZE) {
        PopBackOffTheBuffer();
    }

    Buffer.AddItem(StateToStore);
}

simulated function PopBackOffTheBuffer()
{

    if (!BufferIsEmpty())
        Buffer.Remove(0, 1);

    if (BufferIsEmpty())
        StoreCurrentState();

}

simulated function PopFrontOffTheBuffer()
{

    if (!BufferIsEmpty())
        Buffer.Remove(Buffer.Length - 1, 1);

    if (BufferIsEmpty())
        StoreCurrentState();

}

simulated function AppearanceState GetFrontOfBuffer()
{
    local AppearanceState Front;

    /*
        I have to return SOMETHING as structs can't be "None".

        If you use this function make sure you test it with
        AppearanceStateIsEmpty() or otherwise check what you
        just asked for.
    */

    if (!BufferIsEmpty())
        Front = Buffer[Buffer.Length - 1];

    return Front;
}

simulated function InitTheBuffer()
{
    Buffer.Length = 0;

    if (BufferIsEmpty())
        PushCurrentStateOntoBuffer();
}

simulated function PushCurrentStateOntoBuffer()
{
    /*
        YOU PROBABLY DON'T WANT TO CALL THIS.

        Call StoreCurrentState() instead.
    */

    local AppearanceState CurrentState;

    `log("UNDO BUFFER: Taking snapshot for push onto buffer.");

    CurrentState = TakeAppearanceSnapshot(CustomizeMenuScreen);

    if (CurrentState.bHasDLC1components)
        `log("UNDO BUFFER: Soldier has DLC1 arms.");
    else
        `log("UNDO BUFFER: Soldier does NOT have DLC1 arms.");

    PushOnToBuffer(CurrentState);
}

simulated function StoreCurrentState()
{
    /*
        Iterate over all trait categories, get their current values, store them
        into an AppearanceState struct, then push it onto the buffer.
    */

    `log("UNDO BUFFER: Storing current state.");

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

    if ( BufferIsEmpty() ) {
        `log("UNDO BUFFER: Buffer is emtpy; storing current state.");
        PushCurrentStateOntoBuffer();
    } else if ( ChangesWereMade() ) {
        `log("UNDO BUFFER: Current state isn't at the front of the buffer; storing it.");
        PushCurrentStateOntoBuffer();
    } else {
        `log("UNDO BUFFER: CurrentState matches BufferFront, NOT STORING.");
    }

    `log("UNDO BUFFER: Buffer size now" @ Buffer.Length);
}


simulated static function AppearanceState TakeAppearanceSnapshot(const out UICustomize_Menu Screen)
{
    local AppearanceState           CurrentState;
    local int                       iTrait;
    local int                       iCategoryIndex;

    /*
        Populate CurrentState (take a "snapshot") of the appearance then return it.
    */

    `log("UNDO BUFFER: In TakeAppearanceSnapshot().");

    for (iCategoryIndex = 0; iCategoryIndex <= eUICustomizeCat_MAX; iCategoryIndex++) {

        switch ( GetCategoryType(iCategoryIndex) ) {
            case eCategoryType_Prop:
            case eCategoryType_Color:
            case eCategoryType_Special:
            case eCategoryType_DLC_1:
                iTrait = class'RandomAppearanceButton'.static.GetTrait(Screen, EUICustomizeCategory(iCategoryIndex));

                if (iCategoryIndex == eUICustomizeCat_WeaponColor && iTrait == -1) {
                    /*
                        Upon soldier creation the weapon color is often (maybe always) -1 which
                        is reflected in the UI as the default color; this really messes with my
                        mod here, so when I take a snapshot and find the default color, I force
                        set it to the color in the color picker.

                        I may want to make this configurable.
                    */

                    iTrait = 3;
                }

                /*
                    Useful enough in debugging that I'm loathe to delete it until things have been stable longer.

                eCatIndex = EUICustomizeCategory(iCategoryIndex);
                if (iCategoryIndex >= eUICustomizeCat_LeftArm && iCategoryIndex <= eUICustomizeCat_RightArmDeco ||
                    iCategoryIndex == eUICustomizeCat_Arms ||
                    iCategoryIndex == eUICustomizeCat_Torso)
                    `log("   >" @ iTrait @ class'RandomAppearanceButton_Utilities'.static.CategoryName(eCatIndex) );
                */
                CurrentState.Trait[iCategoryIndex] = iTrait;
                break;

            default:
                break;
        }
    }

    /*
        Snapshot needs to account for whether there's DLC 1 components
        (otherwise stuff gets weird when undoing arms.)

        This will probably negate the need for the button presses
        to track this stuff.
    */
    if (class'RandomAppearanceButton_Utilities'.static.SoldierHasDLC1Torso(Screen) ||
        class'RandomAppearanceButton_Utilities'.static.SoldierHasDLC1Arms(Screen) ) {
        CurrentState.bHasDLC1components = true;
    } else {
        CurrentState.bHasDLC1components = false;
    }

    return CurrentState;
}


simulated static function bool CompareAppearanceStates(const out AppearanceState left, const out AppearanceState right)
{
    local int                   iCategoryIndex;
    local EUICustomizeCategory  eCatIndex;

    /*
        Iterate over all traits, compare the ones we care about; if any of them are changed,
        return false; otherwise return true.

        NOTE: UE3 doesn't support operator overloading as far as I can tell.
    */

    `log("UNDO BUFFER: in CompareAppearanceStates");

    for (iCategoryIndex = 0; iCategoryIndex <= eUICustomizeCat_MAX; iCategoryIndex++){
        switch( GetCategoryType(iCategoryIndex) ) {
            case eCategoryType_Prop:
            case eCategoryType_Color:
            case eCategoryType_Special:
            case eCategoryType_DLC_1:
                eCatIndex = EUICustomizeCategory(iCategoryIndex);
                if (left.Trait[iCategoryIndex] != right.Trait[iCategoryIndex]) {
                    `log("UNDO BUFFER: Compare" @ eCatIndex @ "NO MATCH. left=" @ left.Trait[iCategoryIndex] @ ", right=" @ right.Trait[iCategoryIndex]);
                    return false;
                } /*else {
                    `log("UNDO BUFFER: Compare" @ eCatIndex @ "match. left=" @ left.Trait[iCategoryIndex] @ ", right=" @ right.Trait[iCategoryIndex]);
                }*/
                break;

            case eCategoryType_IGNORE:
            case eCategoryType_UNKNOWN:
            default:
                //`log("UNDO BUFFER: Compare" @ string(iCategoryIndex) @ "ignored/unknown");
                break;
        }
    }

    if (left.bHasDLC1components != right.bHasDLC1components) {
        return false;
    }

    `log("UNDO BUFFER: COMPARE: FULL MATCH.");
    return true;
}

simulated static function ApplyAppearanceSnapshot(const out UICustomize_Menu Screen, const out AppearanceState AppearanceSnapshot/*, const out SoldierPropsLock PropCheckboxes*/)
{
    local int       iCategoryIndex;
    local int       eCatType;
    local int       iTrait;
    local bool      bSkipThisTrait;

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

    class'RandomAppearanceButton'.static.ForceSetTrait(Screen, EUICustomizeCategory(eUICustomizeCat_Gender), AppearanceSnapshot.Trait[eUICustomizeCat_Gender] - 1);
    Screen.UpdateData();

    /*
        Race comes next and before everything else, otherwise the face won't
        be correctly set. (It's not lost, just set to 0 and is detected as
        a "manual change".)
    */

    class'RandomAppearanceButton'.static.ForceSetTrait(Screen, EUICustomizeCategory(eUICustomizeCat_Race), AppearanceSnapshot.Trait[eUICustomizeCat_Race]);

    for (iCategoryIndex = 0; iCategoryIndex <= eUICustomizeCat_MAX; iCategoryIndex++) {

        eCatType = GetCategoryType(iCategoryIndex);
        iTrait = AppearanceSnapshot.Trait[iCategoryIndex];

        switch (eCatType)
        {
            /*
                Anarchy's Chilren's new arm slots will override in-place arms
                if they're set...so we only set them if the arms are not set.
                Likewise, we don't want them to mess with vanilla arms if they're
                NOT involved, thus:
            */
            case eCategoryType_Prop:

                bSkipThisTrait = false;

                if (iCategoryIndex == eUICustomizeCat_Arms && AppearanceSnapshot.bHasDLC1components)
                    bSkipThisTrait = true; // special handling

                if (iCategoryIndex == eUICustomizeCat_Race)
                    bSkipThisTrait = true; // set above

                break;

            case eCategoryType_DLC_1:
                if (AppearanceSnapshot.bHasDLC1components)
                    bSkipThisTrait = false;
                else
                    bSkipThisTrait = true;
                break;

            /*
                Colors require a "Direction" of -1.
            */
            case eCategoryType_Color:
                bSkipThisTrait = false;
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
            case eCategoryType_Special:
                bSkipThisTrait = true;
                break;

        }

        if (!bSkipThisTrait) {
            class'RandomAppearanceButton'.static.ForceSetTrait(Screen, EUICustomizeCategory(iCategoryIndex), iTrait);
        }

    }

    class'RandomAppearanceButton_Utilities'.static.UpdateScreenData(Screen);
    class'RandomAppearanceButton_Utilities'.static.ResetCamera(Screen);

}

simulated function bool Undo()
{
    //local AppearanceState     CurrentAppearance;
    local AppearanceState       BufferFront;

    `log("");
    `log("* * * * * * * * * * * * * * * * * * * * *");
    `log("");
    `log("UNDO BUFFER: In Undo.");
    `log("             Buffer size now" @ Buffer.Length);
    `log("");
    `log("* * * * * * * * * * * * * * * * * * * * *");
    `log("");

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

        EDGE CASE: buffer size 1

        If buffer size is 1 and there are Changes, normal flow is fine.

        If buffer size is 1 and there are No Changes, normal flow will
        break stuff (as it will try to rollback to a nonexistant state)
        so bail.

        EDGE CASE: buffer size 0

        We should never get here; the current state with no changes should
        always be in the buffer, implying min size of 1.
    */

    if ( !CanUndo() ) {
        `log("UNDO BUFFER: Can't Undo.");
        return false;
    }

    // local references to conform to further const out params in calls.
    `log("UNDO BUFFER: Taking snapshot in Undo().");
    `log("UNDO BUFFER: Getting front of buffer.");
    BufferFront = GetFrontOfBuffer();

    `log("UNDO BUFFER: Going to try and Undo now.");
    if ( NoChanges() ) {
        // No state changes: dump *then* apply.
        `log("No manual changes detected.");
        PopFrontOffTheBuffer(); // This state is already applied and we want to UNDO it.
        BufferFront = GetFrontOfBuffer();
        ApplyAppearanceSnapshot(CustomizeMenuScreen, BufferFront);
    } else {
        `log("Manual changes detected.");
        // Nothing to pop as the thing we want to replace isn't in the buffer.
        ApplyAppearanceSnapshot(CustomizeMenuScreen, BufferFront);
    }

    `log("UNDO BUFFER: Buffer size now" @ Buffer.Length);

    return true;
}

private static function int GetCategoryType(const out int iCategoryIndex)
{
    // Just a wrapper for a very long static function name.

    return class'RandomAppearanceButton_Utilities'.static.GetCategoryType(iCategoryIndex);
}

defaultproperties
{
    // Currently nothing here.
}