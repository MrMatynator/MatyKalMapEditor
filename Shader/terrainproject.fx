// Filename: terrainproject.fx

//	MATRICES
matrix worldMatrix;
matrix viewMatrix;
matrix projMatrix;

matrix viewMatrixFrom;
matrix projMatrixFrom;

// TEXTURES
Texture2D shaderTexArray[8];
Texture2D shaderAlphaArray[2];

Texture2D projectTexture;

// GLOBALS
float4 ambientColor;
float4 diffuseColor;
float3 lightDirect;

float2 variables;

// SAMPLE STATES
SamplerState SampleTypeWrap
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

BlendState AlphaBlending
{
    BlendEnable[0] = FALSE;
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
	float4 viewpos :TEXCOORD1;
	float4 color : COLOR;
	float4 ksm : TEXCOORD2;
	float4 detail : TEXCOORD3;
};

// VERTEX SHADER
PixelInputType TerrainProjectVertexShader(VertexInputType input)
{
	PixelInputType output;
	
	input.position.w = 1.0f;
	
	output.position = mul(input.position, worldMatrix);
	output.position = mul(output.position, viewMatrix);
	output.position = mul(output.position, projMatrix);
	
	output.viewpos = mul(input.position, worldMatrix);
	output.viewpos = mul(output.viewpos, viewMatrixFrom);
	output.viewpos = mul(output.viewpos, projMatrixFrom);
	
	output.uvcoord = input.uvcoord;
	
	output.normal = mul(input.normal, (float3x3)worldMatrix);
	output.normal = normalize(output.normal);

	output.color = input.color;	

	output.ksm = input.ksm;
	output.detail = input.detail;
	
	return output;
}

// PIXEL SHADER
float4 TerrainProjectPixelShader(PixelInputType input) : SV_Target
{
	int i;

	float4 color;
	float3 lightDir;
	float lightIntensity;
	
	float4 envColor;
	float4 outColor;
	
	float4 textureColor[8];
	float4 alphaMap[2];
	
	float2 projectCoord;
	float2 projectSaturated;
	float4 projectColor;
	
	i = 0;
	
	color = input.color;
	
	if(variables.y == 2.0f) {
		color = input.ksm;
	} else if(variables.y == 3.0f){
		color = input.detail;
	}
	
	// set the default output color to the ambient light value for all pixels
	envColor = ambientColor;
	
	// invert the light direction for calc
	lightDir = -lightDirect;
	
	// calc the ammount of light on this pixel
	lightIntensity = saturate(dot(input.normal, lightDir));
	
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
		textureColor[i] = shaderTexArray[i].Sample(SampleTypeWrap, input.uvcoord * 45);
		textureColor[i] = saturate(lightIntensity * textureColor[i]);
	}
	
	for(i = 0; i < 2; i++)
	{
		alphaMap[i] = shaderAlphaArray[i].Sample(SampleTypeWrap, input.uvcoord);
	}
	
	// set base color
	outColor = envColor * color * textureColor[0];
	outColor = lerp(outColor,envColor *  color * textureColor[1], alphaMap[0].g);
	outColor = lerp(outColor,envColor *  color * textureColor[2], alphaMap[0].b);
	outColor = lerp(outColor,envColor *  color * textureColor[3], alphaMap[0].a);
	outColor = lerp(outColor,envColor *  color * textureColor[4], alphaMap[1].r);
	outColor = lerp(outColor,envColor *  color * textureColor[5], alphaMap[1].g);
	outColor = lerp(outColor,envColor *  color * textureColor[6], alphaMap[1].b);
	outColor = lerp(outColor,envColor *  color * textureColor[7], alphaMap[1].a);
	
	// flipping coordinates x and y..
	//projectCoord.x = input.viewpos.x / input.viewpos.w / 2.0f + 0.5f;
	//projectCoord.y = -input.viewpos.y / input.viewpos.w / 2.0f + 0.5f; 
	
	//projectCoord.y = input.viewpos.y / input.viewpos.w / 2.0f + 0.5f; 
	//projectCoord.x *= -1;
	//projectCoord.x += 1;
	
	projectCoord.x = input.viewpos.x / input.viewpos.w / 2.0f + 0.5f; 
	projectCoord.y = input.viewpos.y / input.viewpos.w / 2.0f + 0.5f; 
	
	
	if((saturate(projectCoord.x) == projectCoord.x) && (saturate(projectCoord.y) == projectCoord.y))
	{
		projectColor = projectTexture.Sample(SampleTypeWrap, projectCoord);
		
		// blending the projection texture ontop of the terrain color based on brightness..
		outColor = (projectColor.r * projectColor) + ((1.0 - projectColor.r) * outColor);
		
		//outColor = projectColor;
	}
	
	return outColor;
}

// TECHNIQUE
technique10 TerrainProjectTechnique
{
	pass pass0
	{
		SetBlendState(AlphaBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetVertexShader(CompileShader(vs_4_0, TerrainProjectVertexShader()));
		SetPixelShader(CompileShader(ps_4_0, TerrainProjectPixelShader()));
		SetGeometryShader(NULL);
	}
}