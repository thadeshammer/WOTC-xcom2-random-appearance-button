
/*
	static (non-instanced) helper functions
*/

class RandomAppearanceButton_Utilities extends Object;

enum ECategoryType {

	/*
		Means I don't need to replicate various versions of that switch
		statement everywhere. See GetCategoryType() below.
	*/

	eCategoryType_Prop,
	eCategoryType_Color,
	eCategoryType_Special,
	eCategoryType_DLC_1,
	eCategoryType_IGNORE,
	eCategoryType_UNKNOWN
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

simulated static function ECategoryType GetCategoryType(const out int iCategoryIndex)
{
	/*
		This makes a LOT of required switch statements throughout the code
		much easier to read.
	*/

	switch (iCategoryIndex)
		{
			/*
				These special snowflakes require special handling or setting
				attributes/props on undo actions won't work as you'd expect.

				Gender first, then Race, than anything else.
			*/
			case eUICustomizeCat_Gender:
			case eUICustomizeCat_Race:
				return eCategoryType_Special;
				break;

			/*
				Non-color appearance props and attributes require a "Direction"
				of 0. I'm not clear on why but that's how they're handled.
			*/
			case eUICustomizeCat_Face:
			case eUICustomizeCat_Hairstyle:			
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
				return eCategoryType_Prop;
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
				return eCategoryType_Color;
				break;

			/*
				DLC_1 (Anarchy's Children) adds new deco elements that without
				special handling will cause weird clashes with the core arms.
			*/
			case eUICustomizeCat_LeftArmDeco:
			case eUICustomizeCat_RightArmDeco:
			case eUICustomizeCat_LeftArm:
			case eUICustomizeCat_RightArm:
				return eCategoryType_DLC_1;
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
			case eUICustomizeCat_Class:
			case eUICustomizeCat_AllowTypeSoldier:
			case eUICustomizeCat_AllowTypeVIP:
			case eUICustomizeCat_AllowTypeDarkVIP:
			case eUICustomizeCat_DEV1:
			case eUICustomizeCat_DEV2:
				return eCategoryType_IGNORE;
				break;

			default:
				return eCategoryType_UNKNOWN;
				break;
		}
}

simulated static function int PropDirection(ECategoryType eCatType)
{
	/*
		I still have no idea why OnCategoryValueChange() (the callback the UI uses
		to change traits) requires "Direction" nor what "Direction" means or does.

		Colors need a Direction of -1.

		Non-color attributes need a Direction of 0.

		It's 0 *most of the time* which is why the default option returns 0. Probably
		this should throw an exception, but that's well outside of my abilities here.
	*/

	switch (eCatType) {
		case eCategoryType_Prop:
		case eCategoryType_Special:
		case eCategoryType_DLC_1:
			return 0;
			break;

		case eCategoryType_Color:
			return -1;
			break;

		default:
			return 0;
	}
}

simulated static function string CategoryName(EUICustomizeCategory eCategory)
{
	/*
		A helper function to make logging more readable. Takes a EUICustomizeCategory
		enum and returns a shorter version by removing the prefix and leaving the
		meaningful part.

		E.G. "eUICustomizeCat_Torso" becomes "Torso"
	*/

	local string strPropName;

	strPropName = string(eCategory);
	strPropName = Repl(strPropName, "eUICustomizeCat_", "", true);

	return strPropName;
}

simulated static function bool SoldierHasDLC1Torso(UICustomize_Menu CustomizeMenuScreen)
{
	local XComGameState_Unit	Unit;
	local string				strTorsoName;

	 Unit = CustomizeMenuScreen.Movie.Pres.GetCustomizationUnit();

	 /*
		Currently it appears that all of the DLC_1's special
		torsos have (UE3) Names with the prefix 'DLC_30'.
		Not sure why it's not 'DLC_1' like everything else,
		but if it's as consistent as it appears, we're in
		business.
	 */

	 `log("UTIL: nmTorso ==" @ Unit.kAppearance.nmTorso);

	 strTorsoName = string(Unit.kAppearance.nmTorso);

	 if ( InStr(strTorsoName, "DLC_30") != -1 ) {
		`log("UTIL: IS DLC_1 TORSO.");
		return true;
	} else {
		`log("UTIL: IS NOT DLC_1 TORSO.");
		return false;
	}
}

simulated static function bool SoldierHasDLC1Arms(UICustomize_Menu CustomizeMenuScreen)
{
	local XComGameState_Unit Unit;

	 Unit = CustomizeMenuScreen.Movie.Pres.GetCustomizationUnit();

	 /*
		As of the DLC_1 release, the only thing that LEGIT results in the
		arms (button label) name being empty is if one of the DLC_1 arm
		items has been slotted. This may not remain sufficient.
	 */

	 `log("UTIL: nmArms ==" @ Unit.kAppearance.nmArms);

	 if (Unit.kAppearance.nmArms == '') {
		`log("UTIL: ARE DLC_1 ARMS.");
		return true;
	} else {
		`log("UTIL: ARE NOT DLC_1 ARMS.");
		return false;
	}
}

simulated static function ResetTheCamera(UICustomize_Menu Screen)
{
	/*
		Calling this with no args helps correct the camera, which
		becomes weird (locked, zoomed) when I make changes and
		don't call this.
	*/

	Screen.CustomizeManager.UpdateCamera();
}

simulated static function UpdateScreenData(UICustomize_Menu Screen)
{
	/*
		Calling this is necessary to cement certain changes, like
		changes to soldier gender.
	*/

	Screen.UpdateData();
}