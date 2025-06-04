#version 410 core

out vec4 FragColor;

void main()
{
    // Make the light cube emit a bright white light
    FragColor = vec4(0.7, 0.7, 1.0, 1.0);
}