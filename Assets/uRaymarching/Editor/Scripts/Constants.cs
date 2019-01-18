using UnityEngine;

namespace Raymarching
{

[CreateAssetMenu(
    menuName = uShaderTemplate.Common.Setting.menuPlace + "uRaymarching/Constants", 
    order = uShaderTemplate.Common.Setting.menuOrder + 1)]
public class Constants : uShaderTemplate.Constants
{
	const string ShaderDir = "RaymarchingShaderDirectory";

	void Awake()
	{
		values = new uShaderTemplate.Constant[] {
			new uShaderTemplate.Constant() { 
				name = ShaderDir,
				value = Utils.GetCgincDirPath()
			}
		};
	}

	public override void OnBeforeConvert()
	{
		for (int i = 0; i < values.Length; ++i)
		{
			if (values[i].name != ShaderDir) continue;

			var constant = values[i];
			constant.value = Utils.GetCgincDirPath();
			values[i] = constant;
		}
	}
}

}