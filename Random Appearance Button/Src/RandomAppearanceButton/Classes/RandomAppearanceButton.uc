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

	Figure out how to access and set the new Anarchy's Children DLC deco slots.
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

struct SoldierAttribLock {
	var UICheckBox Face;
	var UICheckBox Hair;
	var UICheckBox FacialHair;
	var UICheckBox HairColor;
	var UICheckBox EyeColor;
	var UICheckBox Race;
	var UICheckBox SkinColor;
	var UICheckBox MainColor;
	var UICheckBox SecondaryColor;
	var UICheckBox WeaponColor;

	structdefaultproperties {
		Face				= none;
		Hair				= none;
		FacialHair			= none;
		HairColor			= none;
		EyeColor			= none;
		Race				= none;
		SkinColor			= none;
		MainColor			= none;
		SecondaryColor		= none;
		WeaponColor			= none;
	}
};

struct SoldierPropsLock {
	var UICheckBox		UpperFace;
	var UICheckBox		LowerFace;
	var UICheckBox		Helmet;
	var UICheckBox		Arms;
	var UICheckBox		Torso;
	var UICheckBox		Legs;
	var UICheckBox		ArmorPattern;
	var UICheckBox		WeaponName;
	var UICheckBox		WeaponColor;
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

	structdefaultproperties {
		UpperFace		= none;
		LowerFace		= none;
		Helmet			= none;
		Arms			= none;
		Torso			= none;
		Legs			= none;
		ArmorPattern	= none;
		WeaponName		= none;
		WeaponColor		= none;
		WeaponPattern	= none;
		TattoosLeft		= none;
		TattoosRight	= none;
		TattoosColor	= none;
		Scars			= none;
		FacePaint		= none;
		LeftArmUpper	= none;
		LeftArmLower	= none;
		RightArmUpper	= none;
		RightArmLower	= none;
	}
};


var SoldierAttribLock	SoldierAttribLocks;
var SoldierPropsLock	SoldierPropsLocks;

const DLC_1_STR = "DLC_1";
var bool				isDLC_1_Installed;

var UICustomize_Menu	CustomizeMenuScreen;

var UIPanel				BGBox;
var UIButton			RandomAppearanceButton;
var UIButton			TotallyRandomButton;
var UIButton			RandomApperanceToggle;
var UIButton			ToggleGenderButton;
var UIButton			CheckAllButton;
var UIButton			UncheckAllButton;

var UIText				AttribLocksTitle;
var UIText				WearablesLocksTitle;
var UIText				WearablesColorsLocksTitles;

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

