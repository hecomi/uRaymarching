using UnityEngine;

namespace Raymarching
{

[CreateAssetMenu(
    menuName = "Shader/uRaymarching/Constants", 
    order = uShaderTemplate.Common.Setting.menuOrder + 1)]
public class Constants : uShaderTemplate.Constants
{
	const string ShaderDir = "RaymarchingShaderDirectory";

    [SerializeField]
    string shaderName = "Hidden/Raymarching/UniversalRP/GetPathFromScript";

	void Awake()
	{
		values = new uShaderTemplate.Constant[] {
			new uShaderTemplate.Constant() { 
				name = ShaderDir,
				value = Utils.GetShaderDirPath(shaderName)
			}
		};
	}

	public override void OnBeforeConvert()
	{
		for (int i = 0; i < values.Length; ++i)
		{
			if (values[i].name != ShaderDir) continue;

			var constant = values[i];
			constant.value = Utils.GetShaderDirPath(shaderName);
			values[i] = constant;
		}
	}
}

}