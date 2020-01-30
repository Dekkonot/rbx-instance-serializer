# Instance Serializer

This is the source code for my Instance Serializer plugin for Roblox.

The plugin takes the currently selected Instance(s) and turns them and their descendants into a format that can be run in Roblox to recreate them.

For example, if you had a part in Workspace that was 5x5x5, was fully red, and was at `10, 5, 10`, it would output this:

```lua
local Part = Instance.new("Part")
Part.Size = Vector3.new(5, 5, 5)
Part.CFrame = CFrame.new(10, 5, 10)
Part.Color = Color3.fromRGB(255, 0, 0)
Part.Parent = workspace
return Part
```

## Options

The plugin currently has four options to adjust how the serializer performs and what it outputs. They are listed below:

When `Minify Output` is on, the outputted source will be as compressed as possible. Thus, the above example would become:
```lua
local a=Instance.new"Part"
a.Size=Vector3.new(5,5,5)
a.CFrame=CFram.new(10,5,10)
a.Color=CFrame.fromRGB(255,0,0)
a.Parent=workspace
return a
```

When `Output Modules` is on, the outputted source will be parented inside a module. That is, if it were off, the example code would be inside a normal Script and omit the `return Part` line.

When `Parent main model` is on, the outputted source will have the root model parented. If it were off, the example snippet would ommit the `Part.Parent = workspace` line.

When `Serialize restricted properties` is on, restricted properties (those that can only be read/written by Plugins or the Command Bar) will be serialized along with normal properties. This is most apparent with Source, but there are other properties it affects.

## More Information

This is actually a remake of an older plugin of mine which did the exact same thing but was poorly made and didn't handle errors well. I believe this one is more scalable and handles issues (such as output that's too large) better.

This project was made for [Rojo](https://github.com/rojo-rbx/rojo) and is linted using [Selene](https://github.com/Kampfkarren/selene).