event OnInit(UIScreen Screen)
{	
	CustomizeMenuScreen = UICustomize_Menu(Screen);
	if (CustomizeMenuScreen == none)
		return;

	RunDLCCheck();

	CreateTheChecklist();
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
	Spawn a new button/checkbox on the given screen with the given params.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
simulated function CreateTheChecklist(/*UIScreen Screen*/)
{
	local int					AnchorPos;
	local int					DLCCheckboxYAdjust;
	
	RandomApperanceToggle				= CreateButton(CustomizeMenuScreen, 'RandomAppearanceToggle',	"Toggle Options",		ToggleChecklistVisiblity,				class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -154, -165);
	RandomAppearanceButton				= CreateButton(CustomizeMenuScreen, 'RandomAppearanceButton',	"Random Appearance",	GenerateNormalLookingRandomAppearance,	class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -207, -130);
	TotallyRandomButton					= CreateButton(CustomizeMenuScreen, 'TotallyRandomButton',		"Totally Random", 		GenerateTotallyRandomAppearance,				class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -160, -95);

	SpawnOptionsBG(CustomizeMenuScreen);

	AnchorPos = class'UIUtilities'.const.ANCHOR_TOP_RIGHT;

	ToggleGenderButton					= CreateButton(CustomizeMenuScreen, 'ToggleGender',				"Switch Gender",		ToggleGender,	AnchorPos, -234, CHECKBOX_OFFSET_Y - BUTTON_HEIGHT - BUTTON_SPACING); // xoffset prev -154
	ToggleGenderButton.Hide();

	CheckAllButton						= CreateButton(CustomizeMenuScreen, 'CheckAll',					"All",					CheckAll,		class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -154, -207);
	CheckAllButton.Hide();

	UncheckAllButton					= CreateButton(CustomizeMenuScreen, 'UncheckAll',				"Clear",				UncheckAll,		class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT, -305, -207);
	UncheckAllButton.Hide();

	AttribLocksTitle					= CreateTextBox(CustomizeMenuScreen,	'AttribLocksHeader',	"Lock Body Attributes",	AnchorPos, TITLE_OFFSET_X + 40, CHECKBOX_OFFSET_Y);

	SoldierAttribLocks.Race				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Race',		"Race/Skin Color",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(AttribLocksTitle));
	SoldierAttribLocks.SkinColor		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_SkinColor',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierAttribLocks.Race.Y);

	SoldierAttribLocks.Face				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Face',		"Face/Beard",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierAttribLocks.Race));
	SoldierAttribLocks.FacialHair		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_FacialHair',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierAttribLocks.Face.Y);

	SoldierPropsLocks.FacePaint			= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_FacePaint',	"Paint/Scars",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierAttribLocks.Face));
	SoldierPropsLocks.Scars				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Scars',		"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierPropsLocks.FacePaint.Y);

	SoldierAttribLocks.Hair				= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_Hair',		"Hair/Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.FacePaint));
	SoldierAttribLocks.HairColor		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_HairColor',	"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierAttribLocks.Hair.Y);

	SoldierAttribLocks.EyeColor			= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_EyeColor',	"Eye Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierAttribLocks.Hair));

	SoldierPropsLocks.TattoosLeft		= CreateCheckbox(CustomizeMenuScreen,	'Checkbox_LeftTattoo',	"Tattoos: L/R",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierAttribLocks.EyeColor));
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
	SoldierAttribLocks.MainColor		= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_MainColor',		"Armor Color 1/2",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.ArmorPattern));
	SoldierAttribLocks.SecondaryColor	= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_SecondaryColor',"",						AnchorPos, CHECKBOX_OFFSET_X, SoldierAttribLocks.MainColor.Y);

	SoldierPropsLocks.WeaponPattern		= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_WeaponPattern',	"Weapon Pattern",		AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierAttribLocks.MainColor));	
	SoldierAttribLocks.WeaponColor		= CreateCheckbox(CustomizeMenuScreen, 'Checkbox_WeaponColor',	"Weapon Color",			AnchorPos, CHECKBOX_OFFSET_X - CHECKBOX_NEIGHBOR_OFFSET, PanelYShiftDownFrom(SoldierPropsLocks.WeaponPattern));

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

	BGBox.ToggleVisible();
	ToggleGenderButton.ToggleVisible();

	AttribLocksTitle.ToggleVisible();
	WearablesLocksTitle.ToggleVisible();
	WearablesColorsLocksTitles.ToggleVisible();

	SoldierAttribLocks.Face.ToggleVisible();
	SoldierAttribLocks.Hair.ToggleVisible();
	SoldierAttribLocks.FacialHair.ToggleVisible();
	SoldierAttribLocks.HairColor.ToggleVisible();
	SoldierAttribLocks.EyeColor.ToggleVisible();
	SoldierAttribLocks.Race.ToggleVisible();
	SoldierAttribLocks.SkinColor.ToggleVisible();
	SoldierAttribLocks.MainColor.ToggleVisible();
	SoldierAttribLocks.SecondaryColor.ToggleVisible();
	SoldierAttribLocks.WeaponColor.ToggleVisible();

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

}

simulated function ToggleGender(UIButton Button)
{
	local int					newGender;
	local XComGameState_Unit	Unit;

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

	UICustomize_Menu(`SCREENSTACK.GetCurrentScreen()).CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Gender, 0, newGender);
	UICustomize_Menu(`SCREENSTACK.GetCurrentScreen()).UpdateData();
}

