using HarmonyLib;
using TMPro;
using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.Localization.Settings;

// The game's own native mod loader calls Harmony.PatchAll for this assembly.
// Requires the supplied source-font overlay to obtain static 500-weight UI font.
[HarmonyPatch(typeof(FontLoader), "GetFontByRole")]
public static class PSEnglishKoreanFontRouting
{
    public static void Postfix(FontLoader __instance, FontLoader.FontRole role, Locale locale, ref TMP_FontAsset __result)
    {
        if (locale == null || locale.Identifier.Code != "en") return;
        TMP_FontAsset font;
        switch (role)
        {
            case FontLoader.FontRole.Caveat:
                font = __instance.koreanHandwrittenFont;
                break;
            case FontLoader.FontRole.Tektur:
            case FontLoader.FontRole.Tektur_Bold:
            case FontLoader.FontRole.Lubrifont:
            case FontLoader.FontRole.Rubik:
                font = __instance.koreanScifiFont;
                break;
            default:
                font = __instance.koreanFont;
                break;
        }
        if (font != null) __result = font;
    }
}

// The original game uses 0.35 for KO/JA/ZH. EN-base Korean needs that same pace.
[HarmonyPatch(typeof(StoreUIManager), "GetLocaleSpeedMultiplier")]
public static class PSEnglishKoreanTypewriterPace
{
    public static void Postfix(ref float __result)
    {
        var locale = LocalizationSettings.SelectedLocale;
        if (locale != null && locale.Identifier.Code == "en") __result = 0.35f;
    }
}

// Supplies Korean fallback for dynamic and third-party TMP widgets too.
[HarmonyPatch(typeof(FontLoader), "Awake")]
public static class PSEnglishKoreanFallback
{
    private static TMP_FontAsset added;
    public static void Postfix(FontLoader __instance)
    {
        var font = __instance.koreanFont;
        var fallback = TMP_Settings.fallbackFontAssets;
        if (font != null && fallback != null && !fallback.Contains(font))
        {
            fallback.Add(font);
            added = font;
        }
    }
    public static void Restore()
    {
        var fallback = TMP_Settings.fallbackFontAssets;
        if (added != null && fallback != null) fallback.Remove(added);
        added = null;
    }
}
