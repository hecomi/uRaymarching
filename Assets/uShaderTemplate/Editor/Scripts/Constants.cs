using UnityEngine;

namespace uShaderTemplate
{

[System.Serializable]
public struct Constant
{
    public string name;
    public string value;
}

[CreateAssetMenu(
    menuName = Common.Setting.menuPlace + "Constants", 
    order = Common.Setting.menuOrder + 1)]
public class Constants : ScriptableObject
{
    public Constant[] values;
    public virtual void OnBeforeConvert() {}
    public virtual void OnAfterConvert() {}
}

}