# lua-bytearray

A byte buffer for Lua: write bytes at the end, read them back from a position that moves forward, and get an error you can catch when a read asks for more than the buffer holds. With the `pack` C module (lpack) it also reads and writes numbers and length-prefixed strings in a chosen byte order.

The API follows ActionScript's `ByteArray` (`readByte()`, `writeBoolean()`, `bytesAvailable`, ...). It was written for [dmc-websockets](https://github.com/dmccuskey/dmc-websockets), which collects socket data in one and reads frames out of it, but it's plain Lua 5.1 and runs anywhere:

```lua
local ba = ByteArray:new()
ba:writeBuf( "hello" )
print( ba:readBuf( 2 ), ba.bytesAvailable )  --> he	3
```

## Features

- Append bytes, strings, booleans; read them back in order, or reset the position and read again
- `bytesAvailable` says how much is left to read; reading past the end raises a `BufferError`
- Overwrite bytes at an index, copy bytes between arrays, search the buffer
- With lpack: integers, floats, doubles and strings with a 2-byte length, little-endian, big-endian or native
- A hex dump for debugging
- Pure Lua 5.1 (lpack is optional), built on [lua-class](https://github.com/dmccuskey/lua-class) and [lua-error](https://github.com/dmccuskey/lua-error); MIT licensed

## Quick Start

The following steps will get you up and running in about 5 minutes with Lua 5.1 on macOS or Linux. You will fill a byte array, read it back, and catch a read past its end.

Prerequisites: Lua 5.1 (`lua -v` shows `Lua 5.1.x`) and git.

### 1. Get the Code

In an empty folder:

```sh
git clone https://github.com/dmccuskey/lua-bytearray.git
```

The module is `lua-bytearray/dmc_lua/lua_bytearray.lua`, with its parts in `lua_bytearray/`. The folder also holds copies of `lua_class.lua` and `lua_error.lua`, which it requires.

### 2. Use It

Create `main.lua` in the same folder:

```lua
package.path = './lua-bytearray/dmc_lua/?.lua;' .. package.path
local ByteArray = require 'lua_bytearray'
local BufferError = require('lua_bytearray.exceptions').BufferError

local ba = ByteArray:new()
ba:writeBuf( "GET / HTTP/1.1\r\n" )
ba:writeByte( 0 )
ba:writeBoolean( true )
print( ba.length, ba.position, ba.bytesAvailable )

print( ba:search( "\r\n" ) )
print( ba:readBuf( 3 ), ba.position )

ba.position = 17
print( ba:readByte(), ba:readBoolean(), ba.bytesAvailable )

local ok, err = pcall( ba.readBuf, ba, 10 )
print( ok, err:isa( BufferError ), err.message )
```

Run it:

```sh
lua main.lua
```

```text
18	1	18
15	16
GET	4
0	true	0
false	true	Read surpasses buffer size
```

Writing doesn't move the position: it starts at 1 and only reads advance it. If it shows `module 'lua_bytearray' not found`, run it from the folder that holds `lua-bytearray/`.

To update, pull the repository again (`git -C lua-bytearray pull`).

### 3. Optional: Numbers and Strings

The typed methods need lpack, a C module loaded as `pack`. Install it with LuaRocks (`luarocks install lpack`), then run this as `typed.lua` (not `pack.lua`: a file of that name would be loaded in place of the module):

```lua
package.path = './lua-bytearray/dmc_lua/?.lua;' .. package.path
local ByteArray = require 'lua_bytearray'

local ba = ByteArray:new()
ba.endian = ByteArray.ENDIAN_BIG
ba:writeUShort( 513 ):writeInt( -7 ):writeDouble( 1.5 ):writeStringUShort( "hi" )
print( ba.length )
ba.position = 1
print( ba:readUShort(), ba:readInt(), ba:readDouble(), ba:readStringUShort() )
```

```text
18
513	-7	1.5	hi
```

Without lpack, `writeUShort` is `nil` (`attempt to call method 'writeUShort'`): the module loads without the typed methods and says nothing.

## How It Works

A byte array is a Lua string and a read position. Writes build a new string: appended at the end, or, with an index, laid over the bytes from that index on (growing the string if they run past its end). Reads return the bytes at the position and move it forward; `bytesAvailable` is the length minus what has been read. Nothing is ever removed, so to reuse an array for a stream, copy what's left into a new one (dmc-websockets does this with `writeBytes()` into an empty array).

## Reference

### The Module

`require 'lua_bytearray'` returns the `ByteArray` class, a lua-class class: create with `ByteArray:new( params )`, remove with `:destroy()`. `params.endian` sets `endian`. `ByteArray.__version` is the module's version, `'0.5.0'` (also `ba.version`).

`require 'lua_bytearray.exceptions'` returns `{ BufferError=... }`, the error class for reads past the end (a [lua-error](https://github.com/dmccuskey/lua-error) `Error`: `err.message`, `err:isa( BufferError )`). Other misuse, such as a wrong argument type or an index out of range, fails an `assert()` with a plain string.

### Properties

| property | is |
|---|---|
| `length` | Bytes in the buffer (read-only). |
| `position` | Index of the next byte to read, from `1` to `length + 1`. Set it to read again from an earlier point. |
| `bytesAvailable` | Bytes left to read: `length - position + 1` (read-only). |
| `endian` | Byte order of the typed methods: `ByteArray.ENDIAN_LITTLE`, `ByteArray.ENDIAN_BIG`, or `nil` (the default) for the machine's. The constants exist only with lpack. |

### Bytes and Strings

| method | does |
|---|---|
| `writeBuf( bytes, index )` | Appends the string `bytes`, or with `index` writes it over the bytes from `index` on. Returns the array. Alias `writeUTFBytes`. |
| `readBuf( len )` | Returns the next `len` bytes as a string. Alias `readUTFBytes`. |
| `writeByte( n )` / `readByte()` | One byte as a number, 0-255. |
| `writeChar( c )` / `readChar()` | One byte as a one-character string. `writeChar()` appends any string. |
| `writeBoolean( b )` / `readBoolean()` | One byte, `1` or `0`; any non-zero byte reads as `true`. |
| `writeBytes( ba, offset, length )` | Reads `length` bytes from array `ba` (from its position, moving it; default: all it has left) and writes them into this array at `offset` (default: appended at the end). Returns this array. |
| `readBytes( ba, offset, length )` | Reads `length` bytes from this array (from its position, moving it; default: all it has left) and writes them into `ba` at `offset` (default: appended at its end). Returns this array. |
| `search( pattern )` | `string.find()` on the whole buffer: returns the start and end index of the first match, or `nil`. A Lua pattern, not a plain string. |
| `toString()` | The whole buffer, whatever the position. |
| `toHex()` | Prints a hex dump of the buffer (16 bytes a line, with offsets and the characters); returns nothing. |

Every write returns the array, so writes chain: `ba:writeByte( 1 ):writeBuf( "x" )`. Every read raises a `BufferError` when fewer bytes are available than it needs.

`ByteArray.getBytes( str, index, length )` and `ByteArray.putBytes( str, bytes, index )` are the string functions behind them: `getBytes()` returns part of `str`, `putBytes()` returns `str` with `bytes` appended or written over it at `index`.

### Typed Values (With lpack)

Each `write...()` appends and returns the array; each `read...()` returns the value.

| methods | bytes, lpack format |
|---|---|
| `writeShort()` / `readShort()` | 2, signed |
| `writeUnsignedShort()` / `readUnsignedShort()`, aliases `writeUShort()` / `readUShort()` | 2, unsigned |
| `writeInt()` / `readInt()` | 4, signed |
| `writeUnsignedInt()` / `readUnsignedInt()`, aliases `writeUInt()` / `readUInt()` | 4, unsigned |
| `writeLong()` / `readLong()` | C `long`: 8 on 64-bit desktops, 4 on 32-bit (see Known Issues) |
| `writeUnsignedLong()` / `readUnsignedLong()`, aliases `...ULong()` | C `unsigned long`, as `long` |
| `writeFloat()` / `readFloat()` | 4 |
| `writeDouble()` / `readDouble()` | 8 |
| `writeUnsignedByte()` / `readUnsignedByte()`, aliases `...UByte()` | 1, 0-255 |
| `writeStringBytes( s )` / `readStringBytes( len )` | the string's bytes, no length |
| `writeStringUnsignedShort( s )` / `readStringUnsignedShort()`, aliases `...StringUShort()` | a 2-byte unsigned length, then the bytes |

`readMultiByte()` and `writeMultiByte()` raise `not implemented`.

## In Solar2D

[dmc-bytearray](https://github.com/dmccuskey/dmc-bytearray) is the Solar2D package of this module. The DMC Solar2D libraries load lua-bytearray as `lib.dmc_lua.lua_bytearray` from their `dmc_corona/lib/dmc_lua/` folder, part of [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library). dmc-websockets uses it for received data and frames, and catches its `BufferError` to wait for more data.

Solar2D doesn't include lpack (it isn't in Solar2D's source), so there the array has only the byte and string methods. dmc-websockets needs no more.

## Known Issues

- `search()` takes a Lua pattern (`'.'` matches any byte) and searches the whole buffer, not from the position.
- Every write copies the whole buffer (strings are immutable), and read bytes are never dropped: many small writes into a large array are slow.
- lpack is loaded silently: without it the typed methods and the `ENDIAN_*` constants are just missing, and any `pack.lua` on `package.path` is loaded in its place. `writeLong()`/`readLong()` use the platform's C `long` size, so data written on a 64-bit machine doesn't read back on a 32-bit one.

## Development

Only `dmc_lua/lua_bytearray.lua` and `dmc_lua/lua_bytearray/` are written here. [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) copies them into its `dmc_lua/` with its Snakemake build (the `Snakefile` here registers them and requires lua-class and lua-error), and the DMC Solar2D libraries copy them from there into `dmc_corona/lib/dmc_lua/`. `dmc_lua/lua_class.lua` and `dmc_lua/lua_error.lua` are copies from [lua-class](https://github.com/dmccuskey/lua-class) and [lua-error](https://github.com/dmccuskey/lua-error), and `spec/lib/dmc_lua/` holds copies of lua-files and a JSON shim for the tests; fix them there.

The tests are in `spec/`, for [busted](https://lunarmodules.github.io/busted/) under Lua 5.1. `spec/lua_pack_bytearray_spec.lua` needs lpack (and reads `spec/bin/s-goog.bin`); without it, its 8 tests of typed values error. From the repository's root folder:

```sh
busted spec
```

It ends with:

```text
46 successes / 0 failures / 0 errors / 0 pending : 0.012434 seconds
```

The tests cover `getBytes()`/`putBytes()`, the byte, string and boolean methods, `readBytes()`/`writeBytes()`, `search()`, reading a binary file with the typed methods, and a write-then-read of each typed method in each byte order; not `toHex()`.

## License

lua-bytearray is released under the [MIT License](LICENSE).
