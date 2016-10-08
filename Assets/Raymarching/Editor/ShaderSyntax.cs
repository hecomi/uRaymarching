using System.Text.RegularExpressions;
using System.Collections.Generic;

namespace Raymarching
{

public static class ShaderSyntax
{
    public static readonly string[] type = new string[] {
        "void",
        "fixed",
        "fixed[1-4]",
        "fixed[1-4]x[1-4]",
        "half",
        "half[1-4]",
        "half[1-4]x[1-4]",
        "float",
        "float[1-4]",
        "float[1-4]x[1-4]",
        "RaymarchInfo",
        "PostEffectOutput",
    };

    public static readonly string[] keyword = new string[] {
        "#include",
        "#define",
        "return",
        "out",
        "inout",
        "inline",
    };

    public static readonly string[] symbol = new string[] {
        @"[{}()=;,+\-*/<>|]+",
    };

    public static readonly string[] digit = new string[] {
        @"(?<![a-zz_Z_])[+-]?[0-9]+\.?[0-9]?(([eE][+-]?)?[0-9]+)?"
    };

    public static readonly string[] str = new string[] {
        "(\"[^\"\\n]*?\")"
    };

    public static readonly string[] comment = new string[] {
        @"/\*[\s\S]*?\*/|//.*"
    };

    public static readonly string[] entrypoint = new string[] {
        "DistanceFunction",
        "PostEffect",
    };

    public static readonly string[] cgprogram = new string[] {
        "abs",
        "acos",
        "all",
        "any",
        "asin",
        "atan",
        "atan2",
        "bitCount",
        "bitfieldExtract",
        "bitfieldInsert",
        "bitfieldReverse",
        "ceil",
        "clamp",
        "clip",
        "cos",
        "cosh",
        "cross",
        "ddx",
        "ddy",
        "degrees",
        "determinant",
        "distance",
        "dot",
        "exp",
        "exp2",
        "faceforward",
        "findLSB",
        "findMSB",
        "floatToIntBits",
        "floatToRawIntBits",
        "floor",
        "fmod",
        "frac",
        "frexp",
        "fwidth",
        "intBitsToFloat",
        "inverse",
        "isfinite",
        "isinf",
        "isnan",
        "ldexp",
        "length",
        "lerp",
        "lit",
        "log",
        "log10",
        "log2",
        "max",
        "min",
        "modf",
        "mul",
        "normalize",
        "pack",
        "pow",
        "radians",
        "reflect",
        "refract",
        "round",
        "rsqrt",
        "saturate",
        "sign",
        "sin",
        "sincos",
        "sinh",
        "smoothstep",
        "sqrt",
        "step",
        "tan",
        "tanh",
        "tex1D",
        "tex2D",
        "tex3D",
        "transpose",
        "trunc",
        "unpack",
    };

    public static readonly string[] unity = new string[] {
        "UNITY_MATRIX_MVP",
        "UNITY_MATRIX_MV",
        "UNITY_MATRIX_V",
        "UNITY_MATRIX_P",
        "UNITY_MATRIX_VP",
        "UNITY_MATRIX_T_MV",
        "UNITY_MATRIX_IT_MV",
        "unity_ObjectToWorld",
        "unity_WorldToObject",
        "_WorldSpaceCameraPos",
        "_ProjectionParams",
        "_ScreenParams",
        "_ZBufferParams",
        "unity_OrthoParams",
        "unity_CameraProjection",
        "unity_CameraInvProjection",
        "unity_CameraWorldClipPlanes",
        "_Time",
        "_SinTime",
        "_CosTime",
        "unity_DeltaTime",
        "_LightColor0",
        "_WorldSpaceLightPos0",
        "_LightMatrix0",
        "unity_4LightPosX0",
        "unity_4LightAtten0",
        "unity_LightColor",
        "_LightColor",
        "_LightMatrix0",
        "unity_LightColor",
        "unity_LightPosition",
        "unity_LightAtten",
        "unity_SpotDirection",
        "unity_AmbientSky",
        "unity_AmbientEquator",
        "unity_AmbientGround",
        "UNITY_LIGHTMODEL_AMBIENT",
        "unity_FogColor",
        "unity_FogParams",
        "unity_LODFade",
    };

    public static readonly string[] raymarching = new string[] {
        "Rand",
        "Mod",
        "SmoothMin",
        "Repeat",
        "Rotate",
        "TwistX",
        "TwistY",
        "TwistZ",
        "ToLocal",
        "ToWorld",
        "GetDepth",
        "Sphere",
        "RoundBox",
        "Box",
        "Torus",
        "Plane",
        "Cylinder",
        "HexagonalPrismX",
        "HexagonalPrismY",
        "HexagonalPrismZ",
        "PI",
        "_Scale",
    };

    static Regex regex;
    static MatchEvaluator evaluator;
    static Dictionary<string, string> colorTable = new Dictionary<string, string> {
        { "symbol",      Common.Color.symbol },
        { "digit",       Common.Color.digit },
        { "str",         Common.Color.str },
        { "comment",     Common.Color.comment },
        { "type",        Common.Color.type },
        { "keyword",     Common.Color.keyword },
        { "entrypoint",  Common.Color.entrypoint },
        { "cgprogram",   Common.Color.cgprogram },
        { "raymarching", Common.Color.raymarching },
        { "unity",       Common.Color.unity },
    };

    static string ToColoredCode(string code, string color)
    {
        return "<color=" + color + ">" + code + "</color>";
    }

    [UnityEditor.InitializeOnLoadMethod]
    static void Init()
    {
        var forwardSeparator = "(?<![0-9a-zA-Z_])";
        var backwardSeparator = "(?![0-9a-zA-Z_])";
        var pattern1 = "(?<{0}>({1}))";
        var pattern2 = string.Format("(?<{0}>{2}({1}){3})", "{0}", "{1}", forwardSeparator, backwardSeparator);

        var patterns = new string[] { 
            string.Format(pattern1, "comment", string.Join("|", comment)),
            string.Format(pattern2, "type", string.Join("|", type)),
            string.Format(pattern2, "keyword", string.Join("|", keyword)),
            string.Format(pattern2, "entrypoint", string.Join("|", entrypoint)),
            string.Format(pattern2, "cgprogram", string.Join("|", cgprogram)),
            string.Format(pattern2, "raymarching", string.Join("|", raymarching)),
            string.Format(pattern2, "unity", string.Join("|", unity)),
            string.Format(pattern1, "str", string.Join("|", str)),
            string.Format(pattern1, "digit", string.Join("|", digit)),
            string.Format(pattern1, "symbol", string.Join("|", symbol)),
        };
        var combinedPattern = "(" + string.Join("|", patterns) + ")";

        regex = new Regex(combinedPattern, RegexOptions.Compiled);

        evaluator = new MatchEvaluator(match => { 
            foreach (var pair in colorTable) {
                if (match.Groups[pair.Key].Success) {
                    return ToColoredCode(match.Value, pair.Value);
                }
            }
            return match.Value;
        });
    }

    public static string Highlight(string code)
    {
        return regex.Replace(code, evaluator);
    }
}

}