////////////////////////////////////////////////////////////////////////////////
// Filename: directlight.fx
////////////////////////////////////////////////////////////////////////////////


/////////////
// GLOBALS //
/////////////
matrix worldMatrix;
matrix viewMatrix;
matrix projectionMatrix;

Texture2D colorTexture;
Texture2D normalTexture;

float4 ambientColor;
float4 diffuseColor;
float3 lightDirection;

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
PixelInputType DirectLightVertexShader(VertexInputType input)
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
float4 DirectLightPixelShader(PixelInputType input) : SV_Target
{
	float4 textureColor;
    float4 color;
    float4 normals;
    float3 lightDir;
    float lightIntensity;
    float4 outputColor;

    // Sample the colors from the color render texture using the point sampler at this texture coordinate location.
    textureColor = colorTexture.Sample(SampleTypePoint, input.tex);

	color = ambientColor;
	
    // Sample the normals from the normal render texture using the point sampler at this texture coordinate location.
    normals = normalTexture.Sample(SampleTypePoint, input.tex);

    // Invert the light direction for calculations.
    lightDir = -lightDirection;

	lightIntensity = saturate(dot(normals.xyz, lightDir));
	
    // Calculate the amount of light on this pixel.
	if(lightIntensity)
	{
		 color += (diffuseColor * lightIntensity);
	}
	
	saturate(color);
	
    // Determine the final amount of diffuse color based on the color of the pixel combined with the light intensity.
    outputColor = color * textureColor;
	
    return outputColor;
}


////////////////////////////////////////////////////////////////////////////////
// Technique
////////////////////////////////////////////////////////////////////////////////
technique10 DirectLightTechnique
{
    pass pass0
    {
        SetVertexShader(CompileShader(vs_4_0, DirectLightVertexShader()));
        SetPixelShader(CompileShader(ps_4_0, DirectLightPixelShader()));
        SetGeometryShader(NULL);
    }
}
