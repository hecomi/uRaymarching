using UnityEditor;

namespace uRaymarching
{

public class GeneratorAssetImportProcessor : AssetPostprocessor 
{
    const string ext = ".asset";
    const string dir = "uRaymarching";

    static void OnPostprocessAllAssets(
        string[] importedAssets, 
        string[] deletedAssets, 
        string[] movedAssets, 
        string[] movedFromAssetPaths)
    {
        foreach (string str in importedAssets) {
            if (!str.EndsWith(ext) || !str.Contains(dir)) continue;

            var generator = AssetDatabase.LoadAssetAtPath<uShaderTemplate.Generator>(str);
            if (!generator) continue;

            var editor = Editor.CreateEditor(generator) as uShaderTemplate.GeneratorEditor;
            editor.Reconvert();
        }
    }
}

}
