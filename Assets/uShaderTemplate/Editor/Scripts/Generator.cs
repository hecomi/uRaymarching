using UnityEngine;
using System.Collections.Generic;

namespace uShaderTemplate
{

[System.Serializable]
public struct ShaderVariables
{
    public string key;
    public string value;
}

[System.Serializable]
public struct ShaderCondition
{
    public string key;
    public bool value;
}

[System.Serializable]
public struct ShaderBlock
{
    public string key;
    public string value;
    public bool folded;
}

[CreateAssetMenu(
    menuName = Common.Setting.menuPlace + "Generator", 
    order = Common.Setting.menuOrder)]
public class Generator : ScriptableObject
{
    public string shaderName = "";
    public Shader shaderReference = null;
    public string shaderTemplate = "";

    public List<ShaderVariables> variables = new List<ShaderVariables>();
    public List<ShaderCondition> conditions = new List<ShaderCondition>();
    public List<ShaderBlock> blocks = new List<ShaderBlock>();
    public Constants constants;

    public bool basicFolded = true;
    public bool conditionsFolded = false;
    public bool variablesFolded = false;
    public bool materialsFolded = false;
    public bool constantsFolded = false;

    public virtual void OnBeforeConvert() {}
    public virtual void OnAfterConvert() {}
}

}