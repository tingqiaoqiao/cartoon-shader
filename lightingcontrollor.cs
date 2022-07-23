using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class lightingcontrollor : MonoBehaviour
{
    /*
        _RampMapYRange("RampTexture采样颜色", Range(0.0, 0.5)) = 0.3
        _SpecularPow("高光次幂", Range(10.0, 200.0)) = 50.0
        _SpecularInt("高光强度", Range(0.0, 5.0)) = 2.0
        _RimPow("边缘光幂", Range(0.0, 30.0)) = 1.0
        _RinInt("边缘光强度", Range(0.0, 0.5)) = 1.0
        _EmissionInt("自发光强度", Range(1.0, 5.0)) = 2.0
        _EmissionSpeed("发光频率", Range(1.0, 4.0)) = 2.0
        _FaceShadowRangeSmooth("面部阴影模糊程度", Range(0.1, 1.0)) = 0.1

        [Space(5)]
        _OutlineWidth("轮廓线宽度", Range(0.0001, 0.0003)) = 0.0001
        _OutlineCol("轮廓线颜色", color) = (1.0,1.0,1.0)
     */

        public float _RampMapYRange = 0.3f;
        public float _SpecularPow = 50.0f;
        public float _SpecularInt = 2.0f;
        public float _RimPow = 1.0f;
        public float _RinInt = 1.0f;
        public float _EmissionInt = 2.0f;
        public float _EmissionSpeed = 2.0f;
        public float _FaceShadowRangeSmooth = 0.1f;

        public float _OutlineWidth = 0.0001f;
        public Color _OutlineCol = Color.black;


    private void OnEnable()
    {
        UpdateGlobalProperties();
    }

    public void UpdateGlobalProperties()
    {
        Shader.SetGlobalFloat("_RampMapYRange", _RampMapYRange);
        Shader.SetGlobalFloat("_SpecularPow", _SpecularPow);
        Shader.SetGlobalFloat("_SpecularInt", _SpecularInt);
        Shader.SetGlobalFloat("_RimPow", _RimPow);
        Shader.SetGlobalFloat("_RinInt", _RinInt);
        Shader.SetGlobalFloat("_EmissionInt", _EmissionInt);
        Shader.SetGlobalFloat("_EmissionSpeed", _EmissionSpeed);
        Shader.SetGlobalFloat("_FaceShadowRangeSmooth", _FaceShadowRangeSmooth);
        Shader.SetGlobalFloat("_OutlineWidth", _OutlineWidth);
        Shader.SetGlobalColor("_OutlineCol", _OutlineCol);
    }

    [ContextMenu("教学·设置全局变量")]      //测试代码
    private void Test_SetGlobalParam()
    {
        // 获取当前值
        var origentCol = Shader.GetGlobalColor("_G_testCol");
        // 当前不为红也不为绿时 上红色
        if (origentCol != Color.red && origentCol != Color.green)
        {
            Shader.SetGlobalColor("_G_testCol", Color.red);
            return;
        }
        // 当前为红绿时 来回切
        if (origentCol == Color.red)
            Shader.SetGlobalColor("_G_testCol", Color.green);
        if (origentCol == Color.green)
            Shader.SetGlobalColor("_G_testCol", Color.red);
    }


}
