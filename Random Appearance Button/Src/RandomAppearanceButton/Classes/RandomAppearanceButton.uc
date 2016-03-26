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

var array<UICheckBox>	SoldierPropCheckboxes;

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

	InitRandomAppearanceButtonUI();

	bToggleOptionsButtonVisible = false;

	SoldierPropCheckboxes.Length = eUICustomizeCat_MAX;

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
simulated function InitRandomAppearanceButtonUI()
{	
	ToggleOptionsVisibilityButton		= CreateButton('RandomAppearanceToggle',	"Toggle Options",		ToggleChecklistVisiblity,				class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -154, -165);

	UndoButton							= CreateButton('UndoButton',				"Undo",					UndoAppearanceChanges,					class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -307, -165);
	UndoButtonGreyedOut(); // The buffer starts empty.

	RandomAppearanceButton				= CreateButton('RandomAppearanceButton',	"Random Appearance",	GenerateNormalLookingRandomAppearance,	class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -207, -130);
	TotallyRandomButton					= CreateButton('TotallyRandomButton',		"Totally Random", 		GenerateTotallyRandomAppearance,		class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -160, -95);

	InitOptionsPanel();
}

simulated function InitOptionsPanel()
{
	local int					AnchorPos;
	local int					DLCCheckboxYAdjust;

	/*
		This monolithic function is all in one piece as it makes things much
		easier when I need to move checkboxes around relative to one another.
	*/

	SpawnOptionsBG();

	AnchorPos = class'UIUtilities'.const.ANCHOR_TOP_RIGHT;

	/*
		Buttons on the panel.
	*/

	ToggleGenderButton	= CreateButton('ToggleGender',				"Switch Gender",		ToggleGender,	AnchorPos, -234, CHECKBOX_OFFSET_Y - BUTTON_HEIGHT - BUTTON_SPACING); // xoffset prev -154
	ToggleGenderButton.SetDisabled(false, "Changing gender will clear the undo buffer.");
	ToggleGenderButton.Hide();

	CheckAllButton	= CreateButton('CheckAll',					"All",					CheckAll,		class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -154, -207);
	CheckAllButton.Hide();

	UncheckAllButton = CreateButton('UncheckAll',				"Clear",				UncheckAll,		class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -305, -207);
	UncheckAllButton.Hide();

	/*
		Checkboxes and section labels.

		Body attributes
	*/

	AttribLocksTitle											= CreateTextBox('AttribLocksHeader',	"Lock Body Attributes",	AnchorPos, TITLE_OFFSET_X + 40, CHECKBOX_OFFSET_Y);

	SoldierPropCheckboxes[eUICustomizeCat_Race]					= CreateCheckbox('Lock_Race',			"Race/Skin Color",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(AttribLocksTitle));
	SoldierPropCheckboxes[eUICustomizeCat_Skin]					= CreateCheckbox('Lock_SkinColor',		"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_Race].Y);

	SoldierPropCheckboxes[eUICustomizeCat_Face]					= CreateCheckbox('Lock_Face',			"Face/Beard",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_Race]));
	SoldierPropCheckboxes[eUICustomizeCat_FacialHair]			= CreateCheckbox('Lock_FacialHair',		"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_Face].Y);

	SoldierPropCheckboxes[eUICustomizeCat_FacePaint]			= CreateCheckbox('Lock_FacePaint',		"Paint/Scars",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_Face]));
	SoldierPropCheckboxes[eUICustomizeCat_Scars]				= CreateCheckbox('Lock_Scars',			"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_FacePaint].Y);

	SoldierPropCheckboxes[eUICustomizeCat_Hairstyle]			= CreateCheckbox('Lock_Hair',			"Hair/Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_FacePaint]));
	SoldierPropCheckboxes[eUICustomizeCat_HairColor]			= CreateCheckbox('Lock_HairColor',		"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_Hairstyle].Y);

	SoldierPropCheckboxes[eUICustomizeCat_EyeColor]				= CreateCheckbox('Lock_EyeColor',		"Eye Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_Hairstyle]));

	SoldierPropCheckboxes[eUICustomizeCat_LeftArmTattoos]		= CreateCheckbox('Lock_LeftTattoo',		"Tattoos: L/R",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_EyeColor]));
	SoldierPropCheckboxes[eUICustomizeCat_RightArmTattoos]		= CreateCheckbox('Lock_RightTattoo',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_LeftArmTattoos].Y);
	SoldierPropCheckboxes[eUICustomizeCat_TattooColor]			= CreateCheckbox('Lock_TattooColor',	"Tattoo Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_LeftArmTattoos]));
	
	/*
		Wearables
	*/
	WearablesLocksTitle											= CreateTextBox('WearablesLocksHeader', "Lock Wearables",		AnchorPos, TITLE_OFFSET_X + 60, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_TattooColor]));

	SoldierPropCheckboxes[eUICustomizeCat_Helmet]				= CreateCheckbox('Lock_Helmet',			"Helm",					AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(WearablesLocksTitle));

	SoldierPropCheckboxes[eUICustomizeCat_FaceDecorationUpper]	= CreateCheckbox('Lock_UpperFace',		"Face: Upper/Lower",	AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_Helmet]));
	SoldierPropCheckboxes[eUICustomizeCat_FaceDecorationLower]	= CreateCheckbox('Lock_LowerFace',		"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_FaceDecorationUpper].Y);

	SoldierPropCheckboxes[eUICustomizeCat_Arms]					= CreateCheckbox('Lock_Arms',			"Arms Primary",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_FaceDecorationUpper]));
	
	if (isDLC_1_Installed) {
		/*
			If DLC1 is installed, we need these checkboxes and to draw subsequent checkboxes relative to them.
		*/

		SoldierPropCheckboxes[eUICustomizeCat_LeftArm]			= CreateCheckbox('Lock_LeftArmLower',	"Left Arm/Deco",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_Arms]));
		SoldierPropCheckboxes[eUICustomizeCat_LeftArmDeco]		= CreateCheckbox('Lock_LeftArmUpper',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_LeftArm].Y);			
		
		SoldierPropCheckboxes[eUICustomizeCat_RightArm]			= CreateCheckbox('Lock_RightArmLower',	"Right Arm/Deco",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_LeftArm]));
		SoldierPropCheckboxes[eUICustomizeCat_RightArmDeco]		= CreateCheckbox('Lock_RightArmUpper',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_RightArm].Y);

		DLCCheckboxYAdjust = SoldierPropCheckboxes[eUICustomizeCat_RightArm].Y + SoldierPropCheckboxes[eUICustomizeCat_RightArm].Height + BUTTON_SPACING;
	} else {
		/*
			Otherwise, make like it's not there.
		*/

		DLCCheckboxYAdjust = SoldierPropCheckboxes[eUICustomizeCat_Arms].Y + SoldierPropCheckboxes[eUICustomizeCat_Arms].Height + BUTTON_SPACING;
	}
	
	SoldierPropCheckboxes[eUICustomizeCat_Torso]				= CreateCheckbox('Lock_Torso',			"Torso",				AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, DLCCheckboxYAdjust);
	SoldierPropCheckboxes[eUICustomizeCat_Legs]					= CreateCheckbox('Lock_Legs',			"Legs",					AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_Torso]));

	/*
		Colors + Patterns
	*/
	WearablesColorsLocksTitles									= CreateTextBox('WearablesColorsHead',	"Lock Patterns & Colors", AnchorPos, TITLE_OFFSET_X + 30, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_Legs]));

	SoldierPropCheckboxes[eUICustomizeCat_ArmorPatterns]		= CreateCheckbox('Lock_ArmorPattern',	"Armor Pattern",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(WearablesColorsLocksTitles));
	SoldierPropCheckboxes[eUICustomizeCat_PrimaryArmorColor]	= CreateCheckbox('Lock_MainColor',		"Armor Color 1/2",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_ArmorPatterns]));
	SoldierPropCheckboxes[eUICustomizeCat_SecondaryArmorColor]	= CreateCheckbox('Lock_SecondaryColor',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropCheckboxes[eUICustomizeCat_PrimaryArmorColor].Y);

	SoldierPropCheckboxes[eUICustomizeCat_WeaponPatterns]		= CreateCheckbox('Lock_WeaponPattern',	"Weapon Pattern",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_PrimaryArmorColor]));	
	SoldierPropCheckboxes[eUICustomizeCat_WeaponColor]			= CreateCheckbox('Lock_WeaponColor',	"Weapon Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropCheckboxes[eUICustomizeCat_WeaponPatterns]));
}

