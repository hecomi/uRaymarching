using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace uShaderTemplate
{

public class ShaderTemplateConvertInfo
{
    public Dictionary<string, bool> conditions = new Dictionary<string, bool>();
    public Dictionary<string, string> blocks = new Dictionary<string, string>();
    public Dictionary<string, string> variables = new Dictionary<string, string>();
}

public class ShaderTemplateParser
{
    static readonly string conditionPattern = 
        @"@if\s*(?<Cond>[^:\s\n]+)(?:\s*:\s*)?(?<Init>[^\s\n]+)?\s*\n" + 
        @"(?<TrueValue>[^@]*?)" + 
        @"((\s*@else\s*)\n" +
        @"(?<FalseValue>[^@]*?))?" + 
        @"\n\s*@endif";
    static readonly string blockPattern = 
        @"@block\s*(?<Block>[^\s\n]+)\s*\n" +
        @"(?<Value>[\s\S]*?)" +
        @"\n\s*(:?//\s*)*?@endblock";
    static readonly string variablePattern = 
        @"<(?<Name>[^=\s\n]+)(?:\s*=\s*(?<Value>[^\s\n|>]+)(\s*\|\s*(?<Value>[^\s\n|>]+))*)?\s*>";
    static readonly string constantsPattern =
        @"@constants\s*(?<Path>[^\n]+)";

    public string code { get; set; }

    public Dictionary<string, bool> conditions { get; private set; }
    public Dictionary<string, string> blocks { get; private set; }
    public Dictionary<string, List<string>> variables { get; private set; }
    public Constants constants { get; private set; }

    public ShaderTemplateParser(string code)
    {
        this.code = code;
        conditions = new Dictionary<string, bool>();
        blocks = new Dictionary<string, string>();
        variables = new Dictionary<string, List<string>>();
        Parse();
    }

    void Parse()
    {
        ParseConstants();
        ParseConditions();
        ParseBlocks();
        ParseVariables();
    }

    public string Convert(ShaderTemplateConvertInfo info)
    {
        if (constants != null) {
            constants.OnBeforeConvert();
        }

        var code = this.code;
        code = WriteConstants(code);
        code = WriteConditions(code, info);
        code = WriteBlocks(code, info);
        code = WriteVariables(code, info);
        code = code.Replace("\r\n", "\n");
        var regex = new Regex(@"\n\n\n+");
        code = regex.Replace(code, "\n\n");

        if (constants != null) {
            constants.OnAfterConvert();
        }

        return code;
    }

    void ParseConstants()
    {
        var regex = new Regex(constantsPattern);
        var matches = regex.Matches(code);
        if (matches.Count > 0) {
            var path = matches[0].Groups["Path"].Value;
            constants = UnityEngine.Resources.Load<Constants>(path);
        }
    }

    string WriteConstants(string code)
    {
        var regex = new Regex(constantsPattern);
        var evaluator = new MatchEvaluator(match => "");
        return regex.Replace(code, evaluator);
    }

    void ParseConditions()
    {
        conditions.Clear();

        var regex = new Regex(conditionPattern);
        var matches = regex.Matches(code);
        foreach (Match match in matches) {
            var cond = match.Groups["Cond"].Value;
            if (conditions.ContainsKey(cond)) continue;
            bool init = false;
            if (match.Groups["Init"].Success) {
                init = bool.Parse(match.Groups["Init"].Value);
            }
            conditions.Add(cond, init);
        }
    }

    string WriteConditions(string code, ShaderTemplateConvertInfo info)
    {
        var regex = new Regex(conditionPattern);
        var evaluator = new MatchEvaluator(match => {
            var cond = match.Groups["Cond"].Value;
            var trueValue = match.Groups["TrueValue"].Value;
            var falseValue = match.Groups["FalseValue"].Value;
            if (!info.conditions.ContainsKey(cond)) {
                throw new System.Exception(string.Format("The key \"{0}\" is not found in the given conditions.", cond));
            }
            return (info.conditions[cond]) ? trueValue : falseValue;
        });

        var preCode = code;
        code = regex.Replace(code, evaluator);
        while (code != preCode) {
            preCode = code;
            code = regex.Replace(code, evaluator);
        }

        return code;
    }

    void ParseBlocks()
    {
        blocks.Clear();

        var regex = new Regex(blockPattern);
        var matches = regex.Matches(code);
        foreach (Match match in matches) {
            var block = match.Groups["Block"].Value;
            var value = match.Groups["Value"].Value;
            blocks.Add(block, value);
        }
    }

    string WriteBlocks(string code, ShaderTemplateConvertInfo info)
    {
        var regex = new Regex(blockPattern);
        var evaluator = new MatchEvaluator(match => {
            var block = match.Groups["Block"].Value;
            var value = info.blocks[block];
            if (!info.blocks.ContainsKey(block)) {
                throw new System.Exception(string.Format("The key \"{0}\" is not found in the given blocks.", block));
            }
            return string.Format("// @block {0}\n{1}\n// @endblock", block, value);
        });
        return regex.Replace(code, evaluator);
    }

    void ParseVariables()
    {
        variables.Clear();

        var regex = new Regex(variablePattern);
        var matches = regex.Matches(code);
        foreach (Match match in matches) {
            var variable = match.Groups["Name"].Value;
            if (!variables.ContainsKey(variable)) {
                var values = new List<string>();
                foreach (Capture capture in match.Groups["Value"].Captures) {
                    values.Add(capture.Value);
                }
                variables.Add(variable, values);
            }
        }
    }

    string WriteVariables(string code, ShaderTemplateConvertInfo info)
    {
        var regex = new Regex(variablePattern);
        var evaluator = new MatchEvaluator(match => {
            var variable = match.Groups["Name"].Value;
            if (!info.variables.ContainsKey(variable)) {
                throw new System.Exception(string.Format("The key \"{0}\" is not found in the given variables.", variable));
            }
            return info.variables[variable];
        });
        return regex.Replace(code, evaluator);
    }
}

}