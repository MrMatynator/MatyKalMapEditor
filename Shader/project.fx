// Filename: project.fx

//	MATRICES
matrix worldMatrix;
matrix viewMatrix;
matrix projMatrix;

matrix viewMatrixFrom;
matrix projMatrixFrom;

// TEXTURES
Texture2D shaderTexture;
Texture2D projectTexture;

// GLOBALS
float4 ambientColor;
float4 diffuseColor;
float3 lightDirect;

// SAMPLE STATES
SamplerState SampleTypeWrap
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

// TYPEDEFS
struct VertexInputType
{
	float4 pos : POSITION;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
};

struct PixelInputType
{
	float4 pos : SV_POSITION;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
	float4 viewpos : TEXCOORD1;
};

// VERTEX SHADER
PixelInputType ProjectVertexShader(VertexInputType input)
{
	PixelInputType output;
	
	input.pos.w = 1.0f;
	
	output.pos = mul(input.pos, worldMatrix);
	output.pos = mul(output.pos, viewMatrix);
	output.pos = mul(output.pos, projMatrix);
	
	output.viewpos = mul(input.pos, worldMatrix);
	output.viewpos = mul(output.viewpos, viewMatrixFrom);
	output.viewpos = mul(output.viewpos, projMatrixFrom);
	
	output.tex = input.tex;
	
	output.nor = mul(input.nor, (float3x3)worldMatrix);
	output.nor = normalize(output.nor);
	
	return output;
}

// PIXEL SHADER
float4 ProjectPixelShader(PixelInputType input) : SV_Target
{
	float4 color;
	float3 lightDir;
	float lightIntens;
	float4 textureColor;
	float2 projectCoord;
	float4 projectColor;
	
	color = ambientColor;
	
	lightDir = -lightDirect;
	lightIntens = saturate(dot(input.nor, lightDir));
	
	if(lightIntens > 0.0f)
	{
		color += (diffuseColor * lightIntens);
	}
	
	color = saturate(color);
	
	textureColor = shaderTexture.Sample(SampleTypeWrap, input.tex);
	
	color = color * textureColor;
	
	projectCoord.x = input.viewpos.x / input.viewpos.w / 2.0f + 0.5f;
	projectCoord.y = -input.viewpos.y / input.viewpos.w / 2.0f + 0.5f;
	
	if((saturate(projectCoord.x) == projectCoord.x) && (saturate(projectCoord.y) == projectCoord.y))
	{
		projectColor = projectTexture.Sample(SampleTypeWrap, projectCoord);
		color = projectColor;
	}
	
	return color;
}

// TECHNIQUE

technique10 ProjectTechnique
{
	pass pass0
	{
		SetVertexShader(CompileShader(vs_4_0, ProjectVertexShader()));
		SetPixelShader(CompileShader(ps_4_0, ProjectPixelShader()));
		SetGeometryShader(NULL);
	}
}