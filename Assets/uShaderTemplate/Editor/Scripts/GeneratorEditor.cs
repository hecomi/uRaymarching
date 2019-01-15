using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;
using System.IO;

namespace uShaderTemplate
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

    SerializedProperty constants_;
    SerializedProperty constantsFolded_;

    SerializedProperty blocks_;
    Dictionary<string, ShaderCodeEditor> editors_ = new Dictionary<string, ShaderCodeEditor>();

    ShaderTemplateSelector template_;
    ShaderTemplateParser templateParser_;

    FileWatcher watcher_ = new FileWatcher();

    string errorMessage_;

    Dictionary<string, Func<string, string>> toConstFuncs_;
    bool constVarsFolded_ = false;

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
        constants_ = serializedObject.FindProperty("constants");
        constantsFolded_ = serializedObject.FindProperty("constantsFolded");

        template_ = new ShaderTemplateSelector(serializedObject.FindProperty("shaderTemplate"));
        template_.onChange.AddListener(OnTemplateChanged);

        watcher_.onChanged.AddListener(CheckShaderUpdate);
        if (hasShaderReference) {
            watcher_.Start(GetShaderPath());
        }

        CheckShaderUpdate();
    }

    void OnDisable()
    {
        if (template_ != null) {
            template_.onChange.RemoveListener(OnTemplateChanged);
        }
        if (watcher_ != null) {
            watcher_.Stop();
            watcher_.onChanged.RemoveListener(CheckShaderUpdate);
        }
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        watcher_.Update();

        HandleKeyEvents();

        if (templateParser_ == null) {
            OnTemplateChanged();
        }

        DrawBasics();
        DrawConditions();
        DrawVariables();
        DrawBlocks();
        DrawConstants();
        DrawMaterialReferences();

        EditorGUILayout.Separator();

        DrawButtons();
        DrawMessages();

        EditorGUILayout.Separator();

        serializedObject.ApplyModifiedProperties();
    }

    SerializedProperty FindProperty(SerializedProperty array, string key, string keyName = "key")
    {
        for (int i = 0; i < array.arraySize; ++i) {
            var prop = array.GetArrayElementAtIndex(i);
            var keyProp = prop.FindPropertyRelative(keyName);
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

    void DrawBasics()
    {
        basicFolded_.boolValue = Utils.Foldout("Basic", basicFolded_.boolValue);
        if (basicFolded_.boolValue) {
            ++EditorGUI.indentLevel;
            EditorGUILayout.PropertyField(name_);
            EditorGUILayout.PropertyField(shader_);
            template_.Draw();
            --EditorGUI.indentLevel;
        }
    }

    void DrawConditions()
    {
        if (templateParser_.conditions.Count == 0) {
            return;
        }

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
        if (templateParser_.variables.Count == 0) {
            return;
        }

        variablesFolded_.boolValue = Utils.Foldout("Variables", variablesFolded_.boolValue);
        if (!variablesFolded_.boolValue) return;

        ++EditorGUI.indentLevel;

        var constVars = new Dictionary<string, string>();

        foreach (var kv in templateParser_.variables) {
            var prop = FindProperty(variables_, kv.Key);
            if (prop == null) continue;
            var value = prop.FindPropertyRelative("value");

            var name = Utils.ToSpacedCamel(kv.Key);
            var constValue = ToConstVariable(kv.Key);
            string changedValue;

            if (constValue != null) {
                changedValue = constValue;
                constVars.Add(name, constValue);
            } else {
                if (kv.Value.Count <= 1) {
                    changedValue = EditorGUILayout.TextField(name, value.stringValue);
                } else {
                    var index = kv.Value.IndexOf(value.stringValue);
                    if (index == -1) index = 0;
                    index = EditorGUILayout.Popup(name, index, kv.Value.ToArray());
                    changedValue = kv.Value[index];
                }
            }

            if (value.stringValue != changedValue) {
                value.stringValue = changedValue;
            }
        }

        if (constVars.Count > 0) {
            constVarsFolded_ = EditorGUILayout.Foldout(constVarsFolded_, "Constants");
            if (constVarsFolded_) {
                ++EditorGUI.indentLevel;
                foreach (var kv in constVars) {
                    Utils.ReadOnlyTextField(kv.Key, kv.Value);
                }
                --EditorGUI.indentLevel;
            }
        }

        --EditorGUI.indentLevel;
    }

    void DrawConstants()
    {
        constantsFolded_.boolValue = Utils.Foldout("Constants", constantsFolded_.boolValue);
        if (!constantsFolded_.boolValue) return;

        ++EditorGUI.indentLevel;
        EditorGUILayout.BeginHorizontal(); 
        {
            EditorGUILayout.PropertyField(constants_);
            if (templateParser_ != null && templateParser_.constants) {
                var style = new GUIStyle(EditorStyles.miniButtonLeft);
                style.fixedWidth = 64;
                if (GUILayout.Button("Use Default", style)) {
                    constants_.objectReferenceValue = templateParser_.constants;
                }
            }
        } 
        EditorGUILayout.EndHorizontal();
        --EditorGUI.indentLevel;
    }

    void DrawMaterialReferences()
    {
        materialsFolded_.boolValue = Utils.Foldout("Material References", materialsFolded_.boolValue);
        if (!materialsFolded_.boolValue) return;

        ++EditorGUI.indentLevel;
        var materials = Utils.FindMaterialsUsingShader(shader_.objectReferenceValue as Shader);
        if (materials.Count > 0) {
            foreach (var material in materials) {
                EditorGUILayout.ObjectField(material, typeof(Material), false);
            }
        } else {
            EditorGUILayout.LabelField("No material using this shader.");
        }
        --EditorGUI.indentLevel;
    }

    void DrawButtons()
    {
        EditorGUILayout.BeginHorizontal();
        {
            var buttonFontSize = GUI.skin.label.fontSize;
            var buttonPadding = new RectOffset(12, 12, 6, 6);

            GUILayout.FlexibleSpace();
            var style = new GUIStyle(EditorStyles.miniButtonLeft);
            style.fontSize = buttonFontSize;
            style.padding = buttonPadding;
            if (GUILayout.Button("Export (Ctrl+R)", style)) {
                ExportShaderWithErrorCheck();
            }

            style = new GUIStyle(EditorStyles.miniButtonMid);
            style.fontSize = buttonFontSize;
            style.padding = buttonPadding;
            if (GUILayout.Button("Create Material", style)) {
                CreateMaterial();
            }

            style = new GUIStyle(EditorStyles.miniButtonMid);
            style.fontSize = buttonFontSize;
            style.padding = buttonPadding;
            if (GUILayout.Button("Reset to Default", style)) {
                ResetToDefault();
            }

            style = new GUIStyle(EditorStyles.miniButtonMid);
            style.fontSize = buttonFontSize;
            style.padding = buttonPadding;
            if (GUILayout.Button("Update Template", style)) {
                OnTemplateChanged();
            }

            style = new GUIStyle(EditorStyles.miniButtonRight);
            style.fontSize = buttonFontSize;
            style.padding = buttonPadding;
            if (GUILayout.Button("Reconvert All", style)) {
                ReconvertAll();
            }
        }
        EditorGUILayout.EndHorizontal();
    }

    void DrawMessages()
    {
        if (!string.IsNullOrEmpty(errorMessage_)) {
            EditorGUILayout.HelpBox(errorMessage_, MessageType.Error, true);
        }
    }

    string ToConstVariable(string name)
    {
        if (name == "Name") {
            return name_.stringValue;
        } else if (constants_ != null) {
            var constants = (Constants)constants_.objectReferenceValue;
            foreach (var kv in constants.values) {
                if (kv.name == name) return kv.value;
            }
        }
        return null;
    }

    void OnTemplateChanged()
    {
        templateParser_ = new ShaderTemplateParser(template_.text);

        constants_.objectReferenceValue = 
            templateParser_.constants ??
            Resources.Load<Constants>(Common.Setting.defaultConstants);

        foreach (var kv in templateParser_.conditions) {
            if (FindProperty(conditions_, kv.Key) != null) continue;
            var prop = AddProperty(conditions_, kv.Key);
            prop.FindPropertyRelative("key").stringValue = kv.Key;
            prop.FindPropertyRelative("value").boolValue = kv.Value;
        }

        foreach (var kv in templateParser_.blocks) {
            if (FindProperty(blocks_, kv.Key) != null) continue;
            var prop = AddProperty(blocks_, kv.Key);
            prop.FindPropertyRelative("key").stringValue = kv.Key;
            prop.FindPropertyRelative("value").stringValue = kv.Value;
            prop.FindPropertyRelative("folded").boolValue = false;
        }

        foreach (var kv in templateParser_.variables) {
            if (FindProperty(variables_, kv.Key) != null) continue;
            var prop = AddProperty(variables_, kv.Key);
            var hasDefaultValue = (kv.Value.Count >= 1);
            prop.FindPropertyRelative("key").stringValue = kv.Key;
            prop.FindPropertyRelative("value").stringValue = hasDefaultValue ? kv.Value[0] : "";
        }
    }

    string GetShaderName()
    {
        var name = name_.stringValue;
        if (string.IsNullOrEmpty(name)) {
            throw new System.Exception(string.Format("Shader name of \"{0}\" is empty.", target.name));
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

    void ExportShader()
    {
        var info = new ShaderTemplateConvertInfo();

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
            var constValue = ToConstVariable(kv.Key);
            if (constValue != null) {
                value.stringValue = constValue;
            }
            info.variables.Add(kv.Key, value.stringValue);
        }

        var code = templateParser_.Convert(info);

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

    void ExportShaderWithErrorCheck()
    {
        ClearError();

        var generator = target as Generator;
        generator.OnBeforeConvert();

        try {
            ExportShader();
        } catch (Exception e) {
            AddError(e.Message);
        }

        generator.OnAfterConvert();
    }

    void ResetToDefault()
    {
        blocks_.ClearArray();
        conditions_.ClearArray();
        variables_.ClearArray();
        OnTemplateChanged();
    }

    void ReconvertAll()
    {
        Debug.LogFormat("<color=blue>Reconvert started.\n------------------------------</color>"); 
        var generators = Utils.FindAllAssets<Generator>();
        foreach (var generator in generators) {
            try {
                if (target == generator) {
                    Debug.LogFormat("<color=green>{0}</color>", GetShaderPath());
                    OnTemplateChanged();
                    ExportShaderWithErrorCheck();
                } else {
                    var editor = Editor.CreateEditor(generator) as GeneratorEditor;
                    Debug.LogFormat("<color=green>{0}</color>", editor.GetShaderPath());
                    editor.CheckShaderUpdate();
                    editor.OnTemplateChanged();
                    editor.ExportShaderWithErrorCheck();
                }
            } catch (System.Exception e) {
                Debug.LogFormat("<color=red>Error: " + e.Message + "</color>"); 
            }
        }
        Debug.LogFormat("<color=blue>------------------------------\nReconvert finished.</color>"); 
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

    void CreateMaterial()
    {
        var material = new Material(shader_.objectReferenceValue as Shader);
        var path = string.Format("{0}/{1}.mat", GetOutputDirPath(), GetShaderName());
        ProjectWindowUtil.CreateAsset(material, path);
    }

    void HandleKeyEvents()
    {
        var e = Event.current;
        var isKeyPressing = e.type == EventType.KeyUp;
        if (isKeyPressing && e.control && e.keyCode == KeyCode.R) {
            ExportShaderWithErrorCheck();
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