using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(lightingcontrollor))]
public class lightingcontrollorGUI : Editor
{
    // 重载GUI绘制方法
    public override void OnInspectorGUI()
    {
        // 获取控制器
        var controller = target as lightingcontrollor;
        // 判空
        if (controller == null) return;

        // 绘制参数面板区
        DrawGlobalProperties(controller);
    }

    // 组开关变量
    private bool _groupAToggle;
    private bool _groupBToggle;

    private void DrawGlobalProperties(lightingcontrollor controller)
    {
        EditorGUI.BeginChangeCheck();
        {
            // 参数组A: 光照参数配置
            _groupAToggle = EditorGUILayout.BeginFoldoutHeaderGroup(_groupAToggle, "光照参数配置");
            if (_groupAToggle)
            {
                controller._RampMapYRange = EditorGUILayout.Slider(
                    "RampTexture采样颜色",
                    controller._RampMapYRange,
                    0.0f, 0.5f);

                controller._SpecularPow = EditorGUILayout.Slider(
                    "高光次幂",
                    controller._SpecularPow,
                    10.0f, 200.0f);

                controller._SpecularInt = EditorGUILayout.Slider(
                    "高光强度",
                    controller._SpecularInt,
                    0.0f, 5.0f);

                controller._RimPow = EditorGUILayout.Slider(
                    "边缘光幂",
                    controller._RimPow,
                    0.0f, 2.0f);

                controller._RinInt = EditorGUILayout.Slider(
                    "边缘光强度",
                    controller._RinInt,
                    0.0f, 0.5f);

                controller._EmissionInt = EditorGUILayout.Slider(
                    "自发光强度",
                    controller._EmissionInt,
                    1.0f, 5.0f);

                controller._EmissionSpeed = EditorGUILayout.Slider(
                    "发光频率",
                    controller._EmissionSpeed,
                    1.0f, 4.0f);

                controller._FaceShadowRangeSmooth = EditorGUILayout.Slider(
                    "面部阴影模糊程度",
                    controller._FaceShadowRangeSmooth,
                    0.1f, 1.0f);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();


            // 参数组B: 描边参数配置
            _groupBToggle = EditorGUILayout.BeginFoldoutHeaderGroup(_groupBToggle, "描边参数配置");
            if (_groupBToggle)
            {
                controller._OutlineCol = EditorGUILayout.ColorField(
                    "RampTexture采样颜色",
                    controller._OutlineCol);

                controller._OutlineWidth = EditorGUILayout.Slider(
                    "轮廓线宽度",
                    controller._OutlineWidth,
                    0.0001f, 0.0003f);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        if (EditorGUI.EndChangeCheck())
        {
            controller.UpdateGlobalProperties();
            EditorUtility.SetDirty(controller);
        }
    }

}
