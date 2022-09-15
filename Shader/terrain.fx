matrix worldMatrix;
matrix viewMatrix;
matrix projectionMatrix;

Texture2D shaderTexArray[8];
Texture2D shaderAlphaArray[2];

float4 ambientColor;
float4 diffuseColor;
float3 lightDirection;

float2 variables;

BlendState AlphaBlending
{
    BlendEnable[0] = FALSE;
};

SamplerState SampleType
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

struct VertexInputType
{
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uvcoord : TEXCOORD0;
	float4 color : COLOR;
	float4 ksm : TEXCOORD1;
	float4 detail : TEXCOORD2;
};

struct PixelInputType
{
	float4 position : SV_POSITION;
	float3 normal : NORMAL;
	float2 uvcoord : TEXCOORD0;
	float4 color : COLOR;
	float4 ksm : TEXCOORD1;
	float4 detail : TEXCOORD2;
};

// vertex shader
PixelInputType TerrainVertexShader(VertexInputType input)
{
	PixelInputType output;
	
	// change the position to be 4 units for proper matrix calc
	input.position.w = 1.0f;
	
	// calc the position of the vertex against the world view and projection matrices
	output.position = mul(input.position, worldMatrix);
	output.position = mul(output.position, viewMatrix);
	output.position = mul(output.position, projectionMatrix);
	
	// put the texture coordinates for the pixel shader
	output.uvcoord = input.uvcoord;
	//output.alphacoord = input.alphacoord;
	
	// calc the normal vec against the world matrix
	output.normal = mul(input.normal, (float3x3)worldMatrix);
	
	// normalize the normal vec
	output.normal = normalize(output.normal);
	
	//send the color map color into the pixel shader
	output.color = input.color;
	
	output.ksm = input.ksm;
	output.detail = input.detail;
	
	return output;
}

// pixel shader
float4 TerrainPixelShader(PixelInputType input) : SV_Target
{
	int i;

	float4 color;
	float4 envColor;
	float4 outColor;
	
	float4 textureColor[8];
	float4 alphaMap[2];
	
	float3 lightDir;
	float lightIntensity;
	//float4 vertexColor;
	
	color = input.color;
	
	if(variables.y == 2.0f) {
		color = input.ksm;
	} else if(variables.y == 3.0f){
		color = input.detail;
	}
	
	// set the default output color to the ambient light value for all pixels
	envColor = ambientColor;
	
	// invert the light direction for calc
	lightDir = -lightDirection;
	
	// calc the ammount of light on this pixel
	lightIntensity = saturate(dot(normalize(input.normal), lightDir));
	
	lightIntensity += 0.5f; // brighten up the terrain a little
	
	if(lightIntensity > 0.0f)
	{
		// determine the final diffuse color and light intensity
		envColor += (diffuseColor * lightIntensity);
	}
	
	// saturate the final color
	envColor = saturate(envColor);
	
	// Sample the pixel color from the texture using the sampler at this texture coordinate location.
	
	for(i = 0; i < 8; i++)
	{
		textureColor[i] = shaderTexArray[i].Sample(SampleType, input.uvcoord * 45);
		textureColor[i] = saturate(lightIntensity * textureColor[i]);
	}
	
	for(i = 0; i < 2; i++)
	{
		alphaMap[i] = shaderAlphaArray[i].Sample(SampleType, input.uvcoord);
	}
	
	outColor = envColor * color * textureColor[0];
	outColor = lerp(outColor,envColor *  color * textureColor[1], alphaMap[0].g);
	outColor = lerp(outColor,envColor *  color * textureColor[2], alphaMap[0].b);
	outColor = lerp(outColor,envColor *  color * textureColor[3], alphaMap[0].a);
	outColor = lerp(outColor,envColor *  color * textureColor[4], alphaMap[1].r);
	outColor = lerp(outColor,envColor *  color * textureColor[5], alphaMap[1].g);
	outColor = lerp(outColor,envColor *  color * textureColor[6], alphaMap[1].b);
	outColor = lerp(outColor,envColor *  color * textureColor[7], alphaMap[1].a);
	
	return outColor;
}

// technique
technique10 TerrainTechnique
{
    pass pass0
    {
		SetBlendState(AlphaBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
        SetVertexShader(CompileShader(vs_4_0, TerrainVertexShader()));
        SetPixelShader(CompileShader(ps_4_0, TerrainPixelShader()));
        SetGeometryShader(NULL);
    }
}