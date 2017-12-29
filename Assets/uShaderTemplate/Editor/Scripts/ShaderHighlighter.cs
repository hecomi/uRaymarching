using System.Text.RegularExpressions;
using System.Collections.Generic;

namespace uShaderTemplate
{

public static class ShaderHighlighter
{
    static Regex regex;
    static MatchEvaluator evaluator;
    static Dictionary<string, string> colorTable = new Dictionary<string, string> {
        { "symbol",      Common.Color.symbol },
        { "digit",       Common.Color.digit },
        { "str",         Common.Color.str },
        { "comment",     Common.Color.comment },
        { "type",        Common.Color.type },
        { "keyword",     Common.Color.keyword },
        { "cgprogram",   Common.Color.cgprogram },
        { "user1",       Common.Color.user1 },
        { "user2",       Common.Color.user2 },
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
            string.Format(pattern1, "comment", string.Join("|", ShaderSyntax.comment)),
            string.Format(pattern2, "type", string.Join("|", ShaderSyntax.type)),
            string.Format(pattern2, "keyword", string.Join("|", ShaderSyntax.keyword)),
            string.Format(pattern2, "user1", string.Join("|", ShaderSyntax.user1)),
            string.Format(pattern2, "user2", string.Join("|", ShaderSyntax.user2)),
            string.Format(pattern2, "cgprogram", string.Join("|", ShaderSyntax.cgprogram)),
            string.Format(pattern2, "unity", string.Join("|", ShaderSyntax.unity)),
            string.Format(pattern1, "str", string.Join("|", ShaderSyntax.str)),
            string.Format(pattern1, "digit", string.Join("|", ShaderSyntax.digit)),
            string.Format(pattern1, "symbol", string.Join("|", ShaderSyntax.symbol)),
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