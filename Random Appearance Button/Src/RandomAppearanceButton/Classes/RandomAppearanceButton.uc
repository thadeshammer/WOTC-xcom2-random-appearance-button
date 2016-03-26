/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	Random Appearance Button CORE CLASS

	This has a menu that overlays the right side of this menu:
		UICustomization_Menu (basic soldier attributes like face and hairstyle)

	Since this makes for a cumbersome number of checkboxes that should all be visible
	while being used AND for some reason I can't change the fontsize of the checkboxes,
	I made a button that toggles visiblity of these boxes.

	For convenience (and because it made sense) I also added a Switch Gender button to
	the UI.

	TODO.

	Add an UNDO button with some amount of buffered choices. (Maybe five?)

	The UNDO button should appear disabled when it is disabled.

	Add a lot more configuration to the INI (e.g. allow all options to be assigned
	their own % chance for both buttons, maybe even allow the buttons to be renamed
	by the user which I'll need to at least cap at a certain length).

	(DONE) Figure out how to access and set the new Anarchy's Children DLC deco slots.
		(WONTFIX) There's a ValidatePartSelection() function which is intended to check against
		a given torso...but I'm doing this via the UI instead of the part selector stuff
		soooo...I may have to manually check or see things get super broken (or super
		awesome). Probably super broken.
		(FIXED) I need to figure out how to arrange the UI so it's not horrific with FOUR
		new checkboxes. :\ Maybe ONE label (e.g. "Left Arm/Deco") then followed by
		two checkboxes (one without a label). If that works, I could use that method
		to consolidate others maybe? Colors for instance.

	(DONE) Figure out how to actually load NewSoldier_ constraints from the config.
		* Now trying to load custom RABConf_ constraints from custom config.
		* Works; must be that we can't read from core INIs? Or maybe I needed
		(and didn't try) to include the INI in this project, or at least make
		an INI to extend it. I can play with this later, but for this project
		I now prefer the dedicated INI.

	(DONE) Make Hide/Show button

	BUGS.

	UNDO VS NORMAL UI MODIFICATIONS

	Changed the label from "Undo" to "Recall" so it's not quite so weird that the button
	doesn't track or affect normal user changers via the UI. What I **could** do is check
	the current state vs the last stored state each time and if it's different just
	rollback to the state and NOT pop it. That could work.

	UNDO VS GENDER

	Undo doesn't toggle Gender (maybe it should) and I leveraged this to maintain
	appearance across gender switches which can NEVER work consistently *because*
	there isn't a one-to-one mapping of props between the genders (e.g. females
	have more hairstyles than men, and the ones that match don't have matching
	indicies). 
	
	Ways to fix this (favorite to least favorite):
	* Toggle Gender adds a state to the buffer...this *might* work but could overfill
	the buffer pretty quickly; might be a good reason to increase the buffer size.
	* separate undo buffers for male/female;
	* Toggle Gender button wipes the buffer (undesirable);
	* do my best to map parts by name to their matches inspite of differing indicies
	(ton of work, big pain, probably won't look like it works ever);
	* just leave it as is (lazy, it seems broken this way).

	When a color picker is activated (e.g. Eye Color, Hair color) vs. a prop picker
	(e.g. Hairstyle, Face) the RandomAppearanceButton UI is not hidden as it should be;
	does this mean we don't get Receive and Lose Focus events for color pickers?
		* Correct: the class receives TWO Lose Focus events when a prop picker comes
		up and ZERO Lose Focus events when a Color picker comes up.
		* At first glance it looks like any "fix" for this would be a roundabout hack;
		for instance, I could write a listener that specifically watches for the color
		picker and if it comes up, it could break encapsulation and force THIS class
		to show/hide the UI as needed.

	(FIXED) Tattoo color no longer randomized. Did they change how that's done? - YES
	looks like they did; it takes Direction -1 instead of 0, so it's now in line with the
	other colors and no longer the Weird One.

	(FIXED) Locking the new arm slots needs to also auto-lock the primary arm slot; otherwise
	a primary arm being selected upon the random roll will override/ignore the arm slot
	being checked.

	(FIXED) 2016.03.17 New Anarchy's Children DLC makes for very weird "reasonable
	looking soldiers".
		* Added config limits to prevent use of these during generation.

	(FIXED) Gender switch from male to female prevents further grab'n'spin of the soldier pawn.

	(FIXED) Gender switch from female to male doesn't work.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

class RandomAppearanceButton extends UIScreenListener
	dependson(RandomAppearanceButton_UndoBuffer)
	config(RandomAppearanceButton);

/*
	Based on XGCharacterGenerator's standard procedure for making a new (normal-looking) soldier.
	Declarations ripped right from there (including the comment)
*/
var config float	RABConf_HatChance;
var config float	RABConf_UpperFacePropChance;
var config float	RABConf_LowerFacePropChance;
var config float	RABConf_BeardChance;
var config float	RABConf_ArmorPatternChance;
var config float	RABConf_WeaponPatternChance;
var config float	RABConf_TattoosChance;
var config float	RABConf_ScarsChance;
var config float	RABConf_FacePaintChance;

var config bool		RABConf_ForceDefaultColors;
var config int		RABConf_DefaultArmorColors;
var config int		RABConf_DefaultWeaponColors;
var config int		RABConf_DefaultHairColors;
var config int		RABConf_DefaultEyeColors;

// Added for Anarchy's children and similar DLC
var config int		RABConf_HairRangeMaleLimit;
var config int		RABConf_HairRangeFemaleLimit;
var config int		RABConf_HelmRangeLimit;
var config int		RABConf_ArmsRangeLimit;
var config int		RABConf_LegsRangeLimit;
var config int		RABConf_TorsoRangeLimit;
var config int		RABConf_UpperFacePropLimit;
var config int		RABConf_LowerFacePropLimit;
var config float	RABConf_TotallyRandom_AnarchysChildrenArmsChance;

enum EForceDefaultColorFlags {
	NotForced,
	ArmorColors,
	WeaponColors,
	HairColors,
	EyeColors
};

struct SoldierPropsLock {
	var UICheckBox		Face;
	var UICheckBox		Hair;
	var UICheckBox		FacialHair;
	var UICheckBox		HairColor;
	var UICheckBox		EyeColor;
	var UICheckBox		Race;
	var UICheckBox		SkinColor;
	var UICheckBox		MainColor;
	var UICheckBox		SecondaryColor;
	var UICheckBox		WeaponColor;

	var UICheckBox		UpperFace;
	var UICheckBox		LowerFace;
	var UICheckBox		Helmet;
	var UICheckBox		Arms;
	var UICheckBox		Torso;
	var UICheckBox		Legs;
	var UICheckBox		ArmorPattern;
	var UICheckBox		WeaponPattern;
	var UICheckBox		TattoosLeft;
	var UICheckBox		TattoosRight;
	var UICheckBox		TattoosColor;
	var UICheckBox		Scars;
	var UICheckBox		FacePaint;
	var UICheckBox		LeftArmUpper;
	var UICheckBox		LeftArmLower;
	var UICheckBox		RightArmUpper;
	var UICheckBox		RightArmLower;
};

var SoldierPropsLock	SoldierPropsLocks;

const DLC_1_STR = "DLC_1";
var bool				isDLC_1_Installed;

var UICustomize_Menu	CustomizeMenuScreen;

var UIPanel				BGBox;
var UIButton			RandomAppearanceButton;
var UIButton			TotallyRandomButton;
var UIButton			ToggleOptionsVisibilityButton;
var bool				bToggleOptionsButtonVisible;
var UIButton			UndoButton;
var UIButton			ToggleGenderButton;
var UIButton			CheckAllButton;
var UIButton			UncheckAllButton;

var UIText				AttribLocksTitle;
var UIText				WearablesLocksTitle;
var UIText				WearablesColorsLocksTitles;

var RandomAppearanceButton_UndoBuffer	UndoBuffer;

/*
	Starting with the coords from the random nickname button mod.
*/
const BUTTON_OFFSET_X			= -193;
const BUTTON_OFFSET_Y			= 150;

const BUTTON_LABEL_FONTSIZE		= 24;	// smaller text
const BUTTON_HEIGHT				= 30;	// guesstimate, also smaller
const BUTTON_SPACING			= 3;

// Can't get fontsize to impact checkboxes.
const CHECKBOX_OFFSET_X			= -57;
const CHECKBOX_OFFSET_Y			= 100; //130; //180;
const CHECKBOX_NEIGHBOR_OFFSET	= 40;

const TITLE_OFFSET_X			= -290;

// I needed a local decl of this in rand.nickname in order to make
// a generalized create button func, so...here it is again.
delegate OnClickedDelegate(UIButton Button);

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

							UIScreenListener Callbacks

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

event OnInit(UIScreen Screen)
{	
	CustomizeMenuScreen = UICustomize_Menu(Screen);
	if (CustomizeMenuScreen == none)
		return;

	RunDLCCheck();

	CreateTheChecklist();

	bToggleOptionsButtonVisible = false;

	//Screen.Spawn(class'UIPanel', Screen);
	//UndoBuffer = CustomizeMenuScreen.Spawn(class'RandomAppearance_UndoBuffer', CustomizeMenuScreen);
	//UndoBuffer.Init(CustomizeMenuScreen);

	UndoBuffer = New class'RandomAppearanceButton_UndoBuffer';
	UndoBuffer.Init(CustomizeMenuScreen);
}

simulated function OnReceiveFocus(UIScreen Screen)
{
	`log("RandomAppearanceButton.OnReceiveFocus");

	ShowUI();
}

simulated function OnLoseFocus(UIScreen Screen)
{
	`log("RandomAppearanceButton.OnLoseFocus");

	HideUI();
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
	Spawn a new button/checkbox on the given screen with the given params.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
simulated function CreateTheChecklist(/*UIScreen Screen*/)
{
	local int					AnchorPos;
	local int					DLCCheckboxYAdjust;
	
	ToggleOptionsVisibilityButton		= CreateButton(CustomizeMenuScreen, 'RandomAppearanceToggle',	"Toggle Options",		ToggleChecklistVisiblity,				class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -154, -165);

	UndoButton							= CreateButton(CustomizeMenuScreen, 'UndoButton',				"Undo",					UndoAppearanceChanges,					class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -307, -165);
	UndoButtonGreyedOut(); // The buffer starts empty.

	RandomAppearanceButton				= CreateButton(CustomizeMenuScreen, 'RandomAppearanceButton',	"Random Appearance",	GenerateNormalLookingRandomAppearance,	class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -207, -130);
	TotallyRandomButton					= CreateButton(CustomizeMenuScreen, 'TotallyRandomButton',		"Totally Random", 		GenerateTotallyRandomAppearance,		class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -160, -95);

	SpawnOptionsBG(CustomizeMenuScreen);

	AnchorPos = class'UIUtilities'.const.ANCHOR_TOP_RIGHT;

	ToggleGenderButton					= CreateButton(CustomizeMenuScreen, 'ToggleGender',				"Switch Gender",		ToggleGender,	AnchorPos, -234, CHECKBOX_OFFSET_Y - BUTTON_HEIGHT - BUTTON_SPACING); // xoffset prev -154
	ToggleGenderButton.SetDisabled(false, "Changing gender will clear the undo buffer.");
	ToggleGenderButton.Hide();

	CheckAllButton						= CreateButton(CustomizeMenuScreen, 'CheckAll',					"All",					CheckAll,		class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -154, -207);
	CheckAllButton.Hide();

	UncheckAllButton					= CreateButton(CustomizeMenuScreen, 'UncheckAll',				"Clear",				UncheckAll,		class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -305, -207);
	UncheckAllButton.Hide();

	AttribLocksTitle					= CreateTextBox(CustomizeMenuScreen,	'AttribLocksHeader',	"Lock Body Attributes",	AnchorPos, TITLE_OFFSET_X + 40, CHECKBOX_OFFSET_Y);

	SoldierPropsLocks.Race				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Race',		"Race/Skin Color",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(AttribLocksTitle));
	SoldierPropsLocks.SkinColor		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_SkinColor',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.Race.Y);

	SoldierPropsLocks.Face				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Face',		"Face/Beard",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.Race));
	SoldierPropsLocks.FacialHair		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_FacialHair',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.Face.Y);

	SoldierPropsLocks.FacePaint			= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_FacePaint',	"Paint/Scars",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.Face));
	SoldierPropsLocks.Scars				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Scars',		"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.FacePaint.Y);

	SoldierPropsLocks.Hair				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Hair',		"Hair/Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.FacePaint));
	SoldierPropsLocks.HairColor		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_HairColor',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.Hair.Y);

	SoldierPropsLocks.EyeColor			= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_EyeColor',	"Eye Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.Hair));

	SoldierPropsLocks.TattoosLeft		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_LeftTattoo',	"Tattoos: L/R",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.EyeColor));
	SoldierPropsLocks.TattoosRight		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_RightTattoo',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.TattoosLeft.Y);
	SoldierPropsLocks.TattoosColor		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_TattooColor',	"Tattoo Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.TattoosLeft));
	
	/*
		Wearables
	*/
	WearablesLocksTitle					= CreateTextBox(CustomizeMenuScreen,	'WearablesLocksHeader', "Lock Wearables",		AnchorPos, TITLE_OFFSET_X + 60, PanelYShiftDownFrom(SoldierPropsLocks.TattoosColor));

	SoldierPropsLocks.Helmet			= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Helmet',		"Helm",					AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(WearablesLocksTitle));

	SoldierPropsLocks.UpperFace			= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_UpperFace',	"Face: Upper/Lower",	AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.Helmet));
	SoldierPropsLocks.LowerFace			= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_LowerFace',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.UpperFace.Y);

	SoldierPropsLocks.Arms				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Arms',			"Arms Primary",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.UpperFace));
	
	if (isDLC_1_Installed) {
		/*
			If DLC1 is installed, we need these checkboxes and to draw subsequent checkboxes relative to them.
		*/

		SoldierPropsLocks.LeftArmLower	= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_LeftArmLower',	"Left Arm/Deco",	AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.Arms));
		SoldierPropsLocks.LeftArmUpper	= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_LeftArmUpper',	"",					AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.LeftArmLower.Y);			
	
		SoldierPropsLocks.RightArmLower	= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_RightArmLower',	"Right Arm/Deco",	AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.LeftArmUpper));
		SoldierPropsLocks.RightArmUpper	= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_RightArmUpper',	"",					AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.RightArmLower.Y);

		DLCCheckboxYAdjust = SoldierPropsLocks.RightArmUpper.Y + SoldierPropsLocks.RightArmUpper.Height + BUTTON_SPACING;
	} else {
		/*
			Otherwise, make like it's not there.
		*/

		DLCCheckboxYAdjust = SoldierPropsLocks.Arms.Y + SoldierPropsLocks.Arms.Height + BUTTON_SPACING;
	}
	
	SoldierPropsLocks.Torso				= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_Torso',			"Torso",				AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, DLCCheckboxYAdjust);
	SoldierPropsLocks.Legs				= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_Legs',			"Legs",					AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.Torso));

	/*
		Colors + Patterns
	*/
	WearablesColorsLocksTitles			= CreateTextBox(CustomizeMenuScreen,  'WearablesColorsHeader',	"Lock Patterns & Colors", AnchorPos, TITLE_OFFSET_X + 30, PanelYShiftDownFrom(SoldierPropsLocks.Legs));

	SoldierPropsLocks.ArmorPattern		= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_ArmorPattern',	"Armor Pattern",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(WearablesColorsLocksTitles));
	SoldierPropsLocks.MainColor		= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_MainColor',		"Armor Color 1/2",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.ArmorPattern));
	SoldierPropsLocks.SecondaryColor	= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_SecondaryColor',"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.MainColor.Y);

	SoldierPropsLocks.WeaponPattern		= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_WeaponPattern',	"Weapon Pattern",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.MainColor));	
	SoldierPropsLocks.WeaponColor		= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_WeaponColor',	"Weapon Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.WeaponPattern));

}

simulated function int PanelYShiftDownFrom(UIPanel Element)
{
	return Element.Y + Element.Height + BUTTON_SPACING;
}



simulated function SpawnOptionsBG(UIScreen Screen)
{

	BGBox = Screen.Spawn(class'UIPanel', Screen);
	BGBox.InitPanel('BGBox', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
	BGBox.AnchorTopRight();
	BGBox.SetSize(320, 850);
	BGBox.SetPosition(-310,CHECKBOX_OFFSET_Y - BUTTON_HEIGHT - BUTTON_SPACING - 10);	// remember, relative to the anchor
	BGBox.Hide();

}

simulated function ToggleChecklistVisiblity(UIButton Button)
{

	/*
		Note that the unused param is there because it needs to be in order
		to fit the mold for a button callback function.

		This method only hides/unhides the checklist on the
		button being pressed.
	*/

	BGBox.ToggleVisible();
	ToggleGenderButton.ToggleVisible();

	AttribLocksTitle.ToggleVisible();
	WearablesLocksTitle.ToggleVisible();
	WearablesColorsLocksTitles.ToggleVisible();

	SoldierPropsLocks.Face.ToggleVisible();
	SoldierPropsLocks.Hair.ToggleVisible();
	SoldierPropsLocks.FacialHair.ToggleVisible();
	SoldierPropsLocks.HairColor.ToggleVisible();
	SoldierPropsLocks.EyeColor.ToggleVisible();
	SoldierPropsLocks.Race.ToggleVisible();
	SoldierPropsLocks.SkinColor.ToggleVisible();
	SoldierPropsLocks.MainColor.ToggleVisible();
	SoldierPropsLocks.SecondaryColor.ToggleVisible();
	SoldierPropsLocks.WeaponColor.ToggleVisible();

	SoldierPropsLocks.UpperFace.ToggleVisible();
	SoldierPropsLocks.LowerFace.ToggleVisible();
	SoldierPropsLocks.Helmet.ToggleVisible();
	SoldierPropsLocks.Arms.ToggleVisible();
	SoldierPropsLocks.Torso.ToggleVisible();
	SoldierPropsLocks.Legs.ToggleVisible();
	SoldierPropsLocks.ArmorPattern.ToggleVisible();
	SoldierPropsLocks.WeaponPattern.ToggleVisible();
	SoldierPropsLocks.TattoosLeft.ToggleVisible();
	SoldierPropsLocks.TattoosRight.ToggleVisible();
	SoldierPropsLocks.TattoosColor.ToggleVisible();
	SoldierPropsLocks.Scars.ToggleVisible();
	SoldierPropsLocks.FacePaint.ToggleVisible();
	CheckAllButton.ToggleVisible();
	UncheckAllButton.ToggleVisible();

	SoldierPropsLocks.LeftArmUpper.ToggleVisible();
	SoldierPropsLocks.LeftArmLower.ToggleVisible();

	SoldierPropsLocks.RightArmUpper.ToggleVisible();
	SoldierPropsLocks.RightArmLower.ToggleVisible();

	if (bToggleOptionsButtonVisible) {
		bToggleOptionsButtonVisible = false;
	} else {
		bToggleOptionsButtonVisible = true;
	}

}

simulated function HideUI()
{

	/*
		Hides the mod's UI when losing focus.
	*/

	if (bToggleOptionsButtonVisible) {

		BGBox.Hide();
		ToggleGenderButton.Hide();

		AttribLocksTitle.Hide();
		WearablesLocksTitle.Hide();
		WearablesColorsLocksTitles.Hide();

		SoldierPropsLocks.Face.Hide();
		SoldierPropsLocks.Hair.Hide();
		SoldierPropsLocks.FacialHair.Hide();
		SoldierPropsLocks.HairColor.Hide();
		SoldierPropsLocks.EyeColor.Hide();
		SoldierPropsLocks.Race.Hide();
		SoldierPropsLocks.SkinColor.Hide();
		SoldierPropsLocks.MainColor.Hide();
		SoldierPropsLocks.SecondaryColor.Hide();
		SoldierPropsLocks.WeaponColor.Hide();

		SoldierPropsLocks.UpperFace.Hide();
		SoldierPropsLocks.LowerFace.Hide();
		SoldierPropsLocks.Helmet.Hide();
		SoldierPropsLocks.Arms.Hide();
		SoldierPropsLocks.Torso.Hide();
		SoldierPropsLocks.Legs.Hide();
		SoldierPropsLocks.ArmorPattern.Hide();
		SoldierPropsLocks.WeaponPattern.Hide();
		SoldierPropsLocks.TattoosLeft.Hide();
		SoldierPropsLocks.TattoosRight.Hide();
		SoldierPropsLocks.TattoosColor.Hide();
		SoldierPropsLocks.Scars.Hide();
		SoldierPropsLocks.FacePaint.Hide();
		CheckAllButton.Hide();
		UncheckAllButton.Hide();

		SoldierPropsLocks.LeftArmUpper.Hide();
		SoldierPropsLocks.LeftArmLower.Hide();

		SoldierPropsLocks.RightArmUpper.Hide();
		SoldierPropsLocks.RightArmLower.Hide();
	}

	ToggleOptionsVisibilityButton.Hide();
	RandomAppearanceButton.Hide();
	TotallyRandomButton.Hide();
	UndoButton.Hide();

}

simulated function ShowUI()
{

	/*
		Since this func is called only on a Receive Focus event,
		if the options panel was visible prior to calling this,
		it should be visible again. (I.E. if the user had the
		panel up, then clicked to edit eye color, then came back
		to the root, they should see the options panel still.)

		It's a bug right now but it doesn't work for colors. :(
	*/

	if (bToggleOptionsButtonVisible) {
		BGBox.Show();
		ToggleGenderButton.Show();

		AttribLocksTitle.Show();
		WearablesLocksTitle.Show();
		WearablesColorsLocksTitles.Show();

		SoldierPropsLocks.Face.Show();
		SoldierPropsLocks.Hair.Show();
		SoldierPropsLocks.FacialHair.Show();
		SoldierPropsLocks.HairColor.Show();
		SoldierPropsLocks.EyeColor.Show();
		SoldierPropsLocks.Race.Show();
		SoldierPropsLocks.SkinColor.Show();
		SoldierPropsLocks.MainColor.Show();
		SoldierPropsLocks.SecondaryColor.Show();
		SoldierPropsLocks.WeaponColor.Show();

		SoldierPropsLocks.UpperFace.Show();
		SoldierPropsLocks.LowerFace.Show();
		SoldierPropsLocks.Helmet.Show();
		SoldierPropsLocks.Arms.Show();
		SoldierPropsLocks.Torso.Show();
		SoldierPropsLocks.Legs.Show();
		SoldierPropsLocks.ArmorPattern.Show();
		SoldierPropsLocks.WeaponPattern.Show();
		SoldierPropsLocks.TattoosLeft.Show();
		SoldierPropsLocks.TattoosRight.Show();
		SoldierPropsLocks.TattoosColor.Show();
		SoldierPropsLocks.Scars.Show();
		SoldierPropsLocks.FacePaint.Show();
		CheckAllButton.Show();
		UncheckAllButton.Show();

		SoldierPropsLocks.LeftArmUpper.Show();
		SoldierPropsLocks.LeftArmLower.Show();

		SoldierPropsLocks.RightArmUpper.Show();
		SoldierPropsLocks.RightArmLower.Show();
	}

	ToggleOptionsVisibilityButton.Show();
	RandomAppearanceButton.Show();
	TotallyRandomButton.Show();
	UndoButton.Show();

}

simulated function ToggleGender(UIButton Button)
{
	local int					newGender;
	local XComGameState_Unit	Unit;
	//local AppearanceState		AppearanceSnapshot;

	Unit = CustomizeMenuScreen.Movie.Pres.GetCustomizationUnit();

	/*
		OnCategoryValueChange is set up to receive data from a UIList; in the
		case of the index, it's using 0 (for male) and 1 (for female) as that's
		their order in the visual representation...whereas the enum there's
		a "none" options, so it's 1 for male and 2 for female.

		I subtract 1 from the enum in each case so I can continue changing stuff
		via the UI hooks.
	*/	
	if (Unit.kAppearance.iGender == eGender_Female) {
		newGender = eGender_Male - 1;
	} else if (Unit.kAppearance.iGender == eGender_Male) {
		newGender = eGender_Female - 1;
	}

	/*
		Count this as a state change so UNDO can handle it.

		NOTE The undo buffer gets all sorts of confused when it tries to track gender,
		so for now it will just wipe the buffer clean to hit this button.
	*/

	StoreAppearanceStateInUndoBuffer();

	ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_Gender, newGender);	
	//CustomizeMenuScreen.UpdateData(); // If I don't do this, things can get weird.
	UpdateScreenData();

	//UndoBuffer.ClearTheBuffer();
	//UndoButtonGreyedOut();
}

simulated function StoreAppearanceStateInUndoBuffer()
{
	UndoBuffer.StoreCurrentState();
	UndoButtonLitUp();
}

simulated function UndoButtonGreyedOut()
{
	local string strLabel;

	//strLabel = "Recall: 0";
	strLabel = "Undo";

	UndoButton.SetText(class'UIUtilities_Text'.static.GetColoredText(strLabel, eUIState_Disabled, BUTTON_LABEL_FONTSIZE));
}

simulated function UndoButtonLitUp()
{
	local string strLabel;

	//strLabel = "Recall:" @ string(UndoBuffer.Buffer.Length);
	strLabel = "Undo";

	UndoButton.SetText(class'UIUtilities_Text'.static.GetColoredText(strLabel, eUIState_Normal, BUTTON_LABEL_FONTSIZE));
}

simulated function CheckAll(UIButton Button)
{
	
	SoldierPropsLocks.Face.SetChecked(true);
	SoldierPropsLocks.Hair.SetChecked(true);
	SoldierPropsLocks.FacialHair.SetChecked(true);
	SoldierPropsLocks.HairColor.SetChecked(true);
	SoldierPropsLocks.EyeColor.SetChecked(true);
	SoldierPropsLocks.Race.SetChecked(true);
	SoldierPropsLocks.SkinColor.SetChecked(true);
	SoldierPropsLocks.MainColor.SetChecked(true);
	SoldierPropsLocks.SecondaryColor.SetChecked(true);
	SoldierPropsLocks.WeaponColor.SetChecked(true);

	SoldierPropsLocks.UpperFace.SetChecked(true);
	SoldierPropsLocks.LowerFace.SetChecked(true);
	SoldierPropsLocks.Helmet.SetChecked(true);
	SoldierPropsLocks.Arms.SetChecked(true);
	SoldierPropsLocks.Torso.SetChecked(true);
	SoldierPropsLocks.Legs.SetChecked(true);
	SoldierPropsLocks.ArmorPattern.SetChecked(true);
	SoldierPropsLocks.WeaponPattern.SetChecked(true);
	SoldierPropsLocks.TattoosLeft.SetChecked(true);
	SoldierPropsLocks.TattoosRight.SetChecked(true);
	SoldierPropsLocks.TattoosColor.SetChecked(true);
	SoldierPropsLocks.Scars.SetChecked(true);
	SoldierPropsLocks.FacePaint.SetChecked(true);

	SoldierPropsLocks.LeftArmUpper.SetChecked(true);
	SoldierPropsLocks.LeftArmLower.SetChecked(true);
	SoldierPropsLocks.RightArmUpper.SetChecked(true);
	SoldierPropsLocks.RightArmLower.SetChecked(true);

}

simulated function UncheckAll(UIButton Button)
{

	SoldierPropsLocks.Face.SetChecked(false);
	SoldierPropsLocks.Hair.SetChecked(false);
	SoldierPropsLocks.FacialHair.SetChecked(false);
	SoldierPropsLocks.HairColor.SetChecked(false);
	SoldierPropsLocks.EyeColor.SetChecked(false);
	SoldierPropsLocks.Race.SetChecked(false);
	SoldierPropsLocks.SkinColor.SetChecked(false);
	SoldierPropsLocks.MainColor.SetChecked(false);
	SoldierPropsLocks.SecondaryColor.SetChecked(false);
	SoldierPropsLocks.WeaponColor.SetChecked(false);

	SoldierPropsLocks.UpperFace.SetChecked(false);
	SoldierPropsLocks.LowerFace.SetChecked(false);
	SoldierPropsLocks.Helmet.SetChecked(false);
	SoldierPropsLocks.Arms.SetChecked(false);
	SoldierPropsLocks.Torso.SetChecked(false);
	SoldierPropsLocks.Legs.SetChecked(false);
	SoldierPropsLocks.ArmorPattern.SetChecked(false);
	SoldierPropsLocks.WeaponPattern.SetChecked(false);
	SoldierPropsLocks.TattoosLeft.SetChecked(false);
	SoldierPropsLocks.TattoosRight.SetChecked(false);
	SoldierPropsLocks.TattoosColor.SetChecked(false);
	SoldierPropsLocks.Scars.SetChecked(false);
	SoldierPropsLocks.FacePaint.SetChecked(false);

	SoldierPropsLocks.LeftArmUpper.SetChecked(false);
	SoldierPropsLocks.LeftArmLower.SetChecked(false);
	SoldierPropsLocks.RightArmUpper.SetChecked(false);
	SoldierPropsLocks.RightArmLower.SetChecked(false);

}

simulated function UIButton CreateButton(UIScreen Screen, 
											name ButtonName, string ButtonLabel,
											delegate<OnClickedDelegate> OnClickCallThis, 
											int AnchorPos, int XOffset, int YOffset)
{
	local UIButton  NewButton;
	
	NewButton = Screen.Spawn(class'UIButton', Screen);
	NewButton.InitButton(ButtonName, class'UIUtilities_Text'.static.GetSizedText(ButtonLabel, BUTTON_LABEL_FONTSIZE), OnClickCallThis);
	NewButton.SetAnchor(AnchorPos);
	NewButton.SetPosition(XOffset, YOffset);
	NewButton.SetSize(NewButton.Width, BUTTON_HEIGHT);
	
	return NewButton;
}

simulated function UICheckbox CreateCheckbox(UIScreen Screen, 
											name CheckboxName, string CheckboxLabel, 
											int AnchorPos, int XOffset, int YOffset)
{
	local UICheckbox  NewCheckbox;
	
	NewCheckbox = Screen.Spawn(class'UICheckbox', Screen);
	NewCheckbox.InitCheckbox(CheckboxName, CheckboxLabel);
	NewCheckbox.SetAnchor(AnchorPos);
	NewCheckbox.SetPosition(XOffset, YOffset);
	NewCheckbox.SetSize(NewCheckbox.Width, BUTTON_HEIGHT);
	NewCheckbox.Hide();
	
	return NewCheckbox;
}

simulated function UIText CreateTextBox(UIScreen Screen, name TextBoxName, string strText, int AnchorPos, float XOffset, float YOffset)
{
	local UIText TextBox;

	TextBox = Screen.Spawn(class'UIText', Screen);
	TextBox.InitText(TextBoxName, class'UIUtilities_Text'.static.GetColoredText(strText, eUIState_Normal, 25));
	TextBox.SetAnchor(AnchorPos);
	TextBox.SetPosition(XOffset, YOffset);
	TextBox.Hide();

	return TextBox;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	Random Appearance code

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

simulated function GenerateTotallyRandomAppearance(UIButton Button)
{

	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");
	`log("GENERATING TOTALLY RANDOM APPEARANCE");
	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");
	
	`log("TOTALRAND: Storing current appearance in undo buffer (if it's not there already).");
	StoreAppearanceStateInUndoBuffer();

	// Core customization menu
	RandomizeTrait(SoldierPropsLocks.Face.bChecked,			eUICustomizeCat_Face,						true);
	RandomizeTrait(SoldierPropsLocks.Hair.bChecked,			eUICustomizeCat_Hairstyle,					true);
	RandomizeTrait(SoldierPropsLocks.FacialHair.bChecked,		eUICustomizeCat_FacialHair,				true);
	RandomizeTrait(SoldierPropsLocks.HairColor.bChecked,		eUICustomizeCat_HairColor,				true);
	RandomizeTrait(SoldierPropsLocks.EyeColor.bChecked,		eUICustomizeCat_EyeColor,					true);
	RandomizeTrait(SoldierPropsLocks.Race.bChecked,			eUICustomizeCat_Race,						true);
	RandomizeTrait(SoldierPropsLocks.SkinColor.bChecked,		eUICustomizeCat_Skin,					true);
	RandomizeTrait(SoldierPropsLocks.MainColor.bChecked,		eUICustomizeCat_PrimaryArmorColor,		true);
	RandomizeTrait(SoldierPropsLocks.SecondaryColor.bChecked,	eUICustomizeCat_SecondaryArmorColor,	true);
	RandomizeTrait(SoldierPropsLocks.WeaponColor.bChecked,		eUICustomizeCat_WeaponColor,			true);

	// customize props menu
	RandomizeTrait(SoldierPropsLocks.UpperFace.bChecked,		eUICustomizeCat_FaceDecorationUpper,	true);
	RandomizeTrait(SoldierPropsLocks.LowerFace.bChecked,		eUICustomizeCat_FaceDecorationLower,	true);
	RandomizeTrait(SoldierPropsLocks.Helmet.bChecked,			eUICustomizeCat_Helmet,					true);	
	RandomizeTrait(SoldierPropsLocks.Torso.bChecked,			eUICustomizeCat_Torso,					true);
	RandomizeTrait(SoldierPropsLocks.Legs.bChecked,				eUICustomizeCat_Legs,					true);
	RandomizeTrait(SoldierPropsLocks.ArmorPattern.bChecked,		eUICustomizeCat_ArmorPatterns,			true);
	RandomizeTrait(SoldierPropsLocks.WeaponPattern.bChecked,	eUICustomizeCat_WeaponPatterns,			true);
	RandomizeTrait(SoldierPropsLocks.TattoosLeft.bChecked,		eUICustomizeCat_LeftArmTattoos,			true);
	RandomizeTrait(SoldierPropsLocks.TattoosRight.bChecked,		eUICustomizeCat_RightArmTattoos,		true);
	RandomizeTrait(SoldierPropsLocks.TattoosColor.bChecked,		eUICustomizeCat_TattooColor,			true);
	RandomizeTrait(SoldierPropsLocks.Scars.bChecked,			eUICustomizeCat_Scars,					true);
	RandomizeTrait(SoldierPropsLocks.FacePaint.bChecked,		eUICustomizeCat_FacePaint,				true);

	`log("DOING ARMS.");
	`log("Checking for DLC1.");
	// deal with anarchy's children dlc
	if (isDLC_1_Installed)
	{
		`log("DLC1 installed.");
		HandleDLC1();

	} else {
		// If there's no DLC, we roll.

		`log("No DLC, rolling arms as normal.");
		RandomizeTrait(SoldierPropsLocks.Arms.bChecked,				eUICustomizeCat_Arms,				true);
	}
	`log("DONE WITH ARMS.");

	`log("TOTALRAND: Storing current appearance in undo buffer.");
	StoreAppearanceStateInUndoBuffer();
}

simulated function HandleDLC1()
{
	/*
		If the primary arms are locked then we don't do this at all.
			
		If primary arms are NOT locked AND one or more of the arm slots are locked, then
		we roll for random arm elements every time.

		If no arm aspects are locked then we constrain how often we roll based on config, otherwise
		we virtually never see vanilla arms. We don't constrain in the previous case because
		that only slows down what's going to happen anyway (there's no chance of vanilla
		arms).

		Note that we need to check for the arms lock first as a subsequent setting of arms will
		override the arm component (and vice versa). If locks aren't a concern, the override is okay
		BUT there's another problem.

		There are 6 core arms options from vanilla and 5! (that's factorial, i.e. 120) possible arm
		combos from combinations of AC DLC arm slot picks. (Or 5^4? Pretty sure it's
		5! but my mid-coffee combinatorics isn't so good apparently.) (Order matters so it's factorial,
		Thade. You feeling okay?) (yea, thanks thade.) Still, 120 is a LOT more than 6, so instead of
		treating ALL the AC DLC arms as equally, let's treat it as ONE arm and let it be configurable.

		In short: if anything is locked, then we don't want to bother with the % chance of arm
		component, because there's never a case where they'll be locked and we don't want to roll
		one. If NONE of them are locked, then we constrain based on chance.	
	*/

	// if	(SoldierPropsLocks.Arms.bChecked) then DON'T DO SHIT
	//		Rolling on Arms is harmless (it respects this lock) but the way I've got these locks
	//		implemented, the DLC arm slots won't respect this lock...so we enforce it out here.
	// else	we have two cases that fall under !SoldierPropsLocks.Arms.bChecked:
	//		if ANY of these are bChecked: LeftArmLower, RightArmLower, LeftArmUpper, RightArmUpper
	//			THEN roll NO MATTER WHAT
	//		else if NONE of them are locked (and, given where we are, the Arms themselves aren't locked)
	//			THEN we constrain on % chance

	if (!SoldierPropsLocks.Arms.bChecked) {

		if (SoldierPropsLocks.LeftArmUpper.bChecked || SoldierPropsLocks.RightArmUpper.bChecked ||
			SoldierPropsLocks.LeftArmLower.bChecked || SoldierPropsLocks.RightArmLower.bChecked) {

			/*
				If any one of these are locked, then we can't roll for standard arms because they'll
				override whatever DLC arm prop is locked, so...we just don't. We instead roll for
				the new arm props.

				Since we're going to be getting DLC arms here, we set the arms to the "unset" or default position
				of -1.
			*/
			ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_Arms, -1);
			RandomizeDLC1ArmSlots();

		} else {
			/*
				Arms aren't locked, new arm props aren't locked, sooo roll for the arms then, to handle
				the concerns laid out in the above back-of-the napkin math, we only overwrite the new
				arms picked based on a (small) chance from the config.
			*/

			ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_LeftArm, 0);
			ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_RightArm, 0);
			ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_LeftArmDeco, 0);
			ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_RightArmDeco, 0);
			
			RandomizeTrait(SoldierPropsLocks.Arms.bChecked,				eUICustomizeCat_Arms,					true);
						

			
			if (RandomizeOrNotBasedOnRoll(RABConf_TotallyRandom_AnarchysChildrenArmsChance)) {

				/*
					We're only in here because primary Arms aren't locked and none of the DLC arm slots are locked,
					in which case we ONLY want to see DLC arm elements pop in (and override the much smaller number
					of vanilla arms) some of the time and not all of the time. (See above for shoddy napkin math.)

					The chance is set in the config file.

					Since we're going to be getting DLC arms here, we set the arms to the "unset" or default position
					of -1.
				*/
				ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_Arms, -1);
				RandomizeDLC1ArmSlots();
			}
		}
		
	} else {

	/*
		Otherwise, no worries, just roll on the arms the old fashioned way!
	*/

		RandomizeTrait(SoldierPropsLocks.Arms.bChecked,				eUICustomizeCat_Arms,					true);
	}
}

