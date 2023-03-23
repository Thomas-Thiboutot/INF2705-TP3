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

uniform sampler2D laTextureCoul;
uniform sampler2D laTextureNorm;

/////////////////////////////////////////////////////////////////

in Attribs {
    vec4 couleur;
    vec3 lumiDir;
    vec3 normale;
    vec3 obsVec;
    vec3 spotDir[3];
    vec2 texCoord;
} AttribsIn;

out vec4 FragColor;
float attenuation = 1.0;
vec4 calculerReflexion( in int j, in vec3 L, in vec3 N, in vec3 O) // pour la lumière j
{   

    vec4 coul = vec4(0);
    // calculer l'éclairage seulement si le produit scalaire est positif
    float NdotL = max( 0.0, dot( N, L ) );
    if ( NdotL > 0.0 )
    {
        // calculer la composante diffuse
        coul += attenuation * FrontMaterial.diffuse * LightSource.diffuse[j] * NdotL;

        // calculer la composante spéculaire (Blinn ou Phong : spec = BdotN ou RdotO )
        float spec = ( utiliseBlinn ?
                       dot( normalize( L + O ), N ) : // dot( B, N )
                       dot( reflect( -L, N ), O ) ); // dot( R, O )
        if ( spec > 0 ) coul += attenuation * FrontMaterial.specular * LightSource.specular[j] * pow( spec, FrontMaterial.shininess );
    }

    return( coul );
}

float calculerSpot( in vec3 D, in vec3 L, in vec3 N )
{
    float spotFacteur = 0.0;
    if ( dot( D, N ) >= 0 )
    {
        float spotDot = dot( L, D );
        //spotFacteur = ( spotDot > cos(radians(LightSource.spotAngleOuverture)) ) ? pow( spotDot, LightSource.spotExponent ) : 0.0;
        if ( spotDot > cos(radians(LightSource.spotAngleOuverture)) ) spotFacteur = pow( spotDot, LightSource.spotExponent );
    }
    return( spotFacteur );
}

void main( void )
{
    vec4 coul = AttribsIn.couleur;
    vec3 L = normalize( AttribsIn.lumiDir );
    vec3 O = normalize( AttribsIn.obsVec );  
    vec3 N = normalize( gl_FrontFacing ? AttribsIn.normale : -AttribsIn.normale );
    vec3 D = normalize( AttribsIn.spotDir[0] );

    //float NdotL = dot( N, L );
    //if( (NdotL == 0.0) || (NdotL < 0.0) || (NdotL > 0.0) ) coul += LightSource.diffuse[0];
    //int j = 0; 
    coul += FrontMaterial.diffuse * LightSource.ambient[0];//* NdotL;
    //coul += calculerReflexion( j, L, N, O ) * calculerSpot( D, L, N );
    
    //vec4 couleur0 = texture( laTextureCoul, AttribsIn.texCoord );
    //FragColor = couleur0;

    FragColor = clamp(coul, 0.0, 1.0);
    // Pour « voir » les normales, on peut remplacer la couleur du fragment par la normale.
    // (Les composantes de la normale variant entre -1 et +1, il faut
    // toutefois les convertir en une couleur entre 0 et +1 en faisant (N+1)/2.)
    if ( afficheNormales ) FragColor = clamp( vec4( (N+1)/2, AttribsIn.couleur.a ), 0.0, 1.0 );
}