////////////////////////////////////////////////////////////////////////////////
// Filename: DeferredComposition.fx
////////////////////////////////////////////////////////////////////////////////

/////////////
// GLOBALS //
/////////////
matrix worldMatrix;
matrix viewMatrix;
matrix projectionMatrix;

Texture2D colorTexture;
Texture2D lightTexture;

///////////////////
// SAMPLE STATES //
///////////////////
SamplerState SampleTypePoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

//////////////
// TYPEDEFS //
//////////////
struct VertexInputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
};

struct PixelInputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
};

////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
PixelInputType DeferredCompositionVertexShader(VertexInputType input)
{
    PixelInputType output;
    
    // Change the position vector to be 4 units for proper matrix calculations.
    input.position.w = 1.0f;

    // Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
    // Store the texture coordinates for the pixel shader.
    output.tex = input.tex;
	
    return output;
}


////////////////////////////////////////////////////////////////////////////////
// Pixel Shader
////////////////////////////////////////////////////////////////////////////////
float4 DeferredCompositionPixelShader(PixelInputType input) : SV_Target
{
	float4 outputColor;
	float4 textureColor;
	float4 lightColor;
	
	textureColor = colorTexture.Sample(SampleTypePoint, input.tex);
	lightColor = lightTexture.Sample(SampleTypePoint, input.tex);
	
	outputColor = saturate(textureColor + lightColor);
	outputColor = textureColor;
	
    return outputColor;
}


////////////////////////////////////////////////////////////////////////////////
// Technique
////////////////////////////////////////////////////////////////////////////////
technique10 DeferredCompositionTechnique
{
    pass pass0
    {
        SetVertexShader(CompileShader(vs_4_0, DeferredCompositionVertexShader()));
        SetPixelShader(CompileShader(ps_4_0, DeferredCompositionPixelShader()));
        SetGeometryShader(NULL);
    }
}
