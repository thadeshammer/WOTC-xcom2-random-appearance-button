
class RandomAppearanceButton_Utilities extends Object;

enum ECategoryType {

	/*
		Means I don't need to replicate various versions of that switch
		statement everywhere. See GetCategoryType() below.
	*/

	eCategoryType_Prop,
	eCategoryType_Color,
	eCategoryType_Gender,
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
				Gender often requires special handling so it's treated like the
				special snowflake that it is.
			*/
			case eUICustomizeCat_Gender:
				return eCategoryType_Gender;
				break;

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