simulated function CheckAll(UIButton Button)
{
	
	SoldierAttribLocks.Face.SetChecked(true);
	SoldierAttribLocks.Hair.SetChecked(true);
	SoldierAttribLocks.FacialHair.SetChecked(true);
	SoldierAttribLocks.HairColor.SetChecked(true);
	SoldierAttribLocks.EyeColor.SetChecked(true);
	SoldierAttribLocks.Race.SetChecked(true);
	SoldierAttribLocks.SkinColor.SetChecked(true);
	SoldierAttribLocks.MainColor.SetChecked(true);
	SoldierAttribLocks.SecondaryColor.SetChecked(true);
	SoldierAttribLocks.WeaponColor.SetChecked(true);

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

	SoldierAttribLocks.Face.SetChecked(false);
	SoldierAttribLocks.Hair.SetChecked(false);
	SoldierAttribLocks.FacialHair.SetChecked(false);
	SoldierAttribLocks.HairColor.SetChecked(false);
	SoldierAttribLocks.EyeColor.SetChecked(false);
	SoldierAttribLocks.Race.SetChecked(false);
	SoldierAttribLocks.SkinColor.SetChecked(false);
	SoldierAttribLocks.MainColor.SetChecked(false);
	SoldierAttribLocks.SecondaryColor.SetChecked(false);
	SoldierAttribLocks.WeaponColor.SetChecked(false);

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
	`log("GENERATING NEW APPEARANCE");
	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");

	// Core customization menu
	RandomizeTrait(SoldierAttribLocks.Face.bChecked,			eUICustomizeCat_Face,					0,	true);
	RandomizeTrait(SoldierAttribLocks.Hair.bChecked,			eUICustomizeCat_Hairstyle,				0,	true);
	RandomizeTrait(SoldierAttribLocks.FacialHair.bChecked,		eUICustomizeCat_FacialHair,				0,	true);
	RandomizeTrait(SoldierAttribLocks.HairColor.bChecked,		eUICustomizeCat_HairColor,				-1, true);
	RandomizeTrait(SoldierAttribLocks.EyeColor.bChecked,		eUICustomizeCat_EyeColor,				-1, true);
	RandomizeTrait(SoldierAttribLocks.Race.bChecked,			eUICustomizeCat_Race,					0,	true);
	RandomizeTrait(SoldierAttribLocks.SkinColor.bChecked,		eUICustomizeCat_Skin,					-1, true);
	RandomizeTrait(SoldierAttribLocks.MainColor.bChecked,		eUICustomizeCat_PrimaryArmorColor,		-1, true);
	RandomizeTrait(SoldierAttribLocks.SecondaryColor.bChecked,	eUICustomizeCat_SecondaryArmorColor,	-1, true);
	RandomizeTrait(SoldierAttribLocks.WeaponColor.bChecked,		eUICustomizeCat_WeaponColor,			-1, true);

	// customize props menu
	RandomizeTrait(SoldierPropsLocks.UpperFace.bChecked,		eUICustomizeCat_FaceDecorationUpper,	0,	true);
	RandomizeTrait(SoldierPropsLocks.LowerFace.bChecked,		eUICustomizeCat_FaceDecorationLower,	0,	true);
	RandomizeTrait(SoldierPropsLocks.Helmet.bChecked,			eUICustomizeCat_Helmet,					0,	true);	
	RandomizeTrait(SoldierPropsLocks.Torso.bChecked,			eUICustomizeCat_Torso,					0,	true);
	RandomizeTrait(SoldierPropsLocks.Legs.bChecked,				eUICustomizeCat_Legs,					0,	true);
	RandomizeTrait(SoldierPropsLocks.ArmorPattern.bChecked,		eUICustomizeCat_ArmorPatterns,			0,	true);
	RandomizeTrait(SoldierPropsLocks.WeaponPattern.bChecked,	eUICustomizeCat_WeaponPatterns,			0,	true);
	RandomizeTrait(SoldierPropsLocks.TattoosLeft.bChecked,		eUICustomizeCat_LeftArmTattoos,			0,	true);
	RandomizeTrait(SoldierPropsLocks.TattoosRight.bChecked,		eUICustomizeCat_RightArmTattoos,		0,	true);
	RandomizeTrait(SoldierPropsLocks.TattoosColor.bChecked,		eUICustomizeCat_TattooColor,			-1,	true);
	RandomizeTrait(SoldierPropsLocks.Scars.bChecked,			eUICustomizeCat_Scars,					0,	true);
	RandomizeTrait(SoldierPropsLocks.FacePaint.bChecked,		eUICustomizeCat_FacePaint,				0,	true);

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
		RandomizeTrait(SoldierPropsLocks.Arms.bChecked,				eUICustomizeCat_Arms,					0,	true);
	}
	`log("DONE WITH ARMS.");

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
			*/

			RandomizeDLC1ArmSlots();

		} else {
			/*
				Arms aren't locked, new arm props aren't locked, sooo roll for the arms then, to handle
				the concerns laid out in the above back-of-the napkin math, we only overwrite the new
				arms picked based on a (small) chance from the config.
			*/
			
			RandomizeTrait(SoldierPropsLocks.Arms.bChecked,				eUICustomizeCat_Arms,					0,	true);
			
			if (RandomizeOrNotBasedOnRoll(RABConf_TotallyRandom_AnarchysChildrenArmsChance)) {

				/*
					We're only in here because primary Arms aren't locked and none of the DLC arm slots are locked,
					in which case we ONLY want to see DLC arm elements pop in (and override the much smaller number
					of vanilla arms) some of the time and not all of the time. (See above for shoddy napkin math.)

					The chance is set in the config file.
				*/
				RandomizeDLC1ArmSlots();
			}
		}
		
	} else {

	/*
		Otherwise, no worries, just roll on the arms the old fashioned way!
	*/

		RandomizeTrait(SoldierPropsLocks.Arms.bChecked,				eUICustomizeCat_Arms,					0,	true);
	}
}

