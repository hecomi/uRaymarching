using UnityEngine;
using UnityEditor;

namespace Raymarching
{

public class ShaderCodeEditor
{
    public string name { get; private set; }
    public SerializedProperty value { get; private set; }
    public SerializedProperty folded { get; private set; }

    CodeEditor editor_;
    Vector2 scrollPos_;
    Font font_;

    public string code
    {
        get { return value != null ? value.stringValue : ""; }
        private set { this.value.stringValue = value; }
    }

    public ShaderCodeEditor(string name, SerializedProperty value, SerializedProperty folded)
    {
        this.name = name;
        this.value = value;
        this.folded = folded;

        font_ = Resources.Load<Font>(Common.Editor.font);

        Color color, bgColor;
        ColorUtility.TryParseHtmlString(Common.Color.background, out bgColor);
        ColorUtility.TryParseHtmlString(Common.Color.color, out color);

        editor_ = new CodeEditor(name);
        editor_.backgroundColor = bgColor;
        editor_.textColor = color;
        editor_.highlighter = ShaderSyntax.Highlight;
    }

    public void Draw()
    {
        GUI.SetNextControlName(name + "_fold");
        folded.boolValue = Utils.Foldout(name, folded.boolValue);
        if (!folded.boolValue) {
            if (editor_.isFocused) {
                GUI.FocusControl(name + "_fold");
            }
            return;
        }

        scrollPos_ = EditorGUILayout.BeginScrollView(scrollPos_, GUILayout.MinHeight(Common.Editor.minHeight), GUILayout.MaxHeight(Screen.height));
        {
            var style = new GUIStyle(GUI.skin.textArea);
            style.padding = new RectOffset(6, 6, 6, 6);
            style.font = font_;
            style.fontSize = Common.Editor.fontSize;
            style.wordWrap = Common.Editor.wordWrap;

            var editedCode = editor_.Draw(code, style, GUILayout.ExpandHeight(true));

            if (editedCode != code) {
                code = editedCode;
            }
        }
        EditorGUILayout.EndScrollView();

        EditorGUILayout.Space();
    }
}

}