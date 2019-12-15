using UnityEngine;
using UnityEditor;
using System.IO;

namespace Raymarching
{

public static class Utils
{
    public static string GetLegacyShaderIncludeDirPath()
    {
        var shader = Shader.Find("Hidden/Raymarching/GetPathFromScript");
        var shaderPath = AssetDatabase.GetAssetPath(shader);
        try
        {
            return Path.GetDirectoryName(shaderPath);
        }
        catch (System.Exception)
        {
            return "";
        }
    }
}

}