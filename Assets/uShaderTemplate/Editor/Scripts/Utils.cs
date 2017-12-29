using UnityEngine;
using UnityEngine.Assertions;
using UnityEditor;
using System.IO;
using System.Collections.Generic;

namespace uShaderTemplate
{

public static class Utils
{
    public static HashSet<string> GetShaderTemplatePathList()
    {
        var files = Resources.LoadAll<TextAsset>(Common.Setting.templateDirectoryPath);
        var list = new HashSet<string>();
        foreach (var file in files) {
            var path = AssetDatabase.GetAssetPath(file);
            list.Add(path);
        }
        return list;
    }

    public static bool Foldout(string title, bool display)
    {
        var style = new GUIStyle("ShurikenModuleTitle");
        style.font = new GUIStyle(EditorStyles.label).font;
        style.border = new RectOffset(15, 7, 4, 4);
        style.fixedHeight = 22;
        style.contentOffset = new Vector2(20f, -2f);

        var rect = GUILayoutUtility.GetRect(16f, 22f, style);
        GUI.Box(rect, title, style);

        var e = Event.current;

        var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
        if (e.type == EventType.Repaint) {
            EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
        }
        
        if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition)) {
            display = !display;
            e.Use();
        }

        return display;
    }

    public static string ToSpacedCamel(string str)
    {
        return System.Text.RegularExpressions.Regex.Replace(str, @"([A-Z][^A-Z]+)", @"$1 ");
    }

    public static void ReadOnlyTextField(string label, string text)
    {
        EditorGUILayout.BeginHorizontal();
        {
            EditorGUILayout.LabelField(label, GUILayout.Width(EditorGUIUtility.labelWidth - 4));
            EditorGUILayout.SelectableLabel(text, EditorStyles.textField, GUILayout.Height(EditorGUIUtility.singleLineHeight));
        }
        EditorGUILayout.EndHorizontal();
    }

    public static List<T> FindAllAssets<T>(string query) where T : Object
    {
        var list = new List<T>();
        var guids = AssetDatabase.FindAssets(query);
        foreach (var guid in guids) {
            var path = AssetDatabase.GUIDToAssetPath(guid);
            var obj = AssetDatabase.LoadAssetAtPath<T>(path);
            if (obj) list.Add(obj);
        }
        return list;
    }

    public static List<T> FindAllAssets<T>() where T : Object
    {
        return FindAllAssets<T>("t:" + typeof(T));
    }

    public static List<Material> FindMaterialsUsingShader(Shader shader)
    {
        var materials = new List<Material>();
        var allMaterials = FindAllAssets<Material>("t:Material");
        foreach (var material in allMaterials) {
            if (material.shader == shader) {
                materials.Add(material);
            }
        }
        return materials;
    }
}

}