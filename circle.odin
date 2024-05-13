package main

import "core:fmt"
import "core:math"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

// odin run circle.odin -file
// https://faun.pub/draw-circle-in-opengl-c-2da8d9c2c103

WIDTH :: 500
HEIGHT :: 500
TITLE :: "Circle"

vs_source :: `
#version 460 core

layout (location = 0) in vec3 aPos;

out vec4 vertexColor;

void main() {
	gl_Position = vec4(aPos, 1.0);
	vertexColor = vec4(1.0, 0.0, 0.0, 1.0);
}`

fs_source :: `
#version 460 core

in vec4 vertexColor;
out vec4 FragColor;

void main() {
	FragColor = vertexColor;
}`

main :: proc() {
	if !glfw.Init() {
		panic("Failed to initialize GLFW")
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.RESIZABLE, 0)

	window := glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)
	if window == nil {
		panic("Failed to create GLFW window")
	}

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	program, ok := gl.load_shaders_source(vs_source, fs_source)
	if !ok {
		msg, shader_type := gl.get_last_error_message()
		fmt.panicf("Shader program creation error! %s %v\n", msg, shader_type)
	}
	defer gl.DeleteProgram(program)

	// Start: [Build Circle]

	// vertex_count := 4
	// vertex_count := 32
	// vertex_count := 64
	vertex_count := 128

	vertices := make([dynamic]f32, 0, vertex_count * 3)
	defer delete(vertices)
	indices := make([dynamic]u32, 0, (vertex_count * 3) - (3 * 2))
	defer delete(indices)

	{
		radius := f32(1.0)
		angle := 360.0 / f32(vertex_count)
		triangle_count := vertex_count - 2;

		for i := 0; i < vertex_count; i += 1 {
			currentAngle := angle * f32(i);
			x := radius * math.cos(math.to_radians(currentAngle))
			y := radius * math.sin(math.to_radians(currentAngle))
			z := f32(0.0)

			append(&vertices, x, y, z);
		}

		for i := 0; i < triangle_count; i += 1 {
			append(&indices, u32(0));
			append(&indices, u32(i + 1));
			append(&indices, u32(i + 2));
		}
	}
	fmt.println("vertices", "sizeof:", len(vertices) * size_of(f32), "len:", len(vertices))
	fmt.println("indices", "sizeof:", len(indices) * size_of(u32), "len:", len(indices))
	// End: [Build Circle]

	vbo: u32
	gl.CreateBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)
	gl.NamedBufferStorage(vbo, len(vertices) * size_of(f32), &vertices[0], gl.DYNAMIC_STORAGE_BIT)

	ebo: u32
	gl.CreateBuffers(1, &ebo)
	defer gl.DeleteBuffers(1, &ebo)
	gl.NamedBufferStorage(ebo, len(indices) * size_of(u32), &indices[0], gl.DYNAMIC_STORAGE_BIT)

	vao: u32
	gl.CreateVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)

	gl.EnableVertexArrayAttrib(vao, 0)
	gl.VertexArrayAttribFormat(vao, 0, 3, gl.FLOAT, false, 0)
	gl.VertexArrayAttribBinding(vao, 0, 0)

	gl.VertexArrayVertexBuffer(vao, 0, vbo, 0, 6 * size_of(f32))
	gl.VertexArrayElementBuffer(vao, ebo);

	gl.UseProgram(program)
	gl.BindVertexArray(vao)

	gl.ClearColor(0.1, 0.2, 0.2, 1.0)

	for !glfw.WindowShouldClose(window) {
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS do glfw.SetWindowShouldClose(window, true)

		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_INT, nil)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}