simulated function RandomizeDLC1ArmSlots()
{
	RandomizeTrait(SoldierPropsLocks.LeftArmUpper.bChecked,		eUICustomizeCat_LeftArmDeco,		true);
	RandomizeTrait(SoldierPropsLocks.RightArmUpper.bChecked,	eUICustomizeCat_RightArmDeco,		true);
	RandomizeTrait(SoldierPropsLocks.LeftArmLower.bChecked,		eUICustomizeCat_LeftArm,			true);
	RandomizeTrait(SoldierPropsLocks.RightArmLower.bChecked,	eUICustomizeCat_RightArm,			true);
}

simulated function GenerateNormalLookingRandomAppearance(UIButton Button)
{
	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");
	`log("GENERATING NORMAL LOOKING APPEARANCE");
	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");

	`log("TOTALRAND: Storing current appearance in undo buffer.");
	StoreAppearanceStateInUndoBuffer();

	/*
		Basically need to clear any/all extended stuff (e.g. props) so the result here doesn't look like it's fixed
		and weird.

		If you click the button and get a hat, that hat will persist through further clicks on the button...which
		feels weird; so I clear the hat (and other props) then regen the chance to get one again.
	*/

	// For Sure do these.
	RandomizeTrait(SoldierPropsLocks.Face.bChecked,				eUICustomizeCat_Face);
	RandomizeTrait(SoldierPropsLocks.Hair.bChecked,				eUICustomizeCat_Hairstyle);
		
	RandomizeTrait(SoldierPropsLocks.Race.bChecked,				eUICustomizeCat_Race);
	RandomizeTrait(SoldierPropsLocks.SkinColor.bChecked,		eUICustomizeCat_Skin);

	RandomizeTrait(SoldierPropsLocks.Arms.bChecked,				eUICustomizeCat_Arms);
	RandomizeTrait(SoldierPropsLocks.Torso.bChecked,			eUICustomizeCat_Torso);
	RandomizeTrait(SoldierPropsLocks.Legs.bChecked,				eUICustomizeCat_Legs);

	/*
		Conditionally randomize these (configurable in XComRandomAppearanceButton.ini).

		Optionals per the game's default soldier generator: facial hair and decorations, hat.
		Optionals per me: armor and weapon patterns, tattoos, scars, face paint.
	*/
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FacialHair,				SoldierPropsLocks.FacialHair.bChecked,		RABConf_BeardChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FaceDecorationUpper,	SoldierPropsLocks.UpperFace.bChecked,		RABConf_UpperFacePropChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FaceDecorationLower,	SoldierPropsLocks.LowerFace.bChecked,		RABConf_LowerFacePropChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_Helmet,					SoldierPropsLocks.Helmet.bChecked,			RABConf_HatChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_ArmorPatterns,			SoldierPropsLocks.ArmorPattern.bChecked,		RABConf_ArmorPatternChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_WeaponPatterns,			SoldierPropsLocks.WeaponPattern.bChecked,	RABConf_WeaponPatternChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_Scars,					SoldierPropsLocks.Scars.bChecked,			RABConf_ScarsChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FacePaint,				SoldierPropsLocks.FacePaint.bChecked,		RABConf_FacePaintChance);

	/*
		I handle the tattoos as one field; could handle them individually as I do everything else, but this made
		more sense to me.

		Set the color (if there are no tattoos, no worries, it won't show up).
	*/
	RandomizeTrait(SoldierPropsLocks.TattoosColor.bChecked,		eUICustomizeCat_TattooColor);

	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_LeftArmTattoos,			SoldierPropsLocks.TattoosLeft.bChecked,		RABConf_TattoosChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_RightArmTattoos,		SoldierPropsLocks.TattoosRight.bChecked,		RABConf_TattoosChance);
	
	/*
		Colors!
	*/
	if (RABConf_ForceDefaultColors)
	{
		RandomizeTrait(SoldierPropsLocks.HairColor.bChecked,		eUICustomizeCat_HairColor,				false, EForceDefaultColorFlags.HairColors);
		RandomizeTrait(SoldierPropsLocks.MainColor.bChecked,		eUICustomizeCat_PrimaryArmorColor,		false, EForceDefaultColorFlags.ArmorColors);
		RandomizeTrait(SoldierPropsLocks.SecondaryColor.bChecked,	eUICustomizeCat_SecondaryArmorColor,	false, EForceDefaultColorFlags.ArmorColors);
		RandomizeTrait(SoldierPropsLocks.WeaponColor.bChecked,		eUICustomizeCat_WeaponColor,			false, EForceDefaultColorFlags.WeaponColors);
		RandomizeTrait(SoldierPropsLocks.EyeColor.bChecked,			eUICustomizeCat_EyeColor,				false, EForceDefaultColorFlags.EyeColors);
	}
	else
	{
		RandomizeTrait(SoldierPropsLocks.HairColor.bChecked,		eUICustomizeCat_HairColor);
		RandomizeTrait(SoldierPropsLocks.MainColor.bChecked,		eUICustomizeCat_PrimaryArmorColor);
		RandomizeTrait(SoldierPropsLocks.SecondaryColor.bChecked,	eUICustomizeCat_SecondaryArmorColor);
		RandomizeTrait(SoldierPropsLocks.WeaponColor.bChecked,		eUICustomizeCat_WeaponColor);
		RandomizeTrait(SoldierPropsLocks.EyeColor.bChecked,			eUICustomizeCat_EyeColor);
	}

	/*
		Store the state we just created on the buffer as well. This is to support UNDO
		for alterations via the normal UI
	*/
	`log("TOTALRAND: Storing current appearance in undo buffer (if it's not there already).");
	StoreAppearanceStateInUndoBuffer();
}

simulated function UndoAppearanceChanges(UIButton Button)
{
	if (UndoBuffer == none)
		`log("RANDMAIN: There is no UndoBuffer. :(");

	`log("RANDMAIN: Calling Undo.");
	if (UndoBuffer.CanUndo())
		UndoBuffer.Undo();

	`log("RANDMAIN: Rechecking Undo (to set correct button color state).");
	if (!UndoBuffer.CanUndo()) {
		`log("RANDMAIN: Undo disabled.");
		UndoButtonGreyedOut();
	} else {
		`log("RANDMAIN: Undo still good.");
		UndoButtonLitUp();
	}

	ResetTheCamera();
}

