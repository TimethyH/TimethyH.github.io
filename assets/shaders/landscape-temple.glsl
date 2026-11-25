// Landscape Temple (https://www.shadertoy.com/view/s3jGD3)
// Shadertoy "Image" tab. iChannel0 = Shadertoy texture Xsf3Rr, copied to textures/stone.jpg.
// Changed for the website: the camera stands still and the visitor looks around by
// dragging (see "camera" in mainImage). The player runs this shader with
// data-mouse="drag", so iMouse.xy is the total drag distance in pixels instead of the
// cursor position. Pasted back into Shadertoy it still compiles; there the view simply
// follows the absolute cursor position while dragging.

// This shader is made entirely from resources learned from Inigo Quilez  v
// Landscape: https://www.youtube.com/watch?v=BFld4EBO2RE&t=1501s
// Temple: https://www.youtube.com/watch?v=-pdSjBPH3zM&t=6620s


// Useful functions

// return smoothstep and its derivative
vec2 smoothstepd( float a, float b, float x)
{
    if( x<a ) return vec2( 0.0, 0.0 );
    if( x>b ) return vec2( 1.0, 0.0 );
    float ir = 1.0/(b-a);
    x = (x-a)*ir;
    return vec2( x*x*(3.0-2.0*x), 6.0*x*(1.0-x)*ir );
}

float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }

vec4 textureBox( in sampler2D tex, in vec3 pos, in vec3 nor )
{
    vec4 cx = texture( tex, pos.yz );
    vec4 cy = texture( tex, pos.xz );
    vec4 cz = texture( tex, pos.xy );
    vec3 m = nor*nor;
    return (cx*m.x + cy*m.y + cz*m.z)/(m.x+m.y+m.z);
}

////////////////////////////////////
// Constants
////////////////////////////////////

const mat2 m2 = mat2(  0.80,  0.60,
                      -0.60,  0.80 );

// inversed rotation
const mat2 m2i = mat2( 0.80, -0.60,
                       0.60,  0.80 );

const vec3  kSunDir = vec3(-0.824695,0.458521,-0.624695);
const float kMaxHeight = 840.0;
const int kFbmDetail = 14;

///////////////////////////////////////
// Hash
///////////////////////////////////////

float hash1( vec2 p )
{
    // divide the point in space by irrational pi,
    // get its fractional part and shuffle them to create a random number
    p  = 50.0*fract( p*0.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

float hash1( float n )
{
    return fract( n*17.0*fract( n*0.3183099 ) );
}

///////////////////////////////////////
// Noise
///////////////////////////////////////

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 w = fract(x);

    // Quintic smoothstep
    // https://iquilezles.org/articles/smoothsteps/
    #if 1
    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    #else
    vec2 u = w*w*(3.0-2.0*w); // cubic
    #endif

    // Hash the 4 corners around p
    float a = hash1(p+vec2(0,0));
    float b = hash1(p+vec2(1,0));
    float c = hash1(p+vec2(0,1));
    float d = hash1(p+vec2(1,1));

    // convert it to -1 +1 space with bilinear interpolation
    // this formula is derived by lerping the top corners and the bottom corners
    // then lerping both results.
    return -1.0+2.0*(a + (b-a)*u.x + (c-a)*u.y + (a - b - c + d)*u.x*u.y);
}

// noise function + derivatives in regards of x and z
vec3 noised( in vec2 x )
{
    vec2 p = floor(x);
    vec2 w = fract(x);

    vec2 u = w*w*w*(w*(w * 6.0 - 15.0) + 10.0);

    float a = hash1(p + vec2(0,0));
    float b = hash1(p + vec2(1,0));
    float c = hash1(p + vec2(0,1));
    float d = hash1(p + vec2(1,1));

    // noise is -1 to 1, derivatives are not
    // deriving dx essentially means we only take all variables where u.x is present and viceversa for dz
    // y is treated as a constant since it does change based on xz
    // Look at blue notebook for written out derivation
    float noise = -1.0 + 2.0 * (a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y);
    float dx = 2.0 * ((b-a) + (a - b - c + d)*u.y);
    float dz = 2.0 * ((c - a) + (a - b - c + d) * u.x);
    return vec3(noise,dx,dz);
}

///////////////////////////////////////
// FBM
///////////////////////////////////////


// Changed to 11 layers because the detail looks better
float fbm_9( in vec2 x )
{
    // 9 levels of layered frequencies
    float f = 1.9; // frequency multiplier
    float s = 0.55; // amplitude regulation for smaller detail
    float a = 0.0;
    float b = 0.5; // initial amplitude
    for( int i=0; i<kFbmDetail; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m2*x; // scale then rotate input
    }

    return a;
}

// FBM + accumulated derivatives
vec3 fbmd_9( in vec2 x )
{
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;
    vec2  d = vec2(0.0);
    mat2  m = mat2(1.0,0.0,0.0,1.0);
    for( int i=0; i<kFbmDetail; i++ )
    {
        vec3 n = noised(x);
        a += b*n.x;          // accumulate values
        d += b*m*n.yz;       // accumulate derivatives
        b *= s;
        x = f*m2*x;
        m = f*m2i*m;         // rotate counter clockwise to account for the initial rotations
    }

    return vec3( a, d );
}

/////////////////////////////////////
// SDF
/////////////////////////////////////

float sdSphere( in vec3 p, in float r)
{
    return length(p) - r;
}
float sdRhombus( in vec2 p, in vec2 b, in float r )
{
    vec2 q = abs(p);
    float h = clamp( (-2.0*ndot(q,b) + ndot(b,b) )/dot(b,b), -1.0, 1.0 );
    float d = length( q - 0.5*b*vec2(1.0-h,1.0+h) );
    d *= sign( q.x*b.y + q.y*b.x - b.x*b.y );
    return d - r;
}

float usdBox( in vec3 p, in vec3 b )
{
    return length( max(abs(p)-b,0.0 ) );
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdBox( float p, float b )
{
  return abs(p) - b;
}


////////////////////////////////////////////////////////
// General functions
///////////////////////////////////////////////////////

float opRepLim( in float p, in float s, in float lima, float limb, out float id )
{
    id = round(p/s);
    return p-s*clamp(id,-lima,limb);
}

vec2 opRepLim( in vec2 p, in float s, in vec2 lim )
{
    return p-s*clamp(round(p/s),-lim,lim);
}

vec2 opRepLim( in vec2 p, in float s, in vec2 limmin, in vec2 limmax )
{
    return p-s*clamp(round(p/s),-limmin,limmax);
}

vec2 rotate45(in vec2 v)
{
    // rotation matrix = vec2(x * cos(a) - y * sin(a), x * sin(a) + y * cos(a));
    // Angle of 45 is 1/sqrt(2) = 0.7
    // factor out the 0.7 and you get vec2(x - y, x + y) * 0.7;
    // https://www.youtube.com/watch?v=sl9x19EnKng
    return vec2(v.x - v.y, v.x + v.y) * 0.707107;
}

vec3 fog( in vec3 col, in float t)
{
    vec3 expo = exp2(-0.00015 * t * vec3(1.,2.,4.0));
    return col * expo + (1.0 - expo)*vec3(0.55,0.55,0.58); // fog color
}

const vec2 fbmOffset = vec2(-0.0,-0.0);


vec2 mapTerrain( in vec2 p )
{

    // NOTE: .12 is kind of arbitrary, not sure why this is used yet.

    // Calculate random height at sample point
    // scale samplepoint down to fit within 2000unit length
    float fbmHeight = fbm_9(p / 2000.0 + fbmOffset);

    // Flag that marks when the ray is close to a cliff
    // this flag will slow down the size of the march steps when close
    float cliffDist = 1.0 - smoothstep(0.12, 0.13, abs(fbmHeight + 0.12));

    // scale fbm[-1,1] back into world coords
    fbmHeight = 600.0 * fbmHeight + 600.0; // at -1 = 0, at 1 = 1200

    // Stretch cliffs
    fbmHeight += 50.0 * smoothstep(552.0, 594.0, fbmHeight);

    // flatten a pad under the temple
    vec2 local = p - vec2(2294.0, 7638.0);    // temple center (xz)
    local = rotate45(local);
    vec2 fp = abs(local) - vec2(50.0, 25.0);
    float inside = max(fp.x, fp.y);
    float k = smoothstep(0.0, 6.0, inside);
    float padHeight = 382.0;
    fbmHeight = mix(padHeight, fbmHeight, k);

    return vec2(fbmHeight, cliffDist);
}

vec4 mapTerrainD( in vec2 p )
{
    // Get fbm value + derivatives
    vec3 fbmd = fbmd_9( p / 2000.0 + fbmOffset);
    // derive xz
    fbmd.x = 600.0 * fbmd.x + 600.0; // x is the fbm which is unchanged
    fbmd.yz = 600.0 * fbmd.yz;

    vec2 cliff = smoothstepd(550.0,600.0, fbmd.x);
    fbmd.x = fbmd.x + 50.0 * cliff.x;
    fbmd.yz = fbmd.yz + 50.0 * cliff.y * fbmd.yz;

    // Correct for the downscaling. Chainrule requires the derivative to also be div
    fbmd.yz /= 2000.0;

    // crossproduct of the xz tangent vectors gives the normal
    // results in -fbmd.yz
    return vec4(fbmd.x, normalize(vec3(-fbmd.y,1.0,-fbmd.z)));
}

float mapTemple(in vec3 p)
{
    vec3 basePos = p - vec3(2242.0,404.0,7680.0);
    float pilRad = 3.2;

   // supporting pillars
   // left
   vec3 bPos1 = basePos - vec3(-10.0,-39.0,-17.0);
   bPos1.xz = rotate45(bPos1.xz);
   float d = sdBox(bPos1,vec3(5.0,4.0,5.0) - 0.2) - 0.2;
   float d1 = length(bPos1.xz) - pilRad;
   d1 = d1 - 0.1 * (sin(16.0 * atan(bPos1.x,bPos1.z)));
   d1 = max(d1, p.y - 378.0);
   d = min(d, d1);

   // TODO calc one and use multiple
   // right
   vec3 bPos2 = basePos - vec3(40.0,-15.0,33.0);
   bPos2.xz = rotate45(bPos2.xz);
   d1 = length(bPos2.xz) - pilRad - 0.1 * (sin(16.0 * atan(bPos2.x,bPos2.z)));
   d1 = max(d1, p.y - 377.0);
   d1 = max(d1, -p.y + 350.0);
   d = min(d1,d);
   d1 = sdBox(bPos2 - vec3(0.0,-40.0,0.0),vec3(5.0,8.0,5.0) - 0.2) - 0.2;

    d = min(d,d1);

    // temple body
    vec3 q = p;
    vec3 bodyPos = q - vec3(2294.0,382.0,7638.0);
    bodyPos.xz = rotate45(bodyPos.xz);
    d1 = sdBox(bodyPos,vec3(55.0,5.0,35.0));
    //d = min(d1,d);

    // pillars on the body
    q =  basePos - vec3(57.0,0.0,-41.0);
    q.xz = rotate45(q.xz);
    q.xz = opRepLim(q.xz, 15.0, vec2(3.0,2.0));
    pilRad += 0.15 * pow(0.5 + 0.5 * cos(q.y), 0.12) - 0.15;
    float h = clamp(q.y / 40.0, 0.0,1.0);
    pilRad -= 1.2 * h;
    d1 = length(q.xz) - pilRad;
    d1 *= 0.7;
    d1 = max(-p.y + 390.0, d1);
    d1 = max(d1, q.y - 35.0);
    d1 = d1 - 0.1 * (sin(16.0 * atan(q.x,q.z)));
    d = min(d,d1);


    // pillar base box
    d1 = sdBox(abs(q - vec3(0.0,10.0,0.0)) - vec3(0.0,25.5,0.0), vec3(5.0,1.6,5.0) - 0.2) - 0.2;
    d = min(d,d1);
    // carve out inner pillars
    d = max(-sdBox(bodyPos - vec3(2.0,50.0,5.0), vec3(38.0,55.0,22.0)), d);

    // Stairs
    vec3 tile = vec3(4.8, 3.1, 4.8);

    q = bodyPos - vec3(-1.0, 3.0, -1.0);
    q.xz = opRepLim(q.xz, 10.0, vec2(5.0, 4.0));
    d1 = sdBox(q - vec3(0.0, -1.0, 0.0), tile - 0.2) - 0.2;
    d = min(d, d1);

    q = bodyPos - vec3(-0.0, -1.0, -5.0);
    q.xz = opRepLim(q.xz, 10.0, vec2(6.0, 5.0));
    d1 = sdBox(q - vec3(0.0, -1.0, 0.0), tile - 0.2) - 0.2;
    d = min(d, d1);

   // q = bodyPos - vec3(-2.0, -3.0, -10.0);
   // q.xz = opRepLim(q.xz, 10.0, vec2(7.0, 6.0));
   // d1 = sdBox(q - vec3(0.0, -1.0, 0.0), tile - 0.2) - 0.2;
   // d = min(d, d1);


  //  d1 = sdBox(q - vec3(0.0,-7.0,2.0), vec3(68.0,2.6,40.0));
   // d = min(d,d1);



    // Roof
    vec3 roofPos = bodyPos;
    float roofPeak = 59.5 + 12.0;
    d1 = max(sdRhombus(roofPos.yz - vec2(roofPeak, 0.0), vec2(12.0, 50.0), 1.0), -roofPos.y + roofPeak - 2.0);
    d1 = max(d1, sdBox(roofPos - vec3(0.0,roofPeak,0.0), vec3(59.2,12.0,47.0)));
    d = min(d1,d);

    // Triangle cutout
    float ped = sdRhombus(roofPos.zy - vec2(0.0, roofPeak - 6.0), vec2(45.0, 12.0), 1.0);
    ped = max(ped, sdBox(abs(roofPos.x) - 56.0, 4.0));
    d = max(d, -ped);

    // Cuts into roof
    vec3 gpos = roofPos - vec3(0.0, roofPeak + 1.0, 0.0);
    gpos.z = opRepLim(vec2(gpos.z, 0.0), 9.0, vec2(5.0, 0.0)).x;
    float grv = sdBox( vec3( abs(gpos.x) - 56.0, gpos.y, gpos.z ), vec3(4.0, 10.0, 0.6) ) - 0.05;
    d = max( d, -grv );

    // roof blocks, 2 layers
    q = bodyPos - vec3(-1.0, 64.0, -1.0);
    q.xz = opRepLim(q.xz, 10.1, vec2(4.7, 3.8));
    d1 = sdBox(q - vec3(0.0, -1.0, 0.0), tile - 0.4) - 0.4;
    d = min(d, d1);

    q = bodyPos - vec3(-1.0, 68.0, -1.0);
    q.xz = opRepLim(q.xz, 11.0, vec2(4.8, 3.9));
    d1 = sdBox(q - vec3(0.0, -1.0, 0.0), tile - vec3(0.0,0.5,0.0) - 0.4) - 0.4;
    d = min(d, d1);




    return d;

}

vec2 raymarchScene(in vec3 ro, in vec3 rd, float tmin, float tmax)
{

    // straight forward raymarching.

    // Sample the hight and step based on distance between pos and terrain
    float t = tmin;
    float id = 1.0;
    for(int i=0; i<400; i++) {
        vec3 pos = ro + t*rd;


        float d = mapTemple(pos);
        float dis = pos.y - mapTerrain(pos.xz).x;
        id = d < dis ? 0.0 : 2.0;
        dis = min(d, dis);
        //dis = d;

        if(dis < 0.001*t) break;
        t += dis * 0.8 * (1.0 - 0.75*mapTerrain(pos.xz).y);
        if(t > tmax) break;
    }
    if(t > tmax) return vec2(-1.0, 1.0);
    return vec2(t, id);
}

float terrainShadow( in vec3 ro, in vec3 rd, in float mint)
{
    // Shoot a ray from the point in space to the sun
    // if we're close to the surface small shadow, if we're far its fully lit.
    float res = 1.0;
    float t = mint;
    for(int i = 0; i < 128; ++i)
    {
        vec3 pos = ro + rd * t;
        float height = mapTerrain(pos.xz).x;
        float dist = pos.y - height;
        res = min(res, 32.0 * dist / t);
        if(res < 0.0001 || pos.y > kMaxHeight ) break;
        t += clamp(dist, 0.5 + t * 0.05, 25.0);
    }
    return clamp(res, 0.0,1.0);
}


float templeShadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.5;
    for( int i=0; i<64; i++ )
    {
        float h = mapTemple( ro + t*rd );
        res = min( res, k*max(h,0.0)/t );
        if( res<0.0001 ) break;
        t += clamp(h, 0.5, 20.0);
    }
    return clamp(res,0.0,1.0);
}


float templeOcc( in vec3 pos, in vec3 nor )
{
    float occ = 0.0, sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.1 + 1.5*float(i)/4.0;
        float d = mapTemple( pos + h*nor );
        occ += (h-d)*sca;
        sca *= 0.85;
    }
    return clamp( 1.0 - 1.2*occ, 0.0, 1.0 );
}


vec3 renderSky( in vec3 ro, in vec3 rd)
{
    vec3 col = vec3(0.4,0.6,1.3) - 0.4 * rd.y;
    float t = (2500.0 - ro.y)/rd.y; // derived from pos = 2500
    float intensity = 0.4;
    if(t>0.0)
    {
        vec2 uv = (ro + rd * t).xz;
        float fbm = fbm_9(uv*0.0015); // scaled down to get bigger clouds
        float remap = smoothstep(-0.4,0.6, fbm); // remap the fbm value from -1,1 to 0,1. controls how fuzzy they are
        col = mix(col, vec3(1.0), intensity * remap); // high fbm value becomes white, low onces keep sky color
    }

    return col;
}
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 calcNormal(in vec3 p, in float t)
{
       // changed: clamp epsilon so it never falls below the float-precision grid at world scale
float e = max(0.0001*t, 0.02);
vec3 ep = vec3(e, 0.0, 0.0);
       vec3 n;
       n.x = mapTemple(p+ep.xyy) - mapTemple(p-ep.xyy);
       n.y = mapTemple(p+ep.yxy) - mapTemple(p-ep.yxy);
       n.z = mapTemple(p+ep.yyx) - mapTemple(p-ep.yyx);
       return normalize(n);
}
mat2 rotate2D(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 tot = vec3(0.0);

    for( int m=0; m<2; m++ )
    for( int n=0; n<2; n++ )
    {
        // Sub-pixel sample offsets: a 2x2 grid rotated by a FIXED angle
        // ("rotated grid" AA). The original rotated it by iFrame*2.4 every frame;
        // without temporal accumulation that makes every frame slightly different,
        // which shows up as flicker on the fine terrain detail now that the camera
        // stands still. atan(0.5) ~ 26.6 deg spreads the 4 samples so no two share
        // a row or column, which smooths near-horizontal and near-vertical edges best.
        const float a = 0.4636476;
        mat2 jit = mat2(cos(a),-sin(a),sin(a),cos(a));
        vec2 o = jit * ((vec2(float(m),float(n))+0.5)/2.0 - 0.5);

        // pixel coordinates
        // vec2 o = vec2(float(m),float(n)) / float(2.0) - 0.5;
        vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/iResolution.y;
        float time = iTime;

        vec3 offs = vec3(20.0,0.0,60.0);
        offs = vec3(0.0);

        // camera: fixed position, the view direction comes from the mouse drag
        vec3 ro = vec3(2271.0, 401.5, 7856.0) - offs;
        vec3 ta = vec3(81.0, 403.5, -21.0);

        // Split the original view direction into yaw (around y, 0 = looking down +z)
        // and pitch (up/down), so the drag can rotate around it.
        vec3 baseDir = normalize(ta - ro);
        float yaw   = atan(baseDir.x, baseDir.z);
        float pitch = asin(baseDir.y);

        // Drag distance in pixels -> radians. Dividing by the height keeps the speed the
        // same at any render resolution; 1.2 rad per screen height roughly matches the
        // vertical field of view (fl = 1.5), so the scene follows the cursor.
        // "Grab" style: drag right -> the scene moves right (view turns left), drag up ->
        // the scene moves up (view tilts down). Pitch is clamped so it never flips over.
        vec2 look = iMouse.xy / iResolution.y * 1.2;
        yaw  += look.x;
        pitch = clamp(pitch - look.y, -1.0, 1.2);

        // Rebuild the target one unit in front of the camera.
        ta = ro + vec3(cos(pitch)*sin(yaw), sin(pitch), cos(pitch)*cos(yaw));

        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta, 0.0 );

        // ray direction
        float fl = 1.5;
        vec3 rd = ca * normalize( vec3(p,fl) );


        // background
        vec3 col = renderSky(ro,rd);

        float resT = 2000.0;
        float obj = 0.0; // 1 Sky, 2 terrain, 3 trees

        // raymarch geometry
        const float tmax = 2000.0;
        vec2 t = raymarchScene(ro,rd,15.0, tmax);
        obj = t.y;

        if( t.x>0.0 )
        {
            resT = t.x;
        }

       // Temple
       if(obj < 0.5)
       {
           vec3 pos = ro + rd * resT;
           vec3 nor = calcNormal(pos, resT);

           vec3 tpos = pos - vec3(2242.0, 404.0, 7680.0);
           vec3 te   = textureBox( iChannel0, tpos*0.15, nor ).xyz;
           vec3 mate = (vec3(0.14,0.10,0.07) + 0.1*te) * 1.15;

           float occ = 0.3 + 0.7* templeOcc( pos, nor );
           float sha = templeShadow( pos+nor*0.5, kSunDir, 32.0 );
           vec3  bdir = normalize(vec3(-kSunDir.x, kSunDir.y, -kSunDir.z));

           float dif = clamp( dot(nor, kSunDir), 0.0, 1.0 ) * sha;     // direct sun
           float dom = clamp( 0.5 + 0.5*nor.y, 0.0, 1.0 );             // sky dome term
           float bak = clamp( dot(nor, bdir), 0.0, 1.0 );              // backlight / bounce
           float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 5.0 );     // fresnel rim

           vec3 lin  = 0.20 * mix( 0.1*vec3(0.1,0.2,0.1), vec3(0.7,0.9,1.5)*3.0, dom ) * occ; // sky ambient
                lin += 8.50 * vec3(1.0,0.9,0.8) * dif;                                        // sun
                lin += 0.27 * vec3(1.1,1.0,0.9) * bak * occ;                                  // bounce
           vec3 col_t = mate * lin;

           // specular sun glint on stone
           vec3  hal = normalize( kSunDir - rd );
           float spe = pow( clamp(dot(nor,hal),0.0,1.0), 16.0 ) * dif * (0.1+0.9*fre);
           col_t += spe * vec3(1.0,0.95,0.85) * 2.0;

           col = fog( col_t, resT );
       }

        // Terrain
        if(obj > 1.5)
        {
            vec3 pos = ro + rd * resT;
            vec3 n = mapTerrainD(pos.xz).yzw;

            // Shading
            float dif = clamp(dot(n, kSunDir), 0.0, 1.0);
            dif *= terrainShadow(pos + vec3(0.0,0.02,0.0), kSunDir, 0.02);
            col = vec3(0.18,0.12,0.10)*.85;


            // grass
            float gc = smoothstep(0.65,0.8, n.y);
            col = mix(col, vec3(0.08,0.1,0.0), gc);

            float ambSky = clamp(0.5 + 0.5 * n.y, 0.0, 1.0); // 1 + n.y / 2
            float lowFog = clamp( (pos.y - 280.0)/(400.0-280.0), 0.0,1.0); // define artificial darkening at certain height
            float backlight = clamp(dot(normalize(vec3(-kSunDir.x,kSunDir.y,-kSunDir.z)), n),0.0,1.0); // negate sundir to fake light bounces
            vec3 inLight = 0.2*mix(0.1*vec3(0.1,0.2,0.1), vec3(0.7,0.9,1.5) * 3.0, ambSky) * lowFog; // add ambient light based on steepness
            inLight += 8.5*vec3(1.0,0.9,0.8)*dif;
            inLight += 0.27 * vec3(1.1,1.0,0.9) * backlight * lowFog;
            col *= inLight;



            col = fog(col, resT);
        }


        // gamma
        tot += pow(col,vec3(0.45) );

    }
    tot /= float(4);

    // smoothstep color
    tot = tot*tot*(3.0-2.0*tot);

    // cheap dithering
    tot += sin(fragCoord.x*114.0)*sin(fragCoord.y*211.1)/512.0;



    fragColor = vec4( tot, 1.0 );
}
