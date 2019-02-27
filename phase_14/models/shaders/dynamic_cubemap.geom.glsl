#version 430

layout(triangles, invocations = 6) in;
layout(triangle_strip, max_vertices = 3) out;

out int gl_Layer;

/*
mat3 cubemap_dirs[6] = mat3[](
	mat3(0, 0, -1,
		 1, 0, 0,
		 0, -1, 0),
	mat3(0, 0, 1,
	     -1, 0, 0,
	     0, -1, 0),
	mat3(1, 0, 0,
		 0, 1, 0,
		 0, 0, 1),
	mat3(1, 0, 0,
	     0, -1, 0,
	     0, 0, -1),
	mat3(1, 0, 0,
	     0, 0, 1,
	     0, -1, 0),
	mat3(1, 0, 0,
	     0, 0, -1,
	     0, 1, 0)
);
*/

mat4 cubemap_dirs[6] = mat4[](mat4 (    0   ,  0    , 1.0   , 0 , 
										0   ,  1.0  , 0     , 0 ,
										-1.0 ,  0   , 0     , 0 ,
										0   ,  0    , 0     , 1.0 ),
										
					mat4 (    0   ,  0    , -1.0  , 0 , 
                            0   ,  1.0  , 0     , 0 ,
                            1.0 ,  0    , 0     , 0 ,
                            0   ,  0    , 0     , 1.0 ),
 //+Y/
        mat4 (    -1  ,  0    , 0     , 0 , 
                            0   ,  0    , -1.0  , 0 ,
                            0   ,  -1.0 , 0     , 0 ,
                            0   ,  0    , 0     , 1.0 ),
 //-Y/
        mat4 (     -1  ,  0    , 0     , 0 , 
                            0   ,  0    , 1.0   , 0 ,
                            0   ,  1.0  , 0     , 0 ,
                            0   ,  0    , 0     , 1.0 ),
 //+z/
        mat4 (    -1  ,  0    , 0     , 0 , 
                            0   ,  1    , 0     , 0 ,
                            0   ,  0    , -1    , 0 ,
                            0   ,  0    , 0     , 1.0 ),
 //-z/
        mat4 (    1   ,  0    , 0     , 0 , 
                            0   ,  1    , 0     , 0 ,
                            0   ,  0    , 1     , 0 ,
                            0   ,  0    , 0     , 1.0 ));

uniform mat4 p3d_ModelViewProjectionMatrixInverse;
uniform mat4 p3d_ModelMatrix;
uniform mat4 p3d_ViewMatrix;
uniform mat4 p3d_ProjectionMatrix;

void main()
{
	
	for (int j = 0; j < 3; j++)
	{
		gl_Layer = gl_InvocationID;
		// back into model space
		//vec4 pos = gl_in[j].gl_Position * p3d_ModelViewProjectionMatrixInverse;
		//pos *= p3d_ModelMatrix;
		//pos *= p3d_ViewMatrix * cubemap_dirs[gl_Layer];
		//pos *= p3d_ProjectionMatrix;
		
		gl_Position = gl_in[j].gl_Position;
		
		EmitVertex();
	}
	EndPrimitive();
}
