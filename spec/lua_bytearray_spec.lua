--====================================================================--
-- spec/lua_bytearray_spec.lua
--
-- Testing for lua-bytearray using Busted
--====================================================================--


package.path = './dmc_lua/?.lua;./spec/lib/dmc_lua/?.lua;' .. package.path


--====================================================================--
--== Test: Lua Byte Array
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== Imports


local ByteArray = require 'lua_bytearray'
local File = require 'lua_files'



--====================================================================--
--== Support Functions


local function createByteArray()
	local ba = ByteArray:new()
	ba.endian = ByteArray.ENDIAN_BIG
	return ba
end



--====================================================================--
--== Testing Setup
--====================================================================--


describe( "Module Test: lua_bytearray.lua", function()


	describe("Test: static function getBytes", function()

		it( "part of string", function()
			assert.is.equal( ByteArray.getBytes( "hello", 1, 3 ), "hel" )
		end)

		it( "part of string", function()
			assert.is.equal( ByteArray.getBytes( "hello", 1, 3 ), "hel" )
			assert.is.equal( ByteArray.getBytes( "hello" ), "hello" )
			assert.is.equal( ByteArray.getBytes( "hello", 3 ), "llo" )
		end)

	end)

	describe("Test: static function putBytes", function()

		it( "has index errors", function()
			assert.has.errors( function() ByteArray.putBytes( "hello", "world", 0 ) end )
			assert.has.errors( function() ByteArray.putBytes( "hello", "world", "3" ) end )
			assert.has.errors( function() ByteArray.putBytes( "hello", "world", 43 ) end )
		end)

		it( "inserts bytes at end", function()
			assert.is.equal( ByteArray.putBytes( "hello", "world" ), "helloworld" )
		end)

		it( "replaces at beginning", function()
			assert.is.equal( ByteArray.putBytes( "replace", "helloworld", 1 ), "helloworld" )
			assert.is.equal( ByteArray.putBytes( "replaceall", "helloworld", 1 ), "helloworld" )
			assert.is.equal( ByteArray.putBytes( "xxxxxworld", "hello", 1 ), "helloworld" )
		end)

		it( "replaces in middle", function()
			assert.is.equal( ByteArray.putBytes( "hellxxorld", "ow", 5 ), "helloworld" )
		end)

		it( "replaces at end", function()
			assert.is.equal( ByteArray.putBytes( "helloxx", "world", 6 ), "helloworld" )
			assert.is.equal( ByteArray.putBytes( "hello", "world", 6 ), "helloworld" )
		end)

	end)


	describe("Test: instantiation", function()

		local ba

		before_each( function()
			ba = ByteArray()
		end)

		it( "is a class of Byte Array", function()
			assert( ba, "failed to create byte array" )
			assert.is.equal( ba:isa(ByteArray), true )
		end)

		it( "starts with zero", function()
			assert.is.equal( ba.length, 0 )
			assert.is.equal( ba.bytesAvailable, 0 )
			assert.is.equal( ba.position, 1 )
		end)

		it( "has error when position greater than position", function()
			assert.has.errors( function() ba.position = ba.length + 2 end )
			assert.has.errors( function() ba.position = 0 end )
			assert.has.errors( function() ba.position = nil end )
		end)

	end)


	describe("Test: read/writeBoolean", function()

		local ba

		before_each( function()
			ba = ByteArray()
		end)

		it( "writes true and false", function()

			ba:writeBoolean( false )
			ba:writeBoolean( true )
			ba:writeBoolean( false )
			ba:writeBoolean( true )
			assert.is.equal( ba.bytesAvailable, 4 )

			assert.is.equal( ba:readBoolean(), false )
			assert.is.equal( ba:readBoolean(), true )
			assert.is.equal( ba:readBoolean(), false )
			assert.is.equal( ba:readBoolean(), true )
			assert.is.equal( ba.bytesAvailable, 0 )

			assert.has.errors( function() ba:readBoolean() end )

		end)

	end)


	describe("Test: readBuf", function()

		local ba

		before_each( function()
			ba = ByteArray()
		end)

		it( "returns empty string on 0", function()
			assert.is.equal( ba:readBuf( 0 ), "" )
		end)

		it( "has errors when reading empty buffer", function()
			assert.has.errors( function() ba:readBuf() end )
			assert.has.errors( function() ba:readBuf( 1 ) end )
		end)

		it( "re-reads when position reset", function()
			ba:writeBuf( "helloworld" )
			assert.is.equal( ba:readBuf( 5 ), "hello" )
			ba.position = 2
			assert.is.equal( ba:readBuf( 5 ), "ellow" )
			assert.is.equal( ba:readBuf( 3 ), "orl" )
			ba.position = 1
			assert.is.equal( ba:readBuf( 5 ), "hello" )
		end)

	end)


	describe("Test: writeBuf", function()

		local ba

		before_each( function()
			ba = ByteArray()
		end)

		it( "has error with incorrect position", function()
			ba:writeBuf( "helloworld" )
			assert.has.errors( function() ba.position = ba.length + 2 end )
			assert.has.errors( function() ba.position = 0 end )
			assert.has.errors( function() ba.position = nil end )
		end)

		it( "returns self on writeBuf", function()
			assert.is.equal( ba:writeBuf( "helloworld" ), ba )
		end)

		it( "property changes when writing to buffer", function()
			ba:writeBuf( "helloworld" )
			assert.is.equal( ba.length, 10 )
			assert.is.equal( ba.bytesAvailable, 10 )
			assert.is.equal( ba.position, 1 )
		end)

		it( "write buff overwrites other buffer", function()
			ba:writeBuf( "helloworld" )
			assert.is.equal( ba.length, 10 )
			assert.is.equal( ba.bytesAvailable, 10 )
			assert.is.equal( ba.position, 1 )
		end)

		it( "has errors when writing non-string to buffer", function()
			assert.has.errors( function() ba:writeBuf( 0 ) end )
		end)

	end)


	describe("Test: readBuf/writeBuf", function()

		local ba

		before_each( function()
			ba = ByteArray()
		end)

		it( "returns self on writeBuf", function()
			ba:writeBuf( "helloworld" )
			assert.is.equal( ba:readBuf( 5 ), "hello" )
		end)

		it( "property changes when reading/writing to buffer", function()
			ba:writeBuf( "helloworld" )
			assert.is.equal( ba.length, 10 )
			assert.is.equal( ba.bytesAvailable, 10 )
			assert.is.equal( ba.position, 1 )

			ba:readBuf( 5 )
			assert.is.equal( ba.length, 10 )
			assert.is.equal( ba.bytesAvailable, 5 )
			assert.is.equal( ba.position, 6 )
		end)

		it( "has errors when writing non-string to buffer", function()
			ba:writeBuf( "helloworld" )
			assert.is.equal( ba:readBuf( 5 ), "hello" )
			assert.is.equal( ba:readBuf( 5 ), "world" )
			assert.has.errors( function() ba:readBuf( 5 ) end )
		end)

	end)


	describe("Test: readBytes", function()

		local ba

		before_each( function()
			ba = ByteArray()
		end)

		it( "needs a byte array", function()
			assert.has.errors( function() ba:readBytes( "hello" ) end )
		end)

		it( "no changes with empty byte array", function()
			local ba2 = ByteArray()

			ba:writeBuf( "helloworld" )
			assert.is.equal( ba.length, 10 )
			assert.is.equal( ba.bytesAvailable, 10 )
			assert.is.equal( ba.position, 1 )

			ba:readBytes( ba2 )
			assert.is.equal( ba.length, 10 )
			assert.is.equal( ba.bytesAvailable, 10 )
			assert.is.equal( ba.position, 1 )
		end)


		it( "adds to length, doesn't move position", function()
			local ba2 = ByteArray()

			ba:writeBuf( "hello" )
			ba2:writeBuf( "world" )

			assert.is.equal( ba.length, 5 )
			assert.is.equal( ba.bytesAvailable, 5 )
			assert.is.equal( ba.position, 1 )

			ba:writeBytes( ba2 )
			assert.is.equal( ba.length, 5 )
			assert.is.equal( ba.bytesAvailable, 5 )
			assert.is.equal( ba.position, 1 )

			assert.is.equal( ba:readBuf( ba.length ), "world" )
		end)


		it( "adds to length, doesn't move position", function()
			local ba2 = ByteArray()

			ba:writeBuf( "hello" )
			ba2:writeBuf( "world" )

			ba:writeBytes( ba2, 3 )
			assert.is.equal( ba.position, 1 )
			assert.is.equal( ba.length, 7 )
			assert.is.equal( ba.bytesAvailable, 7 )

			assert.is.equal( ba:readBuf( ba.length ), "heworld" )
		end)

		it( "adds to length, doesn't move position", function()
			local ba2 = ByteArray()

			ba:writeBuf( "hello" )
			ba2:writeBuf( "worlds" )

			assert.is.equal( ba2.position, 1 )

			ba:writeBytes( ba2, 2, 4 )
			assert.is.equal( ba.length, 5 )
			assert.is.equal( ba.bytesAvailable, 5 )
			assert.is.equal( ba.position, 1 )

			assert.is.equal( ba:readBuf( ba.length ), "hworl" )
		end)

		it( "has error when reading beyond buffer limits", function()
			local ba2 = ByteArray()
			ba2:writeBuf( "worlds" )

			ba:writeBuf( "hello" )
			assert.has.errors( function() ba:readBytes( ba2, 1, ba2.length+1 ) end )
		end)

	end)


	describe("Test: search", function()

		local ba

		before_each( function()
			ba = ByteArray()
		end)

		it( "can search for a string", function()
			local s_pos, e_pos
			ba:writeBuf( "hello" )

			s_pos, e_pos = ba:search( 'e' )
			assert.is.equal( s_pos, 2 )
			assert.is.equal( e_pos, 2 )

			s_pos, e_pos = ba:search( 'llo' )
			assert.is.equal( s_pos, 3 )
			assert.is.equal( e_pos, 5 )

			s_pos, e_pos = ba:search( 'z' )
			assert.is.equal( s_pos, nil )

		end)


		it( "can search for a newline", function()
			local s_pos, e_pos
			ba:writeBuf( "hello\n\nworld" )

			s_pos, e_pos = ba:search( '\n\n' )
			assert.is.equal( s_pos, 6 )
			assert.is.equal( e_pos, 7 )

		end)

	end)

end)






