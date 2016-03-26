
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
			return 1000;
	}
}

simulated static function string CategoryName(EUICustomizeCategory eCategory)
{
	local string strPropName;

	strPropName = string(eCategory);
	strPropName = Repl(strPropName, "eUICustomizeCat_", "", true);

	return strPropName;
}

simulated static function ResetTheCamera(UICustomize_Menu Screen)
{
	/*
		Calling this with no args helps correct the camera, which
		becomes weird (locked, zoomed) otherwise.
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