simulated function ResetAndConditionallyRandomizeTrait(EUICustomizeCategory Category, bool bIsTraitLocked, float ChanceToRandomize)
{
	/*
		Reset the trait to 0 then, if we're supposed to randomize it, do so.
	*/

	SetTrait(Category, 0, bIsTraitLocked);
	if (RandomizeOrNotBasedOnRoll(ChanceToRandomize)) {
		RandomizeTrait(bIsTraitLocked, Category);
	}
}

simulated function RandomizeTrait(bool bIsTraitLocked, EUICustomizeCategory eCategory,
									optional bool bTotallyRandom = false,
									optional EForceDefaultColorFlags eForceDefaultColor = NotForced)
{
	local array<string> options;
	local int			maxOptions;
	local int			maxRange;
	local int			iCategory;
	local ECategoryType eCatType;
	local int			iDirection;

	/*
		I don't know what int direction does (mostly for lack of trying) but it's the 2nd param
		for OnCategoryValue change and is different for colors (-1) from other parts (0).
	*/

	if (!bIsTraitLocked) {

		iCategory = eCategory; // annoying caveat to UE3; casting inline doesn't work below
		eCatType = class'RandomAppearanceButton_Utilities'.static.GetCategoryType(iCategory);
		iDirection = class'RandomAppearanceButton_Utilities'.static.PropDirection(eCatType);

		switch (iDirection) {
			case 0:
				options = CustomizeMenuScreen.CustomizeManager.GetCategoryList(eCategory);
				maxOptions = options.Length;
				break;
			case -1:

				switch (eForceDefaultColor) {
					case NotForced:
						//`log(" * COLOR FREE FOR ALL.");
						options = CustomizeMenuScreen.CustomizeManager.GetColorList(eCategory);
						maxOptions = options.Length;
						break;
					case ArmorColors:
						//`log(" * USING DEFAULT ARMOR COLORS.");
						maxOptions = RABConf_DefaultArmorColors;
						break;
					case WeaponColors:
						//`log(" * USING DEFAULT WEAPON COLORS.");
						maxOptions = RABConf_DefaultWeaponColors;
						break;
					case EyeColors:
						//`log(" * USING DEFAULT EYE COLORS.");
						maxOptions = RABConf_DefaultEyeColors;
						break;
				}

				break;
		}
	
		if (!bTotallyRandom) {
			maxRange = GetMaxRangeForProp(eCategory);

			if (maxRange != -1 && maxOptions > maxRange)
				maxOptions = maxRange;
		}

		//`log("--> number of options =" @ maxOptions);

		/*

			Here's the meat of the function: we pass a random value (within the determined range)
			to the customize manager via OnCategoryValueChange, which is actually a callback
			usually triggered by UI interaction, I think. (That's why I need to manually call
			UpdateCamera immediately after (with no args) otherwise the camera gets weird.

		*/

		SetTrait(eCategory, `SYNC_RAND(maxOptions), bIsTraitLocked);
		ResetTheCamera();

	} // endif (!bIsTraitLocked)
}

simulated static function ForceSetTrait(UICustomize_Menu Screen, EUICustomizeCategory eCategory, int iSetting)
{
	local ECategoryType		eCatType;
	local int				iDirection;
	local int				iCategory;

	iCategory = eCategory; // annoying caveat of UE3; inline casting won't work below
	eCatType = class'RandomAppearanceButton_Utilities'.static.GetCategoryType(iCategory);
	iDirection = class'RandomAppearanceButton_Utilities'.static.PropDirection(eCatType);

	/*
		OnCategoryValueChange, which is actually a callback	usually triggered
		by UI interaction. Basically the game responds to my mod the same way
		it responds to the user clicking on a given setting within a picker.
	*/
	Screen.CustomizeManager.OnCategoryValueChange(eCategory, iDirection, iSetting);
	Screen.CustomizeManager.UpdateCamera();
}

simulated function SetTrait(EUICustomizeCategory eCategory, int iTraitIndex, bool bIsTraitLocked)
{

	if (!bIsTraitLocked) {
		ForceSetTrait(CustomizeMenuScreen, eCategory, iTraitIndex);
	}

}

simulated static function int GetTrait(UICustomize_Menu Screen, EUICustomizeCategory eCategory)
{
	/*
		Return the (relative) index for the given trait; used for the Undo feature.
	*/

	return Screen.CustomizeManager.GetCategoryIndex(eCategory);
}

private function ResetTheCamera()
{
	/*
		Calling this with no args helps correct the camera, which
		becomes weird (locked, zoomed) otherwise.
	*/

	//CustomizeMenuScreen.CustomizeManager.UpdateCamera();
	class'RandomAppearanceButton_Utilities'.static.ResetTheCamera(CustomizeMenuScreen);
}

private function UpdateScreenData()
{
	/*
		Calling this is necessary to cement certain changes, like
		changes to soldier gender.

		This is a local wrapper for a long-named static function.
	*/

	class'RandomAppearanceButton_Utilities'.static.UpdateScreenData(CustomizeMenuScreen);
}

simulated function int GetMaxRangeForProp(EUICustomizeCategory eCategory)
{
	/*
		Get max range for given prop from config.

		-1 means there's no limit.
	*/

	local int maxRange;
	local int gender;

	maxRange = -1;

	switch (eCategory)
	{
		case eUICustomizeCat_Hairstyle:
			// conditional on gender; want to avoid the "no gender" option so we're explicit.
			gender = GetGender();

			if (gender == eGender_Female)
				return RABConf_HairRangeFemaleLimit;
			else
				return RABConf_HairRangeMaleLimit;
			break;

		case eUICustomizeCat_Helmet:
			maxRange = RABConf_HelmRangeLimit;
			break;

		case eUICustomizeCat_Arms:
			maxRange = RABConf_ArmsRangeLimit;
			break;

		case eUICustomizeCat_Legs:
			maxRange = RABConf_LegsRangeLimit;
			break;

		case eUICustomizeCat_Torso:
			maxRange = RABConf_TorsoRangeLimit;
			break;

		case eUICustomizeCat_FaceDecorationUpper:
			maxRange = RABConf_UpperFacePropLimit;
			break;

		case eUICustomizeCat_FaceDecorationLower:
			maxRange = RABConf_LowerFacePropLimit;
			break;
	}

	return maxRange;
}

simulated function int GetGender()
{
	local XComGameState_Unit unit;

	 unit = CustomizeMenuScreen.Movie.Pres.GetCustomizationUnit();

	 return unit.kAppearance.iGender;
}

simulated function bool RandomizeOrNotBasedOnRoll(float Chance)
{
	if (`SYNC_FRAND() < Chance)
		return true;
	else
		return false;
}


simulated function RunDLCCheck()
{
	/*
		As more DLC comes down the pipe that affects this, I can add
		it to this check loop in the same way.
	*/

	local array<string> installedDlcNames;
	local int i;

	installedDlcNames = class'Helpers'.static.GetInstalledDLCNames();

	for (i=0; i<installedDlcNames.Length; i++)
	{
		`log(" -->" @ i @ installedDlcNames[i]);
		if (installedDLCNames[i] == DLC_1_STR)
			isDLC_1_Installed = true;
	}
}

defaultproperties
{
	ScreenClass = class'UICustomize_Menu';
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */