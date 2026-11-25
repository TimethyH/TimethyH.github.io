// Gears - IQ Tutorial (https://www.shadertoy.com/view/s3fGD8)
// Shadertoy "Image" tab, unchanged. iChannel0 = Shadertoy texture 4sXGRn, copied to textures/metal.jpg.
// AA is 2 like the published version: with AA 1, Chrome on Windows (ANGLE ->
// Direct3D) miscompiles the 1x1 loop and misses render as bright grey.

#define EXPAND 1.0
#define AA 2 // anti aliasing, set to 1 if lags

// Shader entirely created by following IQ's Tutorial:
// https://www.youtube.com/watch?v=sl9x19EnKng

float iSphere(in vec3 p, in float r)
{
    // simple distance sphere function
    // https://iquilezles.org/articles/distfunctions/
    float d = length(p) - r;
    return d;
}

float iBox(in vec2 p, in vec2 r)
{
    // Box SDF - IQ
    // https://iquilezles.org/articles/distfunctions/
    float edge = 0.01;
    return length(max(abs(p) - r, 0.0)) - edge;
}

float iCross(in vec3 p, in vec3 r)
{
    // mirror p around diagonal line
    // Instead of 2 boxes, rotate the axis when closer to z or x
    // https://iquilezles.org/articles/distfunctions/
    p = abs(p);

    p.xz = p.z > p.x ? p.zx : p.xz;
    return length(max(p - r, 0.0));
}

float iStick(in vec3 p, in float h)
{
    // https://iquilezles.org/articles/distfunctions/
    float d = max(0.0,p.y - h);
    return sqrt(p.x*p.x + p.z*p.z + d*d);
}


float sMax(in float a, in float b, in float k)
{
    // https://www.youtube.com/watch?v=sl9x19EnKng
    // This function is derived by finding where derivatives of a and b are the same
    // Based on that and grouping terms, we find this function.
    // we do k - abs(a-b) because we want full effect when a-b = 0 and no effect when outside of k
    float d = max(k - abs(a-b), 0.0);
    return max(a,b) + (0.25/k)*d*d;

}

vec2 rotate45(in vec2 v)
{
    // rotation matrix = vec2(x * cos(a) - y * sin(a), x * sin(a) + y * cos(a));
    // Angle of 45 is 1/sqrt(2) = 0.7
    // factor out the 0.7 and you get vec2(x - y, x + y) * 0.7;
    // https://www.youtube.com/watch?v=sl9x19EnKng
    return vec2(v.x - v.y, v.x + v.y) * 0.707107;
}

vec4 gear( in vec3 p, in float time, in float offset)
{


   float teethCount = 12.0;
   float pi2 = 6.2831;

   // rotate p around xz axis
   float rot = 2.0 * time * sign(p.y) + offset * pi2 / teethCount * 0.5; // offset rotation by half the distance of the teeth
   p.xz = mat2(cos(rot), -sin(rot), sin(rot), cos(rot)) * p.xz;

   // only evaluate positive plane values
   p.y = abs(p.y);

   // Repeat teeth

   float angle =  pi2 / teethCount;
   float sector = round(atan(p.z,p.x) / angle);
   vec3 q = p;
   float sAngle = sector * angle;
   q.xz = mat2(cos(sAngle), -sin(sAngle), sin(sAngle), cos(sAngle)) * q.xz;

   // Teeth evaluation
   float d1 = iBox(q.xz - vec2(0.17,0.0),vec2(0.04,0.018));

   // Circle connecting the teeth
   float d2 = abs(length(p.xz) - 0.155) - 0.018;

   d1 = min(d1,d2);


   // cross holding the gears
   d2 = iCross(p- vec3(0.0,max(cos(time) * EXPAND,0.48),0.0), vec3(0.15,0.005,0.005)) - 0.005;

   d1 = min(d1,d2);

   // Clipping the cylinder
   float c = length(p);
   // Make the indented ring on the gear
   // TODO: understand why this line works the way it does.
   float de = -0.0015*clamp(600.0*abs(dot(q.xz,q.xz)-0.155*0.155),0.0,1.0);
   float d = sMax(d1, abs(c- max(cos(time) * EXPAND, 0.5))-0.03+de, 0.005);

   // Stick that connects gears
   d2 = iStick(p, min(1.0 - cos(time) * EXPAND,0.5)) - 0.01;
   d = min(d,d2);

   d = min( d, iSphere(q-vec3(0.0,0.12,0.0),0.025) );

   return vec4(d,p);
}