simulated function int PanelYShiftDownFrom(UIPanel Element)
{
	return Element.Y + Element.Height + BUTTON_SPACING;
}

simulated function SpawnOptionsBG()
{

	BGBox = CustomizeMenuScreen.Spawn(class'UIPanel', CustomizeMenuScreen);
	BGBox.InitPanel('BGBox', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
	BGBox.AnchorTopRight();
	BGBox.SetSize(320, 850);
	BGBox.SetPosition(-310,CHECKBOX_OFFSET_Y - BUTTON_HEIGHT - BUTTON_SPACING - 10);	// remember, relative to the anchor
	BGBox.Hide();

}

simulated function ToggleChecklistVisiblity(UIButton Button)
{
	local int iCategory;

	/*
		This method only hides/unhides the checklist on the
		button being pressed.

		(Unused param is a UE3 thing: required for UIButton callback.)
	*/

	BGBox.ToggleVisible();
	ToggleGenderButton.ToggleVisible();

	AttribLocksTitle.ToggleVisible();
	WearablesLocksTitle.ToggleVisible();
	WearablesColorsLocksTitles.ToggleVisible();
	

	for (iCategory = 0; iCategory < eUICustomizeCat_MAX; iCategory++) {
		if (SoldierPropCheckboxes[iCategory] != none) {
			SoldierPropCheckboxes[iCategory].ToggleVisible();
		}
	}

	CheckAllButton.ToggleVisible();
	UncheckAllButton.ToggleVisible();

	if (bToggleOptionsButtonVisible) {
		bToggleOptionsButtonVisible = false;
	} else {
		bToggleOptionsButtonVisible = true;
	}

}

simulated function HideUI()
{
	local int iCategory;

	/*
		Hides the mod's UI when losing focus.
	*/

	if (bToggleOptionsButtonVisible) {

		BGBox.Hide();
		ToggleGenderButton.Hide();

		AttribLocksTitle.Hide();
		WearablesLocksTitle.Hide();
		WearablesColorsLocksTitles.Hide();

		for (iCategory = 0; iCategory < eUICustomizeCat_MAX; iCategory++) {
			if (SoldierPropCheckboxes[iCategory] != none) {
				SoldierPropCheckboxes[iCategory].Hide();
			}
		}

		CheckAllButton.Hide();
		UncheckAllButton.Hide();
	}

	ToggleOptionsVisibilityButton.Hide();
	RandomAppearanceButton.Hide();
	TotallyRandomButton.Hide();
	UndoButton.Hide();

}

simulated function ShowUI()
{
	local int iCategory;

	/*
		Since this func is called only on a Receive Focus event,
		if the options panel was visible prior to calling this,
		it should be visible again. (I.E. if the user had the
		panel up, then clicked to edit eye color, then came back
		to the root, they should see the options panel still.)

		It's a bug right now but it doesn't work for colors. :(
		I'm pretty sure this is on Firaxis's end.
	*/

	if (bToggleOptionsButtonVisible) {
		BGBox.Show();
		ToggleGenderButton.Show();

		AttribLocksTitle.Show();
		WearablesLocksTitle.Show();
		WearablesColorsLocksTitles.Show();

		for (iCategory = 0; iCategory < eUICustomizeCat_MAX; iCategory++) {
			if (SoldierPropCheckboxes[iCategory] != none) {
				SoldierPropCheckboxes[iCategory].Show();
			}
		}

		CheckAllButton.Show();
		UncheckAllButton.Show();
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

	/*
		OnCategoryValueChange is set up to receive data from a UIList; in the
		case of the index, it's using 0 (for male) and 1 (for female) as that's
		their order in the visual representation...whereas the enum there's
		a "none" options, so it's 1 for male and 2 for female.

		I subtract 1 from the enum in each case so I can continue changing stuff
		via the UI hooks.

		(Unused param is a UE3 thing: required for UIButton callback.)
	*/	
	Unit = CustomizeMenuScreen.Movie.Pres.GetCustomizationUnit();

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

	// TODO: handle the DLC1 arms flag; will need to ask the current state and plug that in here
	StoreAppearanceStateInUndoBuffer( class'RandomAppearanceButton_Utilities'.static.SoldierHasDLC1Arms(CustomizeMenuScreen) ); 

	ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_Gender, newGender);	
	//CustomizeMenuScreen.UpdateData(); // If I don't do this, things can get weird.
	UpdateScreenData();

	//UndoBuffer.ClearTheBuffer();
	//UndoButtonGreyedOut();
}

simulated function StoreAppearanceStateInUndoBuffer(bool bDLC1ArmComponents)
{
	UndoBuffer.StoreCurrentState(bDLC1ArmComponents);
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
	local int iCategory;

	/*
		(Unused param is a UE3 thing: required for UIButton callback.)
	*/

	for (iCategory = 0; iCategory < eUICustomizeCat_MAX; iCategory++) {
		if (SoldierPropCheckboxes[iCategory] != none) {
			SoldierPropCheckboxes[iCategory].SetChecked(true);
		}
	}

}

simulated function UncheckAll(UIButton Button)
{
	local int iCategory;

	/*
		(Unused param is a UE3 thing: required for UIButton callback.)
	*/

	for (iCategory = 0; iCategory < eUICustomizeCat_MAX; iCategory++) {
		if (SoldierPropCheckboxes[iCategory] != none) {
			SoldierPropCheckboxes[iCategory].Show();
		}
	}

}

simulated function UIButton CreateButton(name ButtonName, string ButtonLabel,
										delegate<OnClickedDelegate> OnClickCallThis, 
										int AnchorPos, int XOffset, int YOffset)
{
	local UIButton  NewButton;
	
	NewButton = CustomizeMenuScreen.Spawn(class'UIButton', CustomizeMenuScreen);
	NewButton.InitButton(ButtonName, class'UIUtilities_Text'.static.GetSizedText(ButtonLabel, BUTTON_LABEL_FONTSIZE), OnClickCallThis);
	NewButton.SetAnchor(AnchorPos);
	NewButton.SetPosition(XOffset, YOffset);
	NewButton.SetSize(NewButton.Width, BUTTON_HEIGHT);
	
	return NewButton;
}

simulated function UICheckbox CreateCheckbox(name CheckboxName, string CheckboxLabel, 
											 int AnchorPos, int XOffset, int YOffset)
{
	local UICheckbox  NewCheckbox;
	
	NewCheckbox = CustomizeMenuScreen.Spawn(class'UICheckbox', CustomizeMenuScreen);
	NewCheckbox.InitCheckbox(CheckboxName, CheckboxLabel);
	NewCheckbox.SetAnchor(AnchorPos);
	NewCheckbox.SetPosition(XOffset, YOffset);
	NewCheckbox.SetSize(NewCheckbox.Width, BUTTON_HEIGHT);
	NewCheckbox.Hide();
	
	return NewCheckbox;
}

simulated function UIText CreateTextBox(name TextBoxName, string strText, int AnchorPos, float XOffset, float YOffset)
{
	local UIText TextBox;

	TextBox = CustomizeMenuScreen.Spawn(class'UIText', CustomizeMenuScreen);
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
	local bool bThisGeneratedAppearanceHasDLC1Arms;

	/*
		(Unused param is a UE3 thing: required for UIButton callback.)
	*/

	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");
	`log("GENERATING TOTALLY RANDOM APPEARANCE");
	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");
	
	`log("TOTALRAND: Storing current appearance in undo buffer (if it's not there already).");
	StoreAppearanceStateInUndoBuffer( class'RandomAppearanceButton_Utilities'.static.SoldierHasDLC1Arms(CustomizeMenuScreen) );

	// Core customization menu
	RandomizeTrait(eUICustomizeCat_Face,				true);
	RandomizeTrait(eUICustomizeCat_Hairstyle,			true);
	RandomizeTrait(eUICustomizeCat_FacialHair,			true);
	RandomizeTrait(eUICustomizeCat_HairColor,			true);
	RandomizeTrait(eUICustomizeCat_EyeColor,			true);
	RandomizeTrait(eUICustomizeCat_Race,				true);
	RandomizeTrait(eUICustomizeCat_Skin,				true);
	RandomizeTrait(eUICustomizeCat_PrimaryArmorColor,	true);
	RandomizeTrait(eUICustomizeCat_SecondaryArmorColor,	true);
	RandomizeTrait(eUICustomizeCat_WeaponColor,			true);

	// customize props menu
	RandomizeTrait(eUICustomizeCat_FaceDecorationUpper,	true);
	RandomizeTrait(eUICustomizeCat_FaceDecorationLower,	true);
	RandomizeTrait(eUICustomizeCat_Helmet,				true);	
	RandomizeTrait(eUICustomizeCat_Torso,				true);
	RandomizeTrait(eUICustomizeCat_Legs,				true);
	RandomizeTrait(eUICustomizeCat_ArmorPatterns,		true);
	RandomizeTrait(eUICustomizeCat_WeaponPatterns,		true);
	RandomizeTrait(eUICustomizeCat_LeftArmTattoos,		true);
	RandomizeTrait(eUICustomizeCat_RightArmTattoos,		true);
	RandomizeTrait(eUICustomizeCat_TattooColor,			true);
	RandomizeTrait(eUICustomizeCat_Scars,				true);
	RandomizeTrait(eUICustomizeCat_FacePaint,			true);

	`log("DOING ARMS.");
	`log("Checking for DLC1.");
	// deal with anarchy's children dlc
	if (isDLC_1_Installed)
	{
		`log("DLC1 installed.");
		bThisGeneratedAppearanceHasDLC1Arms = HandleDLC1();

	} else {
		bThisGeneratedAppearanceHasDLC1Arms = false;

		`log("No DLC, rolling arms as normal.");
		RandomizeTrait(eUICustomizeCat_Arms,			true);
	}
	`log("DONE WITH ARMS.");

	`log("TOTALRAND: Storing current appearance in undo buffer.");
	StoreAppearanceStateInUndoBuffer(bThisGeneratedAppearanceHasDLC1Arms);
}

simulated function bool HandleDLC1()
{
	local bool bUsingDLC1Arms;

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

		There are 6 core arms options from vanilla and 5^4 options from Anarchy's children...which
		is a LOT more than 6, so instead of	treating ALL the AC DLC arms as equally, let's treat it
		as ONE arm and let it be configurable by the user if they want these more often.

		In short: if anything is locked, then we don't want to bother with the % chance of arm
		component, because there's never a case where they'll be locked and we don't want to roll
		one. If NONE of them are locked, then we constrain based on chance.	
	*/

	// if	(SoldierPropsLocks.Arms.bChecked) then DON'T DO ANYTHING
	//		Rolling on Arms is harmless (it respects this lock) but the way I've got these locks
	//		implemented, the DLC arm slots won't respect this lock...so we enforce it here.
	// else	we have two cases that fall under !SoldierPropCheckboxes[eUICustomizeCat_Arms].bChecked:
	//		if ANY of these are bChecked: LeftArm, RightArm, LeftArmDeco, RightArmDeco
	//			THEN roll NO MATTER WHAT
	//		else if NONE of them are locked (and, given where we are, the Arms themselves aren't locked)
	//		if DLC_1 torso, that doesn't allow vanilla arms, so check for that and constrain.
	//		else we just constrain on (configurable) % chance

	if (!SoldierPropCheckboxes[eUICustomizeCat_Arms].bChecked) {

		if (SoldierPropCheckboxes[eUICustomizeCat_LeftArmDeco].bChecked	|| SoldierPropCheckboxes[eUICustomizeCat_RightArmDeco].bChecked ||
			SoldierPropCheckboxes[eUICustomizeCat_LeftArm].bChecked		|| SoldierPropCheckboxes[eUICustomizeCat_RightArm].bChecked) {

			/*
				If any one of these are locked, then we can't roll for standard arms because they'll
				override whatever DLC arm prop is locked, so...we just don't. We instead roll for
				the new arm props.

				Since we're going to be getting DLC arms here, we set the arms to the "unset" or default position
				of -1.
			*/
			//ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_Arms, -1);
			bUsingDLC1Arms = true;
			RandomizeDLC1ArmSlots();

		} else {
			/*
				Arms aren't locked, new arm props aren't locked, sooo roll for the arms then, to handle
				the concerns laid out in the above back-of-the napkin math, we only overwrite the new
				arms picked based on a (small) chance from the config.
			*/

			if (class'RandomAppearanceButton_Utilities'.static.SoldierHasDLC1Torso(CustomizeMenuScreen)) {
				// vanilla arms not allowed, force roll on DLC1 arms.
				//ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_Arms, -1);
				bUsingDLC1Arms = true;
				RandomizeDLC1ArmSlots();
			} else {
				// vanilla torsos are totally cool with DLC1 arms, so go to town

				//ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_LeftArm, 0);
				//ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_RightArm, 0);
				//ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_LeftArmDeco, 0);
				//ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_RightArmDeco, 0);
			
				bUsingDLC1Arms = false;
				RandomizeTrait(eUICustomizeCat_Arms, true);
			
				if (RandomizeOrNotBasedOnRoll(RABConf_TotallyRandom_AnarchysChildrenArmsChance)) {

					/*
						We're only in here because primary Arms aren't locked and none of the DLC arm slots are locked,
						in which case we ONLY want to see DLC arm elements pop in (and override the much smaller number
						of vanilla arms) some of the time and not all of the time. (See above for shoddy napkin math.)

						The chance is set in the config file.

						Since we're going to be getting DLC arms here, we set the arms to the "unset" or default position
						of -1.
					*/
					//ForceSetTrait(CustomizeMenuScreen, eUICustomizeCat_Arms, -1);
					bUsingDLC1Arms = true;
					RandomizeDLC1ArmSlots();
				}
			}			
		}
		
	} else {

	/*
		Otherwise, no worries, just roll on the arms the old fashioned way!
	*/
		bUsingDLC1Arms = false;
		RandomizeTrait(eUICustomizeCat_Arms,					true);
	}

	return bUsingDLC1Arms;
}

simulated function RandomizeDLC1ArmSlots()
{
	RandomizeTrait(eUICustomizeCat_LeftArmDeco,		true);
	RandomizeTrait(eUICustomizeCat_RightArmDeco,	true);
	RandomizeTrait(eUICustomizeCat_LeftArm,			true);
	RandomizeTrait(eUICustomizeCat_RightArm,		true);
}

simulated function GenerateNormalLookingRandomAppearance(UIButton Button)
{
	/*
		(Unused param is a UE3 thing: required for UIButton callback.)
	*/

	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");
	`log("GENERATING NORMAL LOOKING APPEARANCE");
	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");

	`log("TOTALRAND: Storing current appearance in undo buffer.");
	StoreAppearanceStateInUndoBuffer( class'RandomAppearanceButton_Utilities'.static.SoldierHasDLC1Arms(CustomizeMenuScreen) );

	/*
		Basically need to clear any/all extended stuff (e.g. props) so the result here doesn't look like it's fixed
		and weird.

		If you click the button and get a hat, that hat will persist through further clicks on the button...which
		feels weird; so I clear the hat (and other props) then regen the chance to get one again.
	*/

	// For Sure do these.
	RandomizeTrait(eUICustomizeCat_Face);
	RandomizeTrait(eUICustomizeCat_Hairstyle);
		
	RandomizeTrait(eUICustomizeCat_Race);
	RandomizeTrait(eUICustomizeCat_Skin);

	RandomizeTrait(eUICustomizeCat_Arms);
	RandomizeTrait(eUICustomizeCat_Torso);
	RandomizeTrait(eUICustomizeCat_Legs);

	/*
		Conditionally randomize these (configurable in XComRandomAppearanceButton.ini).

		Optionals per the game's default soldier generator: facial hair and decorations, hat.
		Optionals per me: armor and weapon patterns, tattoos, scars, face paint.
	*/
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FacialHair,				RABConf_BeardChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FaceDecorationUpper,	RABConf_UpperFacePropChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FaceDecorationLower,	RABConf_LowerFacePropChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_Helmet,					RABConf_HatChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_ArmorPatterns,			RABConf_ArmorPatternChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_WeaponPatterns,			RABConf_WeaponPatternChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_Scars,					RABConf_ScarsChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FacePaint,				RABConf_FacePaintChance);

	/*
		I handle the tattoos as one field; could handle them individually as I do everything else, but this made
		more sense to me.

		Set the color (if there are no tattoos, no worries, it won't show up).
	*/
	RandomizeTrait(eUICustomizeCat_TattooColor);

	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_LeftArmTattoos,			RABConf_TattoosChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_RightArmTattoos,		RABConf_TattoosChance);
	
	/*
		Colors!
	*/
	if (RABConf_ForceDefaultColors)
	{
		RandomizeTrait(eUICustomizeCat_HairColor,				false, EForceDefaultColorFlags.HairColors);
		RandomizeTrait(eUICustomizeCat_PrimaryArmorColor,		false, EForceDefaultColorFlags.ArmorColors);
		RandomizeTrait(eUICustomizeCat_SecondaryArmorColor,		false, EForceDefaultColorFlags.ArmorColors);
		RandomizeTrait(eUICustomizeCat_WeaponColor,				false, EForceDefaultColorFlags.WeaponColors);
		RandomizeTrait(eUICustomizeCat_EyeColor,				false, EForceDefaultColorFlags.EyeColors);
	}
	else
	{
		RandomizeTrait(eUICustomizeCat_HairColor);
		RandomizeTrait(eUICustomizeCat_PrimaryArmorColor);
		RandomizeTrait(eUICustomizeCat_SecondaryArmorColor);
		RandomizeTrait(eUICustomizeCat_WeaponColor);
		RandomizeTrait(eUICustomizeCat_EyeColor);
	}

	/*
		Store the state we just created on the buffer as well. This is to support UNDO
		for alterations via the normal UI
	*/
	`log("TOTALRAND: Storing current appearance in undo buffer (if it's not there already).");
	StoreAppearanceStateInUndoBuffer(false); // Currently normal looking soldiers never get DLC_1 arms. They're spikey and weird, so.
}

simulated function UndoAppearanceChanges(UIButton Button)
{
	// (Unused param is a UE3 thing: required for UIButton callback.)

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

simulated function ResetAndConditionallyRandomizeTrait(EUICustomizeCategory Category, float ChanceToRandomize)
{
	/*
		Reset the trait to 0 then, if we're supposed to randomize it, do so.
	*/

	SetTrait(Category, 0);
	if (RandomizeOrNotBasedOnRoll(ChanceToRandomize)) {
		RandomizeTrait(Category);
	}
}

simulated function RandomizeTrait(EUICustomizeCategory eCategory, optional bool bTotallyRandom = false,	optional EForceDefaultColorFlags eForceDefaultColor = NotForced)
{
	local array<string> options;
	local int			maxOptions;
	local int			maxRange;
	local int			iCategory;
	local ECategoryType eCatType;
	local int			iDirection;
	local bool			bIsTraitLocked;

	/*
		I don't know what int direction does (mostly for lack of trying) but it's the 2nd param
		for OnCategoryValue change and is different for colors (-1) from other parts (0).
	*/

	bIsTraitLocked = SoldierPropCheckboxes[eCategory].bChecked;

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

		SetTrait(eCategory, `SYNC_RAND(maxOptions));
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

simulated function SetTrait(EUICustomizeCategory eCategory, int iTraitIndex)
{
	local bool bIsTraitLocked;

	bIsTraitLocked = SoldierPropCheckboxes[eCategory].bChecked;

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