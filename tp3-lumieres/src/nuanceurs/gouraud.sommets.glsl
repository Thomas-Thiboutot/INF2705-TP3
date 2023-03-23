#version 410

// Définition des paramètres des sources de lumière
layout (std140) uniform LightSourceParameters
{
    vec4 ambient[3];
    vec4 diffuse[3];
    vec4 specular[3];
    vec4 position[3];      // dans le repère du monde
    vec3 spotDirection[3]; // dans le repère du monde
    float spotExponent;
    float spotAngleOuverture; // ([0.0,90.0] ou 180.0)
    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
} LightSource;

// Définition des paramètres des matériaux
layout (std140) uniform MaterialParameters
{
    vec4 emission;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
} FrontMaterial;

// Définition des paramètres globaux du modèle de lumière
layout (std140) uniform LightModelParameters
{
    vec4 ambient;       // couleur ambiante globale
    bool twoSide;       // éclairage sur les deux côtés ou un seul?
} LightModel;

layout (std140) uniform varsUnif
{
    // partie 1: illumination
    int typeIllumination;     // 0:Gouraud, 1:Phong
    bool utiliseSpot;         // indique si on utilise des lumière de type spot ou point
    bool utiliseBlinn;        // indique si on veut utiliser modèle spéculaire de Blinn ou Phong
    bool utiliseDirect;       // indique si on utilise un spot style Direct3D ou OpenGL
    bool afficheNormales;     // indique si on utilise les normales comme couleurs (utile pour le débogage)
    // partie 2: texture
    float tempsGlissement;    // temps de glissement
    int iTexCoul;             // numéro de la texture de couleurs appliquée
    // partie 3b: texture
    int iTexNorm;             // numéro de la texture de normales appliquée
};

uniform mat4 matrModel;
uniform mat4 matrVisu;
uniform mat4 matrProj;
uniform mat3 matrNormale;

/////////////////////////////////////////////////////////////////

layout(location=0) in vec4 Vertex;
layout(location=1) in vec3 Normal;
layout(location=8) in vec2 TexCoord;

out Attribs {
    vec4 couleur;
    vec3 lumiDir;
    vec3 normale;
    vec3 obsVec;
    vec3 spotDir[3];
    vec2 texCoord;
} AttribsOut;

void main( void )
{
    gl_Position = matrProj * matrVisu * matrModel * Vertex;
    vec4 coul = FrontMaterial.emission + FrontMaterial.ambient * LightModel.ambient;
    //coul += FrontMaterial.ambient * (LightSource.ambient[0]);

    vec3 pos = vec3( matrVisu * matrModel * Vertex );

    AttribsOut.lumiDir = ( matrVisu * LightSource.position[0] ).xyz - pos;
    AttribsOut.obsVec = -pos ;
    AttribsOut.normale = normalize(matrNormale * Normal) ;
    AttribsOut.spotDir[0] = mat3(matrVisu) * -LightSource.spotDirection[0];
    AttribsOut.couleur = coul;

    AttribsOut.texCoord = TexCoord.st;
}