simulated function RandomizeDLC1ArmSlots()
{
	RandomizeTrait(SoldierPropsLocks.LeftArmUpper.bChecked,		eUICustomizeCat_LeftArmDeco,		0, true);
	RandomizeTrait(SoldierPropsLocks.RightArmUpper.bChecked,	eUICustomizeCat_RightArmDeco,		0, true);
	RandomizeTrait(SoldierPropsLocks.LeftArmLower.bChecked,		eUICustomizeCat_LeftArm,			0, true);
	RandomizeTrait(SoldierPropsLocks.RightArmLower.bChecked,	eUICustomizeCat_RightArm,			0, true);
}

simulated function GenerateNormalLookingRandomAppearance(UIButton Button)
{
	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");
	`log("GENERATING NEW NORMAL LOOKING APPEARANCE");
	`log("");
	`log("* * * * * * * * * * * * * * * * * * * * * * * * *");
	`log("");

	/*
		Basically need to clear any/all extended stuff (e.g. props) so the result here doesn't look like it's fixed
		and weird.

		If you click the button and get a hat, that hat will persist through further clicks on the button...which
		feels weird; so I clear the hat (and other props) then regen the chance to get one again.
	*/

	// For Sure do these.
	RandomizeTrait(SoldierAttribLocks.Face.bChecked,			eUICustomizeCat_Face,		0);
	RandomizeTrait(SoldierAttribLocks.Hair.bChecked,			eUICustomizeCat_Hairstyle,	0);
		
	RandomizeTrait(SoldierAttribLocks.Race.bChecked,			eUICustomizeCat_Race,		0);
	RandomizeTrait(SoldierAttribLocks.SkinColor.bChecked,		eUICustomizeCat_Skin,		-1);

	RandomizeTrait(SoldierPropsLocks.Arms.bChecked,				eUICustomizeCat_Arms,		0);
	RandomizeTrait(SoldierPropsLocks.Torso.bChecked,			eUICustomizeCat_Torso,		0);
	RandomizeTrait(SoldierPropsLocks.Legs.bChecked,				eUICustomizeCat_Legs,		0);

	/*
		Conditionally randomize these (configurable in XComRandomAppearanceButton.ini).

		Optionals per the game's default soldier generator: facial hair and decorations, hat.
		Optionals per me: armor and weapon patterns, tattoos, scars, face paint.
	*/
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FacialHair,				0, SoldierAttribLocks.FacialHair.bChecked,		RABConf_BeardChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FaceDecorationUpper,	0, SoldierPropsLocks.UpperFace.bChecked,		RABConf_UpperFacePropChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FaceDecorationLower,	0, SoldierPropsLocks.LowerFace.bChecked,		RABConf_LowerFacePropChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_Helmet,					0, SoldierPropsLocks.Helmet.bChecked,			RABConf_HatChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_ArmorPatterns,			0, SoldierPropsLocks.ArmorPattern.bChecked,		RABConf_ArmorPatternChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_WeaponPatterns,			0, SoldierPropsLocks.WeaponPattern.bChecked,	RABConf_WeaponPatternChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_Scars,					0, SoldierPropsLocks.Scars.bChecked,			RABConf_ScarsChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FacePaint,				0, SoldierPropsLocks.FacePaint.bChecked,		RABConf_FacePaintChance);

	/*
		I handle the tattoos as one field; could handle them individually as I do everything else, but this made
		more sense to me.

		Set the color (if there are no tattoos, no worries, it won't show up).
	*/
	RandomizeTrait(SoldierPropsLocks.TattoosColor.bChecked,			eUICustomizeCat_TattooColor,			-1);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_LeftArmTattoos,			0, SoldierPropsLocks.TattoosLeft.bChecked,		RABConf_TattoosChance);
	ResetAndConditionallyRandomizeTrait(eUICustomizeCat_RightArmTattoos,		0, SoldierPropsLocks.TattoosRight.bChecked,		RABConf_TattoosChance);
	
	/*
		Colors!
	*/
	if (RABConf_ForceDefaultColors)
	{
		RandomizeTrait(SoldierAttribLocks.HairColor.bChecked,		eUICustomizeCat_HairColor,				-1, false, EForceDefaultColorFlags.HairColors);
		RandomizeTrait(SoldierAttribLocks.MainColor.bChecked,		eUICustomizeCat_PrimaryArmorColor,		-1, false, EForceDefaultColorFlags.ArmorColors);
		RandomizeTrait(SoldierAttribLocks.SecondaryColor.bChecked,	eUICustomizeCat_SecondaryArmorColor,	-1, false, EForceDefaultColorFlags.ArmorColors);
		RandomizeTrait(SoldierAttribLocks.WeaponColor.bChecked,		eUICustomizeCat_WeaponColor,			-1, false, EForceDefaultColorFlags.WeaponColors);
		RandomizeTrait(SoldierAttribLocks.EyeColor.bChecked,		eUICustomizeCat_EyeColor,				-1, false, EForceDefaultColorFlags.EyeColors);
	}
	else
	{
		RandomizeTrait(SoldierAttribLocks.HairColor.bChecked,		eUICustomizeCat_HairColor,				-1);
		RandomizeTrait(SoldierAttribLocks.MainColor.bChecked,		eUICustomizeCat_PrimaryArmorColor,		-1);
		RandomizeTrait(SoldierAttribLocks.SecondaryColor.bChecked,	eUICustomizeCat_SecondaryArmorColor,	-1);
		RandomizeTrait(SoldierAttribLocks.WeaponColor.bChecked,		eUICustomizeCat_WeaponColor,			-1);
		RandomizeTrait(SoldierAttribLocks.EyeColor.bChecked,		eUICustomizeCat_EyeColor,				-1);
	}
}

