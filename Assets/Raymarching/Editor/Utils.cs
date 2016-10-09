using UnityEngine;
using UnityEditor;
using System.IO;
using System.Collections.Generic;

namespace Raymarching
{

public static class Utils
{
    public static string GetShaderTemplateDirPathInResourcesDir()
    {
        return "Raymarching/ShaderTemplates";
    }

    public static string GetCgincDirPath()
    {
        var shader = Shader.Find("Hidden/Raymarching/GetPathFromScript");
        var path = AssetDatabase.GetAssetPath(shader);
        return Path.GetDirectoryName(path);
    }

    public static string GetShaderTemplateDirPath()
    {
        var dir = GetShaderTemplateDirPathInResourcesDir();
        var file = Resources.Load<TextAsset>(dir + "/_Get_Path_From_Script_");
        var path = AssetDatabase.GetAssetPath(file);
        return Path.GetDirectoryName(path);
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

    public static List<Material> FindMaterialsUsingShader(Shader shader)
    {
        var materials = new List<Material>();
        var allMaterials = Resources.FindObjectsOfTypeAll<Material>();
        foreach (var material in allMaterials) {
            if (material.shader == shader) {
                materials.Add(material);
            }
        }
        return materials;
    }

    public static List<T> FindAllAssets<T>() where T : Object
    {
        var list = new List<T>();
        var guids = AssetDatabase.FindAssets("t:" + typeof(T));
        foreach (var guid in guids) {
            var path = AssetDatabase.GUIDToAssetPath(guid);
            var obj = AssetDatabase.LoadAssetAtPath<T>(path);
            if (obj) list.Add(obj);
        }
        return list;
    }
}

}