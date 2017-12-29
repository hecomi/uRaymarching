using System.Text.RegularExpressions;
using System.Collections.Generic;

namespace uShaderTemplate
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

    public static readonly string[] user1 = new string[] {
        "DistanceFunction",
        "PostEffect",
    };

    public static readonly string[] user2 = new string[] {
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
}

}