using UnityEngine;
using UnityEditor;

namespace uShaderTemplate
{

public class CodeEditor
{
    public string controlName { get; set; }
    public Color backgroundColor { get; set; }
    public Color textColor { get; set; }

    string cachedCode { get; set; }
    string cachedHighlightedCode { get; set; }
    public System.Func<string, string> highlighter { get; set; }

    public bool isFocused 
    {
        get { return GUI.GetNameOfFocusedControl() == controlName; }
    }

    public CodeEditor(string controlName)
    {
        this.controlName = controlName;
        backgroundColor = Color.black;
        textColor = Color.white;
        highlighter = code => code;
    }

    public string Draw(string code, GUIStyle style, params GUILayoutOption[] options)
    {
        var preBackgroundColor = GUI.backgroundColor;
        var preColor = GUI.color;

        GUI.backgroundColor = backgroundColor;
        GUI.color = textColor;

        var backStyle = new GUIStyle(style);
        backStyle.normal.textColor = Color.clear;
        backStyle.hover.textColor = Color.clear;
        backStyle.active.textColor = Color.clear;
        backStyle.focused.textColor = Color.clear;

        GUI.SetNextControlName(controlName);

        // IMPORTANT: 
        // Sadly, we cannot use TextEditor with (EditorGUILayout|EditorGUI).TextArea()... X(
        // And GUILayout.TextArea() cannot handle TAB key... ;_;
        // GUI.TextArea needs a lot of tasks to implement basic functions... T_T
        var editedCode = EditorGUILayout.TextArea(code, backStyle, options);

        // So, this does not work...
        // var editor = GUIUtility.GetStateObject(typeof(TextEditor), GUIUtility.keyboardControl) as TextEditor;
        // CheckEvents(editor);

        if (editedCode != code) {
            code = editedCode;
        }

        if (string.IsNullOrEmpty(cachedHighlightedCode) || (cachedCode != code)) {
            cachedCode = code;
            cachedHighlightedCode = highlighter(code);
        }

        GUI.backgroundColor = Color.clear;

        var foreStyle = new GUIStyle(style);
        foreStyle.richText = true;
        foreStyle.normal.textColor = textColor;
        foreStyle.hover.textColor = textColor;
        foreStyle.active.textColor = textColor;
        foreStyle.focused.textColor = textColor;

        EditorGUI.TextArea(GUILayoutUtility.GetLastRect(), cachedHighlightedCode, foreStyle);

        GUI.backgroundColor = preBackgroundColor;
        GUI.color = preColor;

        return code;
    }

    void CheckEvents(TextEditor editor)
    {
        // ...
    }
}

}