using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Raymarching
{

[CustomEditor(typeof(Generator))]
public class GeneratorEditor : Editor
{
    SerializedProperty name_;
    SerializedProperty shader_;

    SerializedProperty basicFolded_;
    SerializedProperty materialsFolded_;

    SerializedProperty conditions_;
    SerializedProperty conditionsFolded_;

    SerializedProperty variables_;
    SerializedProperty variablesFolded_;

    SerializedProperty blocks_;
    Dictionary<string, ShaderCodeEditor> editors_ = new Dictionary<string, ShaderCodeEditor>();

    ShaderTemplateSelector template_;
    ShaderTemplateParser templateParser_;

    FileWatcher watcher_ = new FileWatcher();

    string errorMessage_;

    bool hasShaderReference
    {
        get { return shader_.objectReferenceValue != null; }
    }

    void OnEnable()
    {
        name_ = serializedObject.FindProperty("shaderName");
        shader_ = serializedObject.FindProperty("shaderReference");
        variables_ = serializedObject.FindProperty("variables");
        variablesFolded_ = serializedObject.FindProperty("variablesFolded");
        conditions_ = serializedObject.FindProperty("conditions");
        conditionsFolded_ = serializedObject.FindProperty("conditionsFolded");
        blocks_ = serializedObject.FindProperty("blocks");
        basicFolded_ = serializedObject.FindProperty("basicFolded");
        materialsFolded_ = serializedObject.FindProperty("materialsFolded");

        template_ = new ShaderTemplateSelector(serializedObject.FindProperty("shaderTemplate"));
        template_.onChange += OnTemplateChanged;

        watcher_.onChange += CheckShaderUpdate;
        if (hasShaderReference) {
            watcher_.Start(GetShaderPath());
        }

        CheckShaderUpdate();
    }

    void OnDisable()
    {
        template_.onChange -= OnTemplateChanged;
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        watcher_.Update();

        HandleKeyEvents();

        if (templateParser_ == null) {
            OnTemplateChanged();
        }

        basicFolded_.boolValue = Utils.Foldout("Basic", basicFolded_.boolValue);
        if (basicFolded_.boolValue) {
            ++EditorGUI.indentLevel;
            EditorGUILayout.PropertyField(name_);
            EditorGUILayout.PropertyField(shader_);
            template_.Draw();
            --EditorGUI.indentLevel;
        }

        DrawConditions();
        DrawBlocks();
        DrawVariables();

        materialsFolded_.boolValue = Utils.Foldout("Material References", materialsFolded_.boolValue);
        if (materialsFolded_.boolValue) {
            ++EditorGUI.indentLevel;
            var materials = Utils.FindMaterialsUsingShader(shader_.objectReferenceValue as Shader);
            foreach (var material in materials) {
                EditorGUILayout.ObjectField(material, typeof(Material), false);
            }
            --EditorGUI.indentLevel;
        }

        EditorGUILayout.BeginHorizontal();
        {
            var buttonFontSize = GUI.skin.label.fontSize;
            var buttonPadding = new RectOffset(24, 24, 6, 6);

            GUILayout.FlexibleSpace();
            var style = new GUIStyle(EditorStyles.miniButtonLeft);
            style.fontSize = buttonFontSize;
            style.padding = buttonPadding;
            if (GUILayout.Button("Export (Ctrl+R)", style)) {
                ClearError();
                try {
                    GenerateShader();
                } catch (System.Exception e) {
                    AddError(e.Message);
                }
            }

            style = new GUIStyle(EditorStyles.miniButtonRight);
            style.fontSize = buttonFontSize;
            style.padding = buttonPadding;
            if (GUILayout.Button("Update Template", style)) {
                OnTemplateChanged();
            }
        }
        EditorGUILayout.EndHorizontal();

        if (!string.IsNullOrEmpty(errorMessage_)) {
            EditorGUILayout.HelpBox(errorMessage_, MessageType.Error, true);
        }

        serializedObject.ApplyModifiedProperties();
    }

    SerializedProperty FindProperty(SerializedProperty array, string key)
    {
        for (int i = 0; i < array.arraySize; ++i) {
            var prop = array.GetArrayElementAtIndex(i);
            var keyProp = prop.FindPropertyRelative("key");
            if (keyProp.stringValue == key) {
                return prop;
            }
        }

        return null;
    }

    SerializedProperty AddProperty(SerializedProperty array, string key)
    {
        var prop = FindProperty(array, key);
        if (prop != null) return prop;

        var index = array.arraySize;
        array.InsertArrayElementAtIndex(index);
        return array.GetArrayElementAtIndex(index);
    }

    void DrawConditions()
    {
        conditionsFolded_.boolValue = Utils.Foldout("Conditions", conditionsFolded_.boolValue);
        if (!conditionsFolded_.boolValue) return;

        ++EditorGUI.indentLevel;

        foreach (var kv in templateParser_.conditions) {
            var prop = FindProperty(conditions_, kv.Key);
            var value = prop.FindPropertyRelative("value");
            var name = Utils.ToSpacedCamel(kv.Key);

            var isSelected = EditorGUILayout.Toggle(name, value.boolValue);
            if (value.boolValue != isSelected) {
                value.boolValue = isSelected;
            }
        }

        --EditorGUI.indentLevel;
    }

    void DrawBlocks()
    {
        foreach (var kv in templateParser_.blocks) {
            var prop = FindProperty(blocks_, kv.Key);
            var value = prop.FindPropertyRelative("value");
            var folded = prop.FindPropertyRelative("folded");

            var name = Utils.ToSpacedCamel(kv.Key);
            ShaderCodeEditor editor = null;

            if (editors_.ContainsKey(name)) {
                editor = editors_[name];
            } else {
                editor = new ShaderCodeEditor(name, value, folded);
                editors_.Add(name, editor);
            }

            editor.Draw();
        }
    }

    void DrawVariables()
    {
        variablesFolded_.boolValue = Utils.Foldout("Variables", variablesFolded_.boolValue);
        if (!variablesFolded_.boolValue) return;

        ++EditorGUI.indentLevel;

        foreach (var kv in templateParser_.variables) {
            var prop = FindProperty(variables_, kv.Key);
            if (prop == null) continue;
            var value = prop.FindPropertyRelative("value");

            var name = Utils.ToSpacedCamel(kv.Key);
            var constValue = ToConstVariable(kv.Key);

            if (constValue == null) {
                string changedValue;
                if (kv.Value.Count <= 1) {
                    changedValue = EditorGUILayout.TextField(name, value.stringValue);
                } else {
                    var index = kv.Value.IndexOf(value.stringValue);
                    if (index == -1) index = 0;
                    index = EditorGUILayout.Popup(name, index, kv.Value.ToArray());
                    changedValue = kv.Value[index];
                }
                if (value.stringValue != changedValue) {
                    value.stringValue = changedValue;
                }
            } else {
                value.stringValue = constValue;
                Utils.ReadOnlyTextField("(Const) " + name, constValue);
            }
        }

        --EditorGUI.indentLevel;
    }

    string ToConstVariable(string name)
    {
        switch (name) {
            case "Name": 
                return name_.stringValue;
            case "RaymarchingShaderDirectory": 
                return Utils.GetCgincDirPath();
        }
        return null;
    }

    void OnTemplateChanged()
    {
        templateParser_ = new ShaderTemplateParser(template_.text);

        foreach (var kv in templateParser_.conditions) {
            if (FindProperty(conditions_, kv.Key) == null) {
                var prop = AddProperty(conditions_, kv.Key);
                var key = prop.FindPropertyRelative("key");
                var value = prop.FindPropertyRelative("value");
                key.stringValue = kv.Key;
                value.boolValue = kv.Value;
            }
        }

        foreach (var kv in templateParser_.blocks) {
            if (FindProperty(blocks_, kv.Key) == null) {
                var prop = AddProperty(blocks_, kv.Key);
                var key = prop.FindPropertyRelative("key");
                var value = prop.FindPropertyRelative("value");
                var folded = prop.FindPropertyRelative("folded");
                key.stringValue = kv.Key;
                value.stringValue = kv.Value;
                folded.boolValue = true;
            }
        }

        foreach (var kv in templateParser_.variables) {
            if (FindProperty(variables_, kv.Key) == null) {
                var prop = AddProperty(variables_, kv.Key);
                var key = prop.FindPropertyRelative("key");
                var value = prop.FindPropertyRelative("value");
                key.stringValue = kv.Key;
                value.stringValue = kv.Value.Count >= 1 ? kv.Value[0] : "";
            }
        }
    }

    string GetShaderName()
    {
        var name = name_.stringValue;
        if (string.IsNullOrEmpty(name)) {
            throw new System.Exception("Shader name is empty.");
        }
        return name_.stringValue;
    }

    string GetOutputDirPath()
    {
        if (hasShaderReference) {
            return Path.GetDirectoryName(AssetDatabase.GetAssetPath(shader_.objectReferenceValue));
        }
        return Path.GetDirectoryName(AssetDatabase.GetAssetPath(target));
    }

    string GetShaderPath()
    {
        return string.Format("{0}/{1}.shader", GetOutputDirPath(), GetShaderName());
    }

    void ReImport()
    {
        var outputPath = GetShaderPath();
        AssetDatabase.ImportAsset(outputPath);
        shader_.objectReferenceValue = AssetDatabase.LoadAssetAtPath<Shader>(outputPath);
    }

    void GenerateShader()
    {
        ShaderTemplateConvertInfo info = new ShaderTemplateConvertInfo();

        foreach (var kv in templateParser_.conditions) {
            var prop = FindProperty(conditions_, kv.Key);
            var value = prop.FindPropertyRelative("value");
            info.conditions.Add(kv.Key, value.boolValue);
        }
        foreach (var kv in templateParser_.blocks) {
            var prop = FindProperty(blocks_, kv.Key);
            var value = prop.FindPropertyRelative("value");
            info.blocks.Add(kv.Key, value.stringValue);
        }
        foreach (var kv in templateParser_.variables) {
            var prop = FindProperty(variables_, kv.Key);
            var value = prop.FindPropertyRelative("value");
            info.variables.Add(kv.Key, value.stringValue);
        }

        var code = templateParser_.Convert(info);
        code = code.Replace("\r\n", "\n");

        // rename if generator has a shader reference.
        if (hasShaderReference) {
            var shaderFilePath = AssetDatabase.GetAssetPath(shader_.objectReferenceValue);
            var shaderFileName = Path.GetFileNameWithoutExtension(shaderFilePath);
            var newFilePath = GetShaderPath();

            if (GetShaderName() != shaderFileName) {
                if (File.Exists(newFilePath)) {
                    throw new System.Exception(
                        string.Format("attempted to rename {0} to {1}, but target file existed.",
                            shaderFilePath, newFilePath));
                }
                AssetDatabase.RenameAsset(shaderFilePath, GetShaderName());
            }
        }

        using (var writer = new StreamWriter(GetShaderPath())) {
            writer.Write(code);
        }

        ReImport();

        if (hasShaderReference) {
            watcher_.Start(GetShaderPath());
        }
    }

    void CheckShaderUpdate()
    {
        if (!hasShaderReference) return;

        ClearError();
        try {
            var shaderPath = GetShaderPath();
            using (var reader = new StreamReader(shaderPath)) {
                var code = reader.ReadToEnd();
                var parser = new ShaderTemplateParser(code);
                foreach (var kv in parser.blocks) {
                    var prop = FindProperty(blocks_, kv.Key);
                    if (prop != null) {
                        var value = prop.FindPropertyRelative("value");
                        value.stringValue = kv.Value;
                    }
                }
            }
        } catch (System.Exception e) {
            AddError(e.Message);
        }
    }

    void HandleKeyEvents()
    {
        var e = Event.current;
        var isKeyPressing = e.type == EventType.Layout; // not KeyDown
        if (isKeyPressing && e.control && e.keyCode == KeyCode.R) {
            GenerateShader();
        }
    }

    void ClearError()
    {
        errorMessage_ = "";
    }

    void AddError(string error)
    {
        if (!string.IsNullOrEmpty(errorMessage_)) {
            errorMessage_ += "\n";
        }
        errorMessage_ += error;
    }
}

}