vec4 map( in vec3 p, in float time )
{
    // calculate 1 gear but move the axis around based on which is closest.

    // TODO: The axis ordering does not make 100% sense yet
    vec4 d = vec4(iSphere(p,0.12), p);

    vec3 qa = abs(p);
    qa = (qa.x>qa.y && qa.x>qa.z) ? p.zxy : (qa.z>qa.y) ? p.yzx : p.xyz;

    // X rotation
    vec3 qx = vec3(rotate45(p.zy), p.x); if(abs(qx.x) > abs(qx.y)) qx = qx.zxy;

    // Y rotation
    vec3 qy = vec3(rotate45(p.xz), p.y); if(abs(qy.x) > abs(qy.y)) qy = qy.zxy;

    // Z rotation
    vec3 qz = vec3(rotate45(p.yx), p.z); if(abs(qz.x) > abs(qz.y)) qz = qz.zxy;

    vec4 t;
    t = gear(qa, time, 0.0); if(t.x < d.x) d = t;
    t = gear(qx, time, 1.0); if(t.x < d.x) d = t;
    t = gear(qy, time, 1.0); if(t.x < d.x) d = t;
    t = gear(qz, time, 1.0); if(t.x < d.x) d = t;

    return d;

}



vec4 intersect( in vec3 ro, in vec3 rd, in float time )
{
    vec4 res = vec4(-1);
    float t = 0.0;
    float tMax = 1000.0;

    for(int i = 0; i < 256 && t < tMax; ++i )
    {
        vec4 d1 = map(ro + t * rd, time);
        if(d1.x< 0.0001)
        {
            res = vec4(t,d1.yzw);
            break;
        }
        t += d1.x;
    }
    return res;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 calcNormal(in vec3 p, in float time)
{
       vec3 ep = vec3(0.0001,0.0,0.0);
       vec3 n;
       n.x = map(p+ep.xyy, time).x - map(p-ep.xyy, time).x;
       n.y = map(p+ep.yxy, time).x - map(p-ep.yxy, time).x;
       n.z = map(p+ep.yyx, time).x - map(p-ep.yyx, time).x;
       return normalize(n);
}

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, in float k, in float time )
{
    float res = 1.0;

    // raymarch
    float tmax = 2.0;
    float t    = 0.001;
    for( int i=0; i<64; i++ )
    {
        float h = map( ro + rd*t, time ).x;
        res = min( res, k*h/t );
        t += clamp( h, 0.012, 0.2 );
        if( res<0.001 || t>tmax ) break;
    }

    return clamp( res, 0.0, 1.0 );
}



