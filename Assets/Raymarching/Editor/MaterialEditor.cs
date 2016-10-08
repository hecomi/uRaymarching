using UnityEngine;
using UnityEditor;

namespace Raymarching
{

public class MaterialEditor : ShaderGUI
{
    bool folded_ = true;
    Editor cachedEditor_;

    override public void OnGUI(
        UnityEditor.MaterialEditor materialEditor, 
        MaterialProperty[] properties)
	{
        if (!cachedEditor_) {
            var material = materialEditor.target as Material;
            var shader = material.shader;
            var generators = Resources.FindObjectsOfTypeAll<Generator>();
            Generator targetGenerator = null;
            foreach (var generator in generators) {
                if (generator.shaderReference == shader) {
                    targetGenerator = generator;
                    break;
                }
            }
            if (targetGenerator) {
                cachedEditor_ = Editor.CreateEditor(targetGenerator);
            }
        }

        if (cachedEditor_) {
            cachedEditor_.OnInspectorGUI();
            EditorGUILayout.Space();
        }

        folded_ = Utils.Foldout("Material Properties", folded_);
        if (folded_) {
            ++EditorGUI.indentLevel;
            base.OnGUI(materialEditor, properties);
            --EditorGUI.indentLevel;
        }

	}
}

}