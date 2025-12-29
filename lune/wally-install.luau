--!strict

local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local process = require("@lune/process")

type Options = {
	cwd: string?,
	env: { [string]: string }?,
}

local function run(program: string, params: { string }, options: Options?)
	stdio.write(stdio.style("bold"))
	print(`> {program} {table.concat(params, " ")}`)
	stdio.write(stdio.style("reset"))

	local result = process.exec(program, params, {
		shell = true,
		stdio = "forward",
		cwd = if options then options.cwd else nil,
		env = if options then options.env else nil,
	})

	if result.code ~= 0 then
		process.exit(result.code)
	end

	return result.stdout:gsub("\n$", "")
end

run("wally", { "install" })
for _, folderName in { "Packages", "DevPackages", "ServerPackages" } do
	if not fs.isDir(folderName) then
		fs.writeDir(folderName)
	end
end

run("rojo", { "sourcemap", "demo.project.json", "-o", "sourcemap.json" })

for _, folderName in { "Packages", "DevPackages", "ServerPackages" } do
	if fs.isDir(folderName) then
		run("wally-package-types", { "--sourcemap", "sourcemap.json", folderName })
	end
end
