# Naming Conventions for Rojo Project

This document outlines the naming conventions for files in this Rojo project to ensure consistency and proper functionality.

## General Guidelines

- Use lowercase letters and underscores (`_`) to separate words in file names.
- Avoid using spaces or special characters in file names.

## Lua Scripts

- **Server Scripts**: Use the `.server.lua` extension for scripts that should run on the server.
  - Example: `example.server.lua`
- **Client Scripts**: Use the `.client.lua` extension for scripts that should run on the client.
  - Example: `example.client.lua`
- **Module Scripts**: Use the `.lua` extension for module scripts.
  - Example: `example.lua`

## Meta Files

- Use the `.meta.json` extension for meta files.
  - Example: `example.meta.json`

## JSON Models

- Use the `.model.json` extension for JSON model files.
  - Example: `example.model.json`

## Project Files

- Use the `.project.json` extension for project files.
  - Example: `default.project.json`

## Special Script Names

- **Init Scripts**: Use `init.server.lua`, `init.client.lua`, or `init.lua` to change the parent directory into a script instance.
  - Example: `init.server.lua` in a directory will make the directory a `Script` instance.

## Other File Types

- **Plain Text**: Use the `.txt` extension for plain text files.
  - Example: `example.txt`
- **JSON Modules**: Use the `.json` extension for JSON modules.
  - Example: `example.json`
- **TOML Modules**: Use the `.toml` extension for TOML modules.
  - Example: `example.toml`

By following these conventions, you ensure that Rojo can correctly interpret and sync your files with Roblox Studio.

Scripts
Rojo transforms any files with the lua extension into the various script instances that Roblox has.

Any file ending in .server.lua will turn into a Script instance.
Any file ending in .client.lua will turn into a LocalScript instance.
Any other .lua file will turn into a ModuleScript instance.
Rojo reserves three special script names. These scripts change their parent directory into a script instead of a folder:

init.server.lua will change its parent directory into a Script instance.
init.client.lua will change its parent directory into a LocalScript instance.
init.lua will change its parent directory into a ModuleScript instance.