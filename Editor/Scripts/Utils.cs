using UnityEngine;
using UnityEditor;
using System.IO;

namespace Raymarching
{

public static class Utils
{
    public static string GetShaderDirPath(string shaderName)
    {
        var shader = Shader.Find(shaderName);
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