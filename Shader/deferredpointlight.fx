////////////////////////////////////////////////////////////////////////////////
// Filename: deferredpointlight.fx
////////////////////////////////////////////////////////////////////////////////

/////////////
// GLOBALS //
/////////////
matrix worldMatrix;
matrix viewMatrix;
matrix projectionMatrix;

Texture2D normalTexture;
Texture2D lightTexture; // feedback loop!! <--?

float3 lightPosition;
float4 lightColor;
float lightRange;

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
	float4 worldPos : TEXCOORD1;
};

struct PixelOutputType
{
    float4 color : SV_Target1;
};

////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
PixelInputType DeferredPointLightVertexShader(VertexInputType input)
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
    
	// store the vertex world position for light calculations.
	output.worldPos = mul(input.position, worldMatrix);
	
    return output;
}


////////////////////////////////////////////////////////////////////////////////
// Pixel Shader
////////////////////////////////////////////////////////////////////////////////
PixelOutputType DeferredPointLightPixelShader(PixelInputType input) : SV_Target
{
	PixelOutputType output;
    float4 normals;
    float3 lightDir;
	float3 lightVec;
	float lightDist;
    float lightIntensity;
	float4 outputColor;
	
	outputColor = lightTexture.Sample(SampleTypePoint, input.tex);

    // Sample the normals from the normal render texture using the point sampler at this texture coordinate location.
    normals = normalTexture.Sample(SampleTypePoint, input.tex);

	lightVec = lightPosition.xyz - input.worldPos.xyz;
	lightDist = length(lightVec);
	
	lightIntensity = saturate(dot(normals.xyz, lightVec));
	
    // Calculate the amount of light on this pixel.
	//if(lightDist < lightRange)
	{
		if(lightIntensity > 0.0f)
		{
			outputColor += (lightColor * lightIntensity);
		}
	}	
	
	//saturate(outputColor);
	
	output.color = normals;
	
    return output;
}


////////////////////////////////////////////////////////////////////////////////
// Technique
////////////////////////////////////////////////////////////////////////////////
technique10 DeferredPointLightTechnique
{
    pass pass0
    {
        SetVertexShader(CompileShader(vs_4_0, DeferredPointLightVertexShader()));
        SetPixelShader(CompileShader(ps_4_0, DeferredPointLightPixelShader()));
        SetGeometryShader(NULL);
    }
}
