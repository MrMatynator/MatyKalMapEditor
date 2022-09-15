////////////////////////////////////////////////////////////////////////////////
// Filename: pointlight.fx
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

////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
PixelInputType PointLightVertexShader(VertexInputType input)
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
    
	output.worldPos = mul(input.position, worldMatrix);
	
    return output;
}


////////////////////////////////////////////////////////////////////////////////
// Pixel Shader
////////////////////////////////////////////////////////////////////////////////
float4 PointLightPixelShader(PixelInputType input) : SV_Target
{
	float4 textureColor;
    float4 color;
    float4 normals;
    float3 lightDir;
	float3 lightVec;
	float lightDist;
    float lightIntensity;
	float pointLightIntensity;
    float4 outputColor;

    // Sample the colors from the color render texture using the point sampler at this texture coordinate location.
    textureColor = colorTexture.Sample(SampleTypePoint, input.tex);

	color = ambientColor;
	
    // Sample the normals from the normal render texture using the point sampler at this texture coordinate location.
    normals = normalTexture.Sample(SampleTypePoint, input.tex);

    // Invert the light direction for calculations.
    lightDir = -lightDirection;

	//lightIntensity = saturate(dot(normals.xyz, lightDir));
	
    // Calculate the amount of light on this pixel.
	//if(lightIntensity > 0.0f)
	//{
	//	color += (diffuseColor * lightIntensity);
	//}
	
	lightVec = lightPosition.xyz - input.worldPos.xyz;
	lightDist = length(lightVec);
	
	//if(lightDist < lightRange) // only render the light on this pixel if the light is in range!!!
	//{
		pointLightIntensity = saturate(dot(normals.xyz, normalize(lightPosition.xyz - input.worldPos.xyz)));
		if(pointLightIntensity > 0.0f)
		{
			color += (lightColor * pointLightIntensity);
		}
	//}
	
	saturate(color);
	
    // Determine the final amount of diffuse color based on the color of the pixel combined with the light intensity.
    outputColor = color * textureColor;

    return outputColor;
}


////////////////////////////////////////////////////////////////////////////////
// Technique
////////////////////////////////////////////////////////////////////////////////
technique10 PointLightTechnique
{
    pass pass0
    {
        SetVertexShader(CompileShader(vs_4_0, PointLightVertexShader()));
        SetPixelShader(CompileShader(ps_4_0, PointLightPixelShader()));
        SetGeometryShader(NULL);
    }
}
