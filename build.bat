@echo off
echo Building into out/plugin.rbxmx
if not exist out (
    mkdir out
)
rojo build build.project.json -o out/plugin.rbxmx