simulated function ResetAndConditionallyRandomizeTrait(EUICustomizeCategory Trait, int Direction, bool bIsTraitLocked, float ChanceToRandomize)
{
	/*
		Reset the trait to 0 then, if we're supposed to randomize it, do so.
	*/

	SetTrait(0, Trait, Direction, bIsTraitLocked);
	if (RandomizeOrNotBasedOnRoll(ChanceToRandomize)) {
		RandomizeTrait(bIsTraitLocked, Trait, Direction);
	}
}

simulated function RandomizeTrait(bool bIsTraitLocked, EUICustomizeCategory eCategory, int Direction, 
									optional bool bTotallyRandom = false,
									optional EForceDefaultColorFlags eForceDefaultColor = NotForced)
{
	local array<string> options;
	local int			maxOptions;
	local int			maxRange;

	/*
		I don't know what int direction does (mostly for lack of trying) but it's the 2nd param
		for OnCategoryValue change and is different for colors (-1) from other parts (0).
	*/

	if (!bIsTraitLocked) {

		switch (Direction) {
			case 0:
				options = CustomizeMenuScreen.CustomizeManager.GetCategoryList(eCategory);
				maxOptions = options.Length;
				break;
			case -1:

				switch (eForceDefaultColor) {
					case NotForced:
						`log(" * COLOR FREE FOR ALL.");
						options = CustomizeMenuScreen.CustomizeManager.GetColorList(eCategory);
						maxOptions = options.Length;
						break;
					case ArmorColors:
						`log(" * USING DEFAULT ARMOR COLORS.");
						maxOptions = RABConf_DefaultArmorColors;
						break;
					case WeaponColors:
						`log(" * USING DEFAULT WEAPON COLORS.");
						maxOptions = RABConf_DefaultWeaponColors;
						break;
					case EyeColors:
						`log(" * USING DEFAULT EYE COLORS.");
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

		`log("--> number of options =" @ maxOptions);

		/*

			Here's the meat of the function: we pass a random value (within the determined range)
			to the customize manager via OnCategoryValueChange, which is actually a callback
			usually triggered by UI interaction, I think. (That's why I need to manually call
			UpdateCamera immediately after (with no args) otherwise the camera gets weird.

		*/

		CustomizeMenuScreen.CustomizeManager.OnCategoryValueChange(eCategory, Direction, `SYNC_RAND(maxOptions));
		CustomizeMenuScreen.CustomizeManager.UpdateCamera();
	} // endif (!bIsTraitLocked)
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

simulated function ForceTrait(int TraitIndex, EUICustomizeCategory eCategory, int Direction)
{
	CustomizeMenuScreen.CustomizeManager.OnCategoryValueChange(eCategory, direction, TraitIndex);
	CustomizeMenuScreen.CustomizeManager.UpdateCamera();
}

simulated function SetTrait(int TraitIndex, EUICustomizeCategory eCategory, int Direction, bool bIsTraitLocked)
{
	if (!bIsTraitLocked) {
		ForceTrait(TraitIndex, eCategory, Direction);
	}
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