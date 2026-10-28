using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Localization.Settings;

// Optional native mod. No file/network access. Logs unresolved Korean overflow.
// Only Button descendants get bounded auto-sizing; dialogue geometry is not changed.
public sealed class PSKoreanEnglishBaseMod : IMod
{
    private GameObject host;
    public void Init(ModManifest manifest) { }
    public void OnEnable()
    {
        if (host != null) return;
        host = new GameObject("PS Korean English Base");
        UnityEngine.Object.DontDestroyOnLoad(host);
        host.AddComponent<PSKoreanEnglishBaseRunner>();
    }
    public void OnDisable()
    {
        if (host != null) UnityEngine.Object.Destroy(host);
        PSEnglishKoreanFallback.Restore();
    }
}

public sealed class PSKoreanEnglishBaseRunner : MonoBehaviour
{
    private sealed class Original
    {
        public TMP_Text Text;
        public bool Auto;
        public float Size, Min, Max;
    }
    private readonly Dictionary<int, Original> originals = new Dictionary<int, Original>();
    private readonly Dictionary<int, int> reported = new Dictionary<int, int>();
    private IEnumerator Start()
    {
        while (true)
        {
            yield return new WaitForSecondsRealtime(0.75f);
            var locale = LocalizationSettings.SelectedLocale;
            if (locale == null || !(locale.Identifier.Code == "en" || locale.Identifier.Code.StartsWith("ko", StringComparison.OrdinalIgnoreCase)))
            {
                Restore();
                continue;
            }
            foreach (var text in Resources.FindObjectsOfTypeAll<TextMeshProUGUI>())
            {
                if (text == null || !text.isActiveAndEnabled || !text.gameObject.scene.IsValid() || !Hangul(text.text)) continue;
                var id = text.GetInstanceID();
                if (text.isTextOverflowing && text.GetComponentInParent<Button>() != null && !text.enableAutoSizing)
                {
                    if (!originals.ContainsKey(id)) originals[id] = new Original { Text = text, Auto = text.enableAutoSizing, Size = text.fontSize, Min = text.fontSizeMin, Max = text.fontSizeMax };
                    float size = originals[id].Size;
                    text.fontSizeMax = size;
                    text.fontSizeMin = size * 0.85f;
                    text.enableAutoSizing = true;
                }
                if (text.isTextOverflowing)
                {
                    int signature = (text.text ?? "").GetHashCode() ^ text.rectTransform.rect.GetHashCode();
                    int previous;
                    if (!reported.TryGetValue(id, out previous) || previous != signature)
                    {
                        reported[id] = signature;
                        Debug.LogWarning("[PSKO Overflow] " + Hierarchy(text.transform) + " | rect=" + text.rectTransform.rect.size + " | font=" + text.fontSize + " | text=" + text.text);
                    }
                }
                else reported.Remove(id);
            }
        }
    }
    private static bool Hangul(string value)
    {
        if (value == null) return false;
        foreach (char c in value) if ((c >= 0xAC00 && c <= 0xD7A3) || (c >= 0x3130 && c <= 0x318F)) return true;
        return false;
    }
    private static string Hierarchy(Transform t)
    {
        string path = t.name;
        while (t.parent != null) { t = t.parent; path = t.name + "/" + path; }
        return path;
    }
    private void Restore()
    {
        foreach (var state in originals.Values)
            if (state.Text != null)
            {
                state.Text.enableAutoSizing = state.Auto;
                state.Text.fontSize = state.Size;
                state.Text.fontSizeMin = state.Min;
                state.Text.fontSizeMax = state.Max;
            }
        originals.Clear(); reported.Clear();
    }
    private void OnDestroy() { Restore(); }
}
