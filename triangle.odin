package main

import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

// odin run triangle.odin -file

WIDTH :: 500
HEIGHT :: 500
TITLE :: "Triangle"

vs_source :: `
#version 460 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

out vec4 vertexColor;

void main() {
	gl_Position = vec4(aPos, 1.0);
	vertexColor = vec4(aColor, 1.0);
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

	vertices := [?]f32 {
		-0.5, -0.5, 0.0, 1.0, 0.0, 0.0, // left
		0.5, -0.5, 0.0, 0.0, 1.0, 0.0, // right
		0.0, 0.5, 0.0, 0.0, 0.0, 1.0, // top
	}

	vbo: u32
	gl.CreateBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)
	gl.NamedBufferStorage(vbo, size_of(vertices), &vertices, gl.DYNAMIC_STORAGE_BIT)

	vao: u32
	gl.CreateVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)

	gl.EnableVertexArrayAttrib(vao, 0)
	gl.EnableVertexArrayAttrib(vao, 1)
	gl.VertexArrayAttribFormat(vao, 0, 3, gl.FLOAT, false, 0)
	gl.VertexArrayAttribFormat(vao, 1, 3, gl.FLOAT, false, 3 * size_of(f32))
	gl.VertexArrayAttribBinding(vao, 0, 0)
	gl.VertexArrayAttribBinding(vao, 1, 0)

	gl.VertexArrayVertexBuffer(vao, 0, vbo, 0, 6 * size_of(f32))

	gl.UseProgram(program)
	gl.BindVertexArray(vao)

	gl.ClearColor(0.1, 0.2, 0.2, 1.0)

	for !glfw.WindowShouldClose(window) {
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS do glfw.SetWindowShouldClose(window, true)

		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}
