using Raymarching.ColorScheme;

namespace Raymarching
{

namespace Common
{

public static class Color
{ 
    public static string background = Solarized.base03;
    public static string color = "#ffffff";
    public static string type = Solarized.yellow;
    public static string keyword = Solarized.green;
    public static string symbol = Solarized.base1;
    public static string digit = Solarized.violet;
    public static string str = Solarized.violet;
    public static string comment = Solarized.base01;
    public static string cgprogram = Solarized.blue;
    public static string raymarching = Solarized.cyan;
    public static string entrypoint = Solarized.orange;
    public static string unity = Solarized.magenta;
}

public static class Editor
{
    public static string font = "Raymarching/Font/NotoMono-regular";
    public static int fontSize = 12;
    public static bool wordWrap = false;
    public static int minHeight = 200;
}

}

}