float calcAO( in vec3 pos, in vec3 nor, in float time )
{
    // Essentially shoots a ray from the pos in the normal direction
    // If there is geometry closer than h, then the geometry is occluded
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos+h*nor, time ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 total = vec3(0);
    for(int i = 0; i < AA; ++i)
    {
        for(int j = 0; j < AA; ++j)
        {


            // Normalized pixel coordinates (from 0 to 1)
            vec2 uv = (2.0*fragCoord-iResolution.xy) / iResolution.x;

            float an = 6.2831 * iTime / 40.0;
            float zoom = 1.0;
            vec3 lookAt = vec3(0.0,0.0,0.0);
            vec3 ro = lookAt + vec3(1.3 * cos(an), 0.5, 1.2 * sin(an));

            mat3 cam = setCamera(ro, lookAt, 0.0);
            vec3 rd = cam * normalize(vec3(uv, zoom));

            vec4 t = intersect(ro, rd, iTime);


            vec3 col = vec3(1.0 + rd.y) * 0.05;

            if(t.x > 0.0)
            {
                vec3 p = ro + rd * t.x;
                vec3 n = calcNormal(p, iTime);
                col = vec3(1.0);

                // Occlusion
                //float occ = max(cos(iTime) * EXPAND,0.55) + 0.45 * dot(n,normalize(p));

                // Darken inside
                float len = length(p);
                float occ = 0.1 + 0.9 * clamp(0.5 + 0.5 * dot(n,(p/len)),0.0,1.0);
                occ *= 0.1 + 0.9 * clamp(len * 2.0, 0.0, 1.0);

                float ao = calcAO(p,n,iTime) * occ;
                float occlusion = (0.1 + 0.9 * clamp(length(p) / min(1.0 - (0.1 + 0.9 * cos(iTime) * EXPAND), 0.5),0.0,1.0)) * ao;



                // biplanar texture mapping
                // adding the texture from 2 dimensions
                vec3 tex = 0.5 * texture(iChannel0, t.yz).xyz +
                                0.5 * texture(iChannel0, t.yw).xyz;
                vec3 material = 0.22 * tex;
                material = mix(material, vec3(1.0,0.4,0.2), 1.0-smoothstep(0.121,0.123, length(p)));
                vec3 f0 = material;
                float ks = clamp(1.5 * tex.x, 0.0,1.0);
                float kd = (1.0 - ks) * 0.125;


                // lighting happens in linear space (^2 space)
                col = vec3(0.0);

                // Top Light
                col = vec3(0.0);
                {
                    vec3 lcol = vec3(0.19,0.22,0.24) * 5.0;
                    float diff = 0.4 + 0.6 * n.y;
                    diff *= occlusion;
                    vec3 ref = reflect(rd,n);
                    vec3 spec = vec3(1.0)*smoothstep(-1.0 + 1.5*occ,0.6,ref.y);
                    float fres = clamp(1.0 + dot(rd,n),0.0,1.0);
                    spec  *= f0 + (1.0-f0)*pow(fres,5.0);
                    spec *= 6.0;
                    col += kd * material * lcol * diff;
                    col += ks * lcol * spec * diff;

                }

                // Warm Side Light
                {
                    vec3 lpos = normalize(vec3(0.7,0.1,0.4));
                    vec3 lcol = vec3(1.0,0.7,0.5);
                    float diff = dot(n,lpos);
                    float sha = calcSoftshadow(p, lpos, 32.0, iTime );
                    vec3 hal = normalize(lpos - rd);
                    vec3 spec = vec3(1.0)* pow(clamp(dot(hal,n),0.0,1.0),16.0);
                    spec *= f0 + (1.0-f0)*pow(1.0-clamp(dot(hal,lpos),0.0,1.0),5.0);

                    col += kd * material * lcol * diff * sha;
                    col += ks * 8.0 * (lcol + vec3(0.0,0.1,0.2)) * diff * sha * spec * 3.14;
                }

                // Bottom Light
                {
                    float diff = clamp(0.5 - 0.5 * n.y, 0.0,1.0);
                    col += kd * material * diff * occ;
                }



            }
            // This lets us work in Gamma space
            // This pow curve brings the colors to perseptual space from linear space ( essentially sqrt )
            // Texture load is sRGB which is close to perseptual space
            total += pow(col,vec3(0.45));
        }
     }

    total /= float(AA*AA); // div by 2^2

    // S-Curve smooth step
    // Making derivatives 0 at 0 and 1
    total = clamp(total,0.0,1.0);
    total = total*total*(3.0-2.0*total);

    // Output to screen
    fragColor = vec4(total,1.0);
}
