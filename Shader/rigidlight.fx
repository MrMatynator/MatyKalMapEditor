////////////////////////////////////////////////////////////////////////////////
// Filename: rigidlight.fx
////////////////////////////////////////////////////////////////////////////////

#define MAX_LIGHTS 4

/////////////
// GLOBALS //
/////////////
matrix worldMatrix;
matrix viewMatrix;
matrix projectionMatrix;
Texture2D shaderTexture;

float4 ambientColor;
float4 diffuseColor;
float3 lightDirection;

float4 highLighted;

float3 lightCount;

float3 lightPositions[MAX_LIGHTS];
float4 lightDefuseColors[MAX_LIGHTS];

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
    float2 tex : TEXCOORD0;
};

struct PixelInputType
{
    float4 position : SV_POSITION;
    float3 normal : NORMAL;
    float2 tex : TEXCOORD0;
	float4 worldPos : TEXCOORD1;
};

////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
PixelInputType RigidLightVertexShader(VertexInputType input)
{
    PixelInputType output;
	float4 worldPosition;
	
    // Change the position vector to be 4 units for proper matrix calculations.
    input.position.w = 1.0f;

    // Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
    // Store the texture coordinates for the pixel shader.
    output.tex = input.tex;
    
    // Calculate the normal vector against the world matrix only.
    output.normal = mul(input.normal, (float3x3)worldMatrix);
	
    // Normalize the normal vector.
    output.normal = normalize(output.normal);
	
	output.worldPos = mul(input.position, worldMatrix);

    return output;
}

////////////////////////////////////////////////////////////////////////////////
// Pixel Shader
////////////////////////////////////////////////////////////////////////////////
float4 RigidLightPixelShader(PixelInputType input) : SV_Target
{
    float4 textureColor;
    float3 lightDir;
    float lightIntensity;
    float4 color;
	float lightIntens[MAX_LIGHTS];
	float i;

    // Sample the pixel color from the texture using the sampler at this texture coordinate location.
    textureColor = shaderTexture.Sample(SampleType, input.tex);

	// Set the default output color to the ambient light value for all pixels.
    color = ambientColor;
	
    // Invert the light direction for calculations.
    lightDir = -lightDirection;

    // Calculate the amount of light on this pixel.
    lightIntensity = saturate(dot(input.normal, lightDir));

    // Calculate the amount of light on this pixel.
    lightIntensity = saturate(dot(input.normal, lightDir));

    if(lightIntensity > 0.0f)
    {
        // Determine the final diffuse color based on the diffuse color and the amount of light intensity.
        color += (diffuseColor * lightIntensity);
    }
	
	for(i = 0; i < lightCount.x; i++)
	{
		lightIntens[i] = saturate(dot(input.normal, normalize(lightPositions[i].xyz - input.worldPos.xyz)));
	
		if(lightIntens[i] > 0.0f)
		{
			color += (lightDefuseColors[i] * lightIntens[i]);
		}
	}
	
	if(highLighted.b > 0.0f)
	{
		color += highLighted;
	}
	
	// Saturate the final light color.
    color = saturate(color);
	
    // Multiply the texture pixel and the final diffuse color to get the final pixel color result.
    color = color * textureColor;

    return color;
}

////////////////////////////////////////////////////////////////////////////////
// Technique
////////////////////////////////////////////////////////////////////////////////
technique10 RigidLightTechnique
{
    pass pass0
    {
        SetVertexShader(CompileShader(vs_4_0, RigidLightVertexShader()));
        SetPixelShader(CompileShader(ps_4_0, RigidLightPixelShader()));
        SetGeometryShader(NULL);
    }
}




