////////////////////////////////////////////////////////////////////////////////
// Filename: double.fx
////////////////////////////////////////////////////////////////////////////////

/////////////
// GLOBALS //
/////////////
matrix worldMatrix;
matrix viewMatrix;
matrix projectionMatrix;
Texture2D shaderTexture;
Texture2D shaderTexture2;

float4 ambientColor;
float4 diffuseColor;
float3 lightDirection;

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
    float2 tex0 : TEXCOORD0;
    float2 tex1 : TEXCOORD1;
};

struct PixelInputType
{
    float4 position : SV_POSITION;
    float3 normal : NORMAL;
    float2 tex0 : TEXCOORD0;
    float2 tex1 : TEXCOORD1;
};

////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
PixelInputType DoubleVertexShader(VertexInputType input)
{
    PixelInputType output;
	float4 worldPosition;
	float i;
        
    // Change the position vector to be 4 units for proper matrix calculations.
    input.position.w = 1.0f;

    // Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);

    // Store the texture coordinates for the pixel shader.
    output.tex0 = input.tex0;
    output.tex1 = input.tex1;
    
    // Calculate the normal vector against the world matrix only.
    output.normal = mul(input.normal, (float3x3)worldMatrix);
	
    // Normalize the normal vector.
    output.normal = normalize(output.normal);

    return output;
}

////////////////////////////////////////////////////////////////////////////////
// Pixel Shader
////////////////////////////////////////////////////////////////////////////////
float4 DoublePixelShader(PixelInputType input) : SV_Target
{
    float4 textureColor1;
	float4 textureColor2;
    float3 lightDir;
    float lightIntensity;
    float4 color;

    // Sample the pixel color from the texture using the sampler at this texture coordinate location.
    textureColor1 = shaderTexture.Sample(SampleType, input.tex0);
	//textureColor2 = shaderTexture2.Sample(SampleType, input.tex1);

    // Set the default output color to the ambient light value for all pixels.
    color = ambientColor;

    // Invert the light direction for calculations.
    lightDir = -lightDirection;

    // Calculate the amount of light on this pixel.
    lightIntensity = saturate(dot(input.normal, lightDir));

    if(lightIntensity > 0.0f)
    {
        // Determine the final diffuse color based on the diffuse color and the amount of light intensity.
        color += (diffuseColor * lightIntensity);
    }

    // Saturate the final light color.
    color = saturate(color);
	
	if(highLighted.a > 0.0f)
	{
		color += highLighted;
	}

    // Multiply the texture pixel and the final diffuse color to get the final pixel color result.
    color = color * textureColor1;// * texturecolor2;

    return color;
}

////////////////////////////////////////////////////////////////////////////////
// Technique
////////////////////////////////////////////////////////////////////////////////
technique10 DoubleTechnique
{
    pass pass0
    {
        SetVertexShader(CompileShader(vs_4_0, DoubleVertexShader()));
        SetPixelShader(CompileShader(ps_4_0, DoublePixelShader()));
        SetGeometryShader(NULL);
    }
}