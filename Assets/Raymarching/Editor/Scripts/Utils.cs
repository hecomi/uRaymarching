using UnityEngine;
using UnityEditor;
using System.IO;

namespace Raymarching
{

public static class Utils
{
    public static string GetCgincDirPath()
    {
        var shader = Shader.Find("Hidden/Raymarching/GetPathFromScript");
        var path = AssetDatabase.GetAssetPath(shader);
        return Path.GetDirectoryName(path);
    }
}

}