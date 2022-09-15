////////////////////////////////////////////////////////////////////////////////
// Filename: deffereddouble.fx
////////////////////////////////////////////////////////////////////////////////

/////////////
// GLOBALS //
/////////////
matrix worldMatrix;
matrix viewMatrix;
matrix projectionMatrix;
Texture2D shaderTexture;

float4 highLighted;

///////////////////
// SAMPLE STATES //
///////////////////
SamplerState SampleType
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

//////////////
// TYPEDEFS //
//////////////
struct VertexInputType
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float2 tex1 : TEXCOORD0;
	float2 tex2 : TEXCOORD1;
};

struct PixelInputType
{
    float4 position : SV_POSITION;
    float3 normal : NORMAL;
    float2 tex1 : TEXCOORD0;
	float2 tex2 : TEXCOORD1;
};

struct PixelOutputType
{
    float4 color : SV_Target0;
    float4 normal : SV_Target1;
};

////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
PixelInputType DefferedDoubleVertexShader(VertexInputType input)
{
    PixelInputType output;
    
    
    // Change the position vector to be 4 units for proper matrix calculations.
    input.position.w = 1.0f;

    // Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
    // Store the texture coordinates for the pixel shader.
    output.tex1 = input.tex1;
	output.tex2 = input.tex2;
    
    // Calculate the normal vector against the world matrix only.
    output.normal = mul(input.normal, (float3x3)worldMatrix);
	
    // Normalize the normal vector.
    output.normal = normalize(output.normal);

    return output;
}

////////////////////////////////////////////////////////////////////////////////
// Pixel Shader
////////////////////////////////////////////////////////////////////////////////
PixelOutputType DefferedDoublePixelShader(PixelInputType input) : SV_Target
{
    PixelOutputType output;

    // Sample the pixel color from the texture using the sampler at this texture coordinate location.
    output.color = shaderTexture.Sample(SampleType, input.tex1);

	output.normal = float4(input.normal, 1.0f);

    return output;
}

////////////////////////////////////////////////////////////////////////////////
// Technique
////////////////////////////////////////////////////////////////////////////////
technique10 DefferedDoubleTechnique
{
    pass pass0
    {
        SetVertexShader(CompileShader(vs_4_0, DefferedDoubleVertexShader()));
        SetPixelShader(CompileShader(ps_4_0, DefferedDoublePixelShader()));
        SetGeometryShader(NULL);
    }
}