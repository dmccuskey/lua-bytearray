# lua-bytearray

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "lua-bytearray"
	include: "../DMC-Lua-Library/snakemake/Snakefile"

module_config = {
	"name": "lua-bytearray",
	"module": {
		"files": [
				"lua_bytearray.lua",
				"lua_bytearray/exceptions.lua",
				"lua_bytearray/pack_bytearray.lua"
		],
		"requires": [
				"lua-error",
				"lua-objects"
		]
	},
	"tests": {
		"files": [
		],
		"requires": [
			"lua-error",
			"lua-objects"
		]
	}
}

register( "lua-bytearray", module_config )

