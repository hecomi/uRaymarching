using uShaderTemplate.ColorScheme;

namespace uShaderTemplate
{

namespace Common
{

public static class Color
{ 
    public const string background = Solarized.base03;
    public const string color = "#ffffff";
    public const string type = Solarized.yellow;
    public const string keyword = Solarized.green;
    public const string symbol = Solarized.base1;
    public const string digit = Solarized.violet;
    public const string str = Solarized.violet;
    public const string comment = Solarized.base01;
    public const string cgprogram = Solarized.blue;
    public const string unity = Solarized.magenta;
    public const string user1 = Solarized.orange;
    public const string user2 = Solarized.cyan;
}

public static class Editor
{
    public const string font = "uShaderTemplate/Font/NotoMono-regular";
    public const int fontSize = 12;
    public const bool wordWrap = false;
    public const int height = 200;
}

public static class Setting
{
    public const int menuOrder = 1000;
    public const string menuPlace = "Shader/uShaderTemplate/";
    public const string defaultConstants = "uShaderTemplate/Constants/Default Constants";
    public const string templateDirectoryPath = "ShaderTemplates";
    public const string templateFileExtension = ".txt";
}

}

}