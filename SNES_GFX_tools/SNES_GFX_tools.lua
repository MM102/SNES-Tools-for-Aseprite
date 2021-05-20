--SNES GFX Tools written by MM102

if app.apiVersion < 3 then
	app.alert("API version is outdated")
	return
end

local function doSpriteChecks(spr)
	if not spr then
		app.alert{title="Error", text="There is no sprite open", buttons="OK"}
		return false
	end
	if spr.colorMode ~= ColorMode.INDEXED then
		app.alert{title="Error", text="Sprite color mode needs to be indexed", buttons="OK"}
		return false
	end
	if (spr.width % 8) ~= 0 then
		app.alert{title="Error", text="Sprite width needs to be a multiple of 8", buttons="OK"}
		return false
	end
	if (spr.height % 8) ~= 0 then
		app.alert{title="Error", text="Sprite height needs to be a multiple of 8", buttons="OK"}
		return false
	end
	return true
end

----------------------------------------------------------------
--init stuff

local bitmode = "4BPP"
local importsettings = {overwrite = false}

----------------------------------------------------------------

local scriptPath = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SNES_GFX_tools\\")

----------------------------------------------------------------

function toBits(num,bits)
    -- returns a table of bits, most significant first.
    bits = bits or math.max(1, select(2, math.frexp(num)))
    local t = {} -- will contain the bits        
    for b = bits, 1, -1 do
        t[b] = math.fmod(num, 2)
        num = math.floor((num - t[b]) / 2)
    end
    return t
end

function string.fromhex(str)
	return (str:gsub('..', function (cc)
		return string.char(tonumber(cc, 16))
	end))
end

function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

function fileSize(file)
	local current = file:seek()      -- get current position
	local size = file:seek("end")    -- get file size
	file:seek("set", current)        -- restore position
	return size
end

local function makeChar4BPP(img,x,y)
	local pixelIterator = 0
	local rowIterator = 1
	local bitPlanes = {{{}},{{}},{{}},{{}}}
	for i in img:pixels(Rectangle(x, y, 8, 8)) do
		pixelIterator = pixelIterator + 1
		local pixelBits = toBits(i()%16,4)
		bitPlanes[1][rowIterator][#bitPlanes[1][rowIterator]+1] = pixelBits[4]
		bitPlanes[2][rowIterator][#bitPlanes[2][rowIterator]+1] = pixelBits[3]
		bitPlanes[3][rowIterator][#bitPlanes[3][rowIterator]+1] = pixelBits[2]
		bitPlanes[4][rowIterator][#bitPlanes[4][rowIterator]+1] = pixelBits[1]
		if pixelIterator == 8 and rowIterator < 8 then
			pixelIterator = 0
			rowIterator = rowIterator + 1
			bitPlanes[1][rowIterator] = {}
			bitPlanes[2][rowIterator] = {}
			bitPlanes[3][rowIterator] = {}
			bitPlanes[4][rowIterator] = {}
		end
	end
	for i = 1, 4 do
		for j = 1, 8 do
			bitPlanes[i][j] = string.format('%02X',tonumber(table.concat(bitPlanes[i][j]),2))
		end
	end
	local charOutput = ""
	for i = 1, 8 do
		charOutput = charOutput..bitPlanes[1][i]
		charOutput = charOutput..bitPlanes[2][i]
	end
	for i = 1, 8 do
		charOutput = charOutput..bitPlanes[3][i]
		charOutput = charOutput..bitPlanes[4][i]
	end
	return charOutput
end

local function makeChar2BPP(img,x,y)
	--just ignore bitplanes 3 and 4 :)
	local pixelIterator = 0
	local rowIterator = 1
	local bitPlanes = {{{}},{{}},{{}},{{}}}
	for i in img:pixels(Rectangle(x, y, 8, 8)) do
		pixelIterator = pixelIterator + 1
		local pixelBits = toBits(i()%4,4)
		bitPlanes[1][rowIterator][#bitPlanes[1][rowIterator]+1] = pixelBits[4]
		bitPlanes[2][rowIterator][#bitPlanes[2][rowIterator]+1] = pixelBits[3]
		bitPlanes[3][rowIterator][#bitPlanes[3][rowIterator]+1] = pixelBits[2]
		bitPlanes[4][rowIterator][#bitPlanes[4][rowIterator]+1] = pixelBits[1]
		if pixelIterator == 8 and rowIterator < 8 then
			pixelIterator = 0
			rowIterator = rowIterator + 1
			bitPlanes[1][rowIterator] = {}
			bitPlanes[2][rowIterator] = {}
			bitPlanes[3][rowIterator] = {}
			bitPlanes[4][rowIterator] = {}
		end
	end
	for i = 1, 4 do
		for j = 1, 8 do
			bitPlanes[i][j] = string.format('%02X',tonumber(table.concat(bitPlanes[i][j]),2))
		end
	end
	local charOutput = ""
	for i = 1, 8 do
		charOutput = charOutput..bitPlanes[1][i]
		charOutput = charOutput..bitPlanes[2][i]
	end
	return charOutput
end

local function importChar4BPP(data)
	local datastring = string.tohex(data)
	local bitPlanes = {{},{},{},{}}
	for i = 1,8 do
		bitPlanes[1][i] = tonumber(string.sub(datastring,((i-1)*4)+1,((i-1)*4)+2), 16)
		bitPlanes[2][i] = tonumber(string.sub(datastring,((i-1)*4)+3,((i-1)*4)+4), 16)
	end
	for i = 9,16 do
		bitPlanes[3][i-8] = tonumber(string.sub(datastring,((i-1)*4)+1,((i-1)*4)+2), 16)
		bitPlanes[4][i-8] = tonumber(string.sub(datastring,((i-1)*4)+3,((i-1)*4)+4), 16)
	end
	local char = {}
	for i = 1,8 do
		local bits1 = toBits(bitPlanes[1][i],8)
		local bits2 = toBits(bitPlanes[2][i],8)
		local bits3 = toBits(bitPlanes[3][i],8)
		local bits4 = toBits(bitPlanes[4][i],8)
		for j = 1,8 do
			char[#char+1] = tonumber(bits4[j]..bits3[j]..bits2[j]..bits1[j],2)
		end
	end
	local imageTarget = Image(8,8,ColorMode.INDEXED)
	for i = 1,64 do
		imageTarget:drawPixel(((i-1)%8), math.ceil(i/8)-1, char[i])
	end
	return imageTarget
end

local function importChar2BPP(data)
	local datastring = string.tohex(data)
	local bitPlanes = {{},{}}
	for i = 1,8 do
		bitPlanes[1][i] = tonumber(string.sub(datastring,((i-1)*4)+1,((i-1)*4)+2), 16)
		bitPlanes[2][i] = tonumber(string.sub(datastring,((i-1)*4)+3,((i-1)*4)+4), 16)
	end
	local char = {}
	for i = 1,8 do
		local bits1 = toBits(bitPlanes[1][i],8)
		local bits2 = toBits(bitPlanes[2][i],8)
		for j = 1,8 do
			char[#char+1] = tonumber(bits2[j]..bits1[j],2)
		end
	end
	local imageTarget = Image(8,8,ColorMode.INDEXED)
	for i = 1,64 do
		imageTarget:drawPixel(((i-1)%8), math.ceil(i/8)-1, char[i])
	end
	return imageTarget
end

----------------------------------------------------------------

local function doImport()
	app.transaction(
	function()
		if DLG_import.data.importfile == "Import" then
			return
		end
		if not app.fs.isFile(DLG_import.data.importfile) then
			app.alert{title="Error", text="Unable to open file.", buttons="OK"}
			return
		end
		if not app.fs.fileExtension(DLG_import.data.importfile) == "bin" then
			app.alert{title="Error", text="File is not a .bin file", buttons="OK"}
		end

		local input = io.open(app.fs.normalizePath(DLG_import.data.importfile), "rb")
		local inputSize = fileSize(input)

		local spr
		if importsettings.overwrite == true then
			spr = app.activeSprite
			if not spr then
				spr = "none"
				return
			end
		else
			spr = "none"
		end

		if bitmode == "4BPP" then

			local inputSprite = spr
			if spr == "none" then
				inputSprite = Sprite(128,math.ceil(inputSize/512)*8,ColorMode.INDEXED)
			else
				spr:resize(128,math.ceil(inputSize/512)*8)
				app.command.ChangePixelFormat({ format="indexed", dithering="none" })
				spr.cels[1].image:clear()
			end
			app.command.BackgroundFromLayer()
			
			inputSprite.cels[1].layer.name = "GFX Contents"
			inputSprite.cels[1].layer.data = "4BPP"

			inputSprite:loadPalette(scriptPath.."\\default_pal.pal")

			local inputSpriteImage = Image(inputSprite.spec)

			for i = 1, inputSize/32 do
				inputSpriteImage:drawImage( importChar4BPP(input:read(32)),((i-1)*8)%128,(math.ceil(i/16)-1)*8 )
			end

			inputSprite.filename = app.fs.fileTitle(DLG_import.data.importfile)
			inputSprite.cels[1].image = inputSpriteImage
			input:close()

		elseif bitmode == "2BPP" then

			local inputSprite = spr
			if spr == "none" then
				inputSprite = Sprite(128,math.ceil(inputSize/256)*8,ColorMode.INDEXED)
			else
				spr:resize(128,math.ceil(inputSize/256)*8)
				app.command.ChangePixelFormat({ format="indexed", dithering="none" })
				spr.cels[1].image:clear()
			end
			app.command.BackgroundFromLayer()

			inputSprite.cels[1].layer.name = "GFX Contents"
			inputSprite.cels[1].layer.data = "2BPP"

			inputSprite:loadPalette(scriptPath.."\\default_pal.pal")

			local inputSpriteImage = Image(inputSprite.spec)

			for i = 1, inputSize/16 do
				inputSpriteImage:drawImage( importChar2BPP(input:read(16)),((i-1)*8)%128,(math.ceil(i/16)-1)*8 )
			end

			inputSprite.filename = app.fs.fileTitle(DLG_import.data.importfile)
			inputSprite.cels[1].image = inputSpriteImage
			input:close()

		end

		DLG_import:modify{
			id="importfile",
			filename = "Import"}
		DLG_import:close()

		app.refresh()
	end)
end

local function doExport()

	if DLG_export.data.exportfile == "Export" then
		return
	end

	local spr = app.activeSprite
	if not doSpriteChecks(spr) then
		return
	end

	local bin = ""
	if spr.cels[1].layer.data == "4BPP" then
		for i = 1, (spr.height/8) do
			for j = 1, (spr.width/8) do
				bin = bin..makeChar4BPP(spr.cels[1].image,(j-1)*8,(i-1)*8)
			end
		end
	elseif spr.cels[1].layer.data == "2BPP" then
		for i = 1, (spr.height/8) do
			for j = 1, (spr.width/8) do
				bin = bin..makeChar2BPP(spr.cels[1].image,(j-1)*8,(i-1)*8)
			end
		end
	else
		app.alert{title="Error", text={
			"Sprite Layer doesn't have a valid bit depth",
			"Edit the user data of a layer by right clicking it and pressing properties",
			'Press the square next to the name and set the user data to "4BPP" or "2BPP"'
		}, buttons="OK"}
		return
	end

	local filesize = string.len(bin)/2
	local exportsize = DLG_export.data.exportsize

	if exportsize == "Auto (closest)" then
		if filesize > 32768 then
			filesize = 224512
		elseif filesize > 24064 then
			filesize = 32768
		elseif filesize > 12288 then
			filesize = 23808
		elseif filesize > 6656 then
			filesize = 12288
		elseif filesize > 4096 then
			filesize = 6656
		elseif filesize > 2048 then
			filesize = 4096
		else
			filesize = 2048
		end
	elseif exportsize == "Document Size" then
		filesize = string.len(bin)/2
	elseif exportsize == "2.00   kb (Layer 3)" then
		filesize = 2048
	elseif exportsize == "4.00   kb (Normal)" then
		filesize = 4096
	elseif exportsize == "6.50   kb (AN2)" then
		filesize = 6656
	elseif exportsize == "12.00  ­kb (GFX33.bin)" then
		filesize = 12288
	elseif exportsize == "23.25 ­­­kb (GFX32.bin)" then
		filesize = 23808
	elseif exportsize == "32.00 ­­­kb (ALT ExGFX source)" then
		filesize = 32768
	elseif exportsize == "219.25 kb (AllGFX.bin)" then
		filesize = 224512
	end

	if string.len(bin)/2 > filesize then
		bin = string.sub(bin,1,filesize*2)
	elseif string.len(bin)/2 < filesize then
		while string.len(bin) < filesize*2 do
			bin = bin.."00"
		end
	end

	local out = io.open(app.fs.normalizePath(DLG_export.data.exportfile), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()

	DLG_export:modify{
		id="exportfile",
		filename = "Export"}
	DLG_export:close()

	app.refresh()
end

local function doQuickExport()
	
	local spr = app.activeSprite
	if not doSpriteChecks(spr) then
		return
	end
	path = app.fs.filePathAndTitle(spr.filename)
	if not app.fs.isFile(spr.filename) then
		app.alert{title="Error", text="File needs to be saved first", buttons="OK"}
		return
	end

	local bin = ""
	if spr.cels[1].layer.data == "4BPP" then
		for i = 1, (spr.height/8) do
			for j = 1, (spr.width/8) do
				bin = bin..makeChar4BPP(spr.cels[1].image,(j-1)*8,(i-1)*8)
			end
		end
	elseif spr.cels[1].layer.data == "2BPP" then
		for i = 1, (spr.height/8) do
			for j = 1, (spr.width/8) do
				bin = bin..makeChar2BPP(spr.cels[1].image,(j-1)*8,(i-1)*8)
			end
		end
	else
		app.alert{title="Error", text={
			"Sprite Layer doesn't have a valid bit depth",
			"Edit the user data of a layer by right clicking it and pressing properties",
			'Press the square next to the name and set the user data to "4BPP" or "2BPP"'
		}, buttons="OK"}
		return
	end

	local filesize = string.len(bin)/2

	if filesize > 32768 then
		filesize = 224512
	elseif filesize > 24064 then
		filesize = 32768
	elseif filesize > 12288 then
		filesize = 23808
	elseif filesize > 6656 then
		filesize = 12288
	elseif filesize > 4096 then
		filesize = 6656
	elseif filesize > 2048 then
		filesize = 4096
	else
		filesize = 2048
	end

	if string.len(bin)/2 > filesize then
		bin = string.sub(bin,1,filesize*2)
	elseif string.len(bin)/2 < filesize then
		while string.len(bin) < filesize*2 do
			bin = bin.."00"
		end
	end

	local out = io.open(app.fs.normalizePath(path..".bin"), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()
end

local function convertBitDepth()
	app.transaction(
	function()
		local spr = app.activeSprite
		if not doSpriteChecks(spr) then
			return
		end

		local bin = ""
		if bitmode == "2BPP" and spr.cels[1].layer.data == "4BPP" then
			for i = 1, (spr.height/8) do
				for j = 1, (spr.width/8) do
					bin = bin..makeChar4BPP(spr.cels[1].image,(j-1)*8,(i-1)*8)
				end
			end
		elseif bitmode == "4BPP" and spr.cels[1].layer.data == "2BPP" then
			for i = 1, (spr.height/8) do
				for j = 1, (spr.width/8) do
					bin = bin..makeChar2BPP(spr.cels[1].image,(j-1)*8,(i-1)*8)
				end
			end
		else
			if spr.cels[1].layer.data ~= "4BPP" then
				if spr.cels[1].layer.data ~= "2BPP" then
					app.alert{title="Error", text={
						"Sprite Layer doesn't have a valid bit depth",
						"Edit the user data of a layer by right clicking it and pressing properties",
						'Press the square next to the name and set the user data to "4BPP" or "2BPP"'
					}, buttons="OK"}
				end
			end
			return
		end
		inputSize = string.len(bin)/2

		if bitmode == "4BPP" then

			local inputSprite = spr
			spr:resize(128,math.ceil(inputSize/512)*8)
			app.command.ChangePixelFormat({ format="indexed", dithering="none" })
			spr.cels[1].image:clear()

			app.command.BackgroundFromLayer()

			spr.cels[1].layer.data = "4BPP"

			local inputSpriteImage = Image(inputSprite.spec)

			for i = 1, inputSize/32 do
				local bytes = string.fromhex(string.sub(bin, 1+(64*(i-1)), 64+(64*(i-1))))
				inputSpriteImage:drawImage( importChar4BPP(bytes),((i-1)*8)%128,(math.ceil(i/16)-1)*8 )
			end

			inputSprite.cels[1].image = inputSpriteImage

		elseif bitmode == "2BPP" then

			local inputSprite = spr
			spr:resize(128,math.ceil(inputSize/256)*8)
			app.command.ChangePixelFormat({ format="indexed", dithering="none" })
			spr.cels[1].image:clear()

			app.command.BackgroundFromLayer()

			spr.cels[1].layer.data = "2BPP"

			local inputSpriteImage = Image(inputSprite.spec)

			for i = 1, inputSize/16 do
				local bytes = string.fromhex(string.sub(bin, 1+(32*(i-1)), 32+(32*(i-1))))
				inputSpriteImage:drawImage( importChar2BPP(bytes),((i-1)*8)%128,(math.ceil(i/16)-1)*8 )
			end

			inputSprite.cels[1].image = inputSpriteImage

		end
	end)
end

local function loadPalette()
	app.transaction(
	function()
		if DLG_palette.data.pickpal == "Import Palette" then
			return
		end
		if not app.fs.isFile(DLG_palette.data.pickpal) then
			app.alert{title="Error", text="Unable to open file.", buttons="OK"}
			return
		end
		if not app.fs.fileExtension(DLG_palette.data.pickpal) == "pal" then
			app.alert{title="Error", text="File is not a .pal file", buttons="OK"}
		end

		local palFile = io.open(app.fs.normalizePath(DLG_palette.data.pickpal), "rb")

		local playerPalette = Palette(256)
		for i=0,255 do
			local col = {
				r=tonumber(string.tohex(palFile:read(1)), 16),
				g=tonumber(string.tohex(palFile:read(1)), 16),
				b=tonumber(string.tohex(palFile:read(1)), 16)
			}
			playerPalette:setColor(i, col)
		end
		
		palFile:close()
		app.activeSprite:setPalette(playerPalette)

		DLG_palette:modify{
			id="pickpal",
			filename = "Import Palette"}
		DLG_palette.bounds = DLG_palette.bounds

		app.refresh()
	end)
end

local function exportPalette()
	
	if DLG_palette.data.exportpal == "Export Palette" then
		return
	end

	local currentpal = app.activeSprite.palettes[1]
	local coloramount = math.min(#currentpal,256)
	local colortable = {}
	for i=1,256 do
		local col = Color{ r=0, g=0, b=0, a=255 }
		if i <= coloramount then
			col = app.activeSprite.palettes[1]:getColor(i-1)
		end
		colortable[i] = string.format("%02X", col.red )..string.format("%02X", col.green )..string.format("%02X", col.blue )
	end

	local colorstring = string.fromhex(table.concat(colortable))

	local out = io.open(app.fs.normalizePath(DLG_palette.data.exportpal), "wb")
	out:write(colorstring)
	out:close()

	DLG_palette:modify{
		id="exportpal",
		filename = "Export Palette"}
	DLG_palette.bounds = DLG_palette.bounds

	app.refresh()

end

local function shiftPalDown()
	if app.activeSprite.colorMode ~= ColorMode.INDEXED then
		app.alert{title="Error", text="Sprite color mode needs to be indexed", buttons="OK"}
		return
	end
	local canvas = {};
	if app.activeSprite.selection.bounds.width>0 then 
		canvas = {
			x = app.activeSprite.selection.bounds.x,
			y = app.activeSprite.selection.bounds.y,
			width = app.activeSprite.selection.bounds.width,
			height = app.activeSprite.selection.bounds.height,
			selection = true
		}
	else 
		canvas = {
			x = 0,
			y = 0,
			width = app.activeImage.width,
			height = app.activeImage.height,
			selection = false
		}
	end
	local sPal = app.activeSprite.palettes[1]
	local sImg = app.activeImage:clone()
	for x = 0, canvas.width - 1 do
		for y = 0, canvas.height - 1 do
			if canvas.selection == true then
				if app.activeSprite.selection:contains(canvas.x + x, canvas.y + y) then
					local posx = canvas.x+x
					local posy = canvas.y+y
					local sPix = sImg:getPixel(posx, posy)
					if sPix then
						if app.activeSprite.cels[1].layer.data == "4BPP" then
							if sPix+16 < #sPal then
								sImg:drawPixel(posx, posy, sPix+16)
							end
						elseif app.activeSprite.cels[1].layer.data == "2BPP" then
							if sPix+4 < #sPal then
								sImg:drawPixel(posx, posy, sPix+4)
							end
						end
					end
				end
			else
				local posx = canvas.x+x
				local posy = canvas.y+y
				local sPix = sImg:getPixel(posx, posy)
				if sPix then
					if app.activeSprite.cels[1].layer.data == "4BPP" then
						if sPix+16 < #sPal then
							sImg:drawPixel(posx, posy, sPix+16)
						end
					elseif app.activeSprite.cels[1].layer.data == "2BPP" then
						if sPix+4 < #sPal then
							sImg:drawPixel(posx, posy, sPix+4)
						end
					end
				end
			end
		end
	end
	app.activeImage:putImage(sImg)
	app.refresh()
end

local function shiftPalUp()
	if app.activeSprite.colorMode ~= ColorMode.INDEXED then
		app.alert{title="Error", text="Sprite color mode needs to be indexed", buttons="OK"}
		return
	end
	local canvas = {};
	if app.activeSprite.selection.bounds.width>0 then 
		canvas = {
			x = app.activeSprite.selection.bounds.x,
			y = app.activeSprite.selection.bounds.y,
			width = app.activeSprite.selection.bounds.width,
			height = app.activeSprite.selection.bounds.height,
			selection = true
		};
	else 
		canvas = {
			x = 0,
			y = 0,
			width = app.activeImage.width,
			height = app.activeImage.height,
			selection = false
		};
	end
	local sPal = app.activeSprite.palettes[1]
	local sImg = app.activeImage:clone()
	for x = 0, canvas.width - 1 do
		for y = 0, canvas.height - 1 do
			if canvas.selection == true then
				if app.activeSprite.selection:contains(canvas.x + x, canvas.y + y) then
					local posx = canvas.x+x
					local posy = canvas.y+y
					local sPix = sImg:getPixel(posx, posy)
					if sPix then
						if app.activeSprite.cels[1].layer.data == "4BPP" then
							if sPix-16 >= 0 then
								sImg:drawPixel(posx, posy, sPix-16)
							end
						elseif app.activeSprite.cels[1].layer.data == "2BPP" then
							if sPix-4 >= 0 then
								sImg:drawPixel(posx, posy, sPix-4)
							end
						end
					end
				end
			else
				local posx = canvas.x+x
				local posy = canvas.y+y
				local sPix = sImg:getPixel(posx, posy)
				if sPix then
					if app.activeSprite.cels[1].layer.data == "4BPP" then
						if sPix-16 >= 0 then
							sImg:drawPixel(posx, posy, sPix-16)
						end
					elseif app.activeSprite.cels[1].layer.data == "2BPP" then
						if sPix-4 >= 0 then
							sImg:drawPixel(posx, posy, sPix-4)
						end
					end
				end
			end
		end
	end
	app.activeImage:putImage(sImg)
	app.refresh()
end

local function setPal()
	local palnumber = math.floor(tonumber(DLG_palette.data.palnum))
	if palnumber == nil then
		app.alert{title="Error", text="Not a valid number", buttons="OK"}
		return
	end
	if app.activeSprite.colorMode ~= ColorMode.INDEXED then
		app.alert{title="Error", text="Sprite color mode needs to be indexed", buttons="OK"}
		return
	end
	if palnumber < 0 then
		app.alert{title="Error", text="Number out of bounds", buttons="OK"}
		return
	end
	local numbermult = 16
	if app.activeSprite.cels[1].layer.data == "2BPP" then
		numbermult = 4
	end
	if ((palnumber+1)*numbermult) > #app.activeSprite.palettes[1] then
		app.alert{title="Error", text="Number out of bounds", buttons="OK"}
		return
	end

	local canvas = {};
	if app.activeSprite.selection.bounds.width>0 then 
		canvas = {
			x = app.activeSprite.selection.bounds.x,
			y = app.activeSprite.selection.bounds.y,
			width = app.activeSprite.selection.bounds.width,
			height = app.activeSprite.selection.bounds.height,
			selection = true
		};
	else 
		canvas = {
			x = 0,
			y = 0,
			width = app.activeImage.width,
			height = app.activeImage.height,
			selection = false
		};
	end
	local sPal = app.activeSprite.palettes[1]
	local sImg = app.activeImage:clone()
	for x = 0, canvas.width - 1 do
		for y = 0, canvas.height - 1 do
			if canvas.selection == true then
				if app.activeSprite.selection:contains(canvas.x + x, canvas.y + y) then
					local posx = canvas.x+x
					local posy = canvas.y+y
					local sPix = sImg:getPixel(posx, posy)
					if sPix then
						sImg:drawPixel(posx, posy, (sPix%numbermult)+(palnumber*numbermult) )
					end
				end
			else
				local posx = canvas.x+x
				local posy = canvas.y+y
				local sPix = sImg:getPixel(posx, posy)
				if sPix then
					sImg:drawPixel(posx, posy, (sPix%numbermult)+(palnumber*numbermult) )
				end
			end
		end
	end
	app.activeImage:putImage(sImg)
	app.refresh()
end

-- This code is a modified version of an Aseprite example script
-- However, I can't figure out how to easily rotate/slip raw image data using the API
-- Which is odd considering theres functions for resizing
-- Anyways, this is scrapped for now cus I'm running low on time and its not completely nessesary
--[[

local function doRemove()
	local spr = app.activeSprite
	if not doSpriteChecks(spr) then
		return
	end

	local img = Image(spr.spec)
	img:clear()
	img:drawSprite(spr, app.activeFrame)
	
	local tiles_w = img.width/8
	local tiles_h = img.height/8

	local numbermult = 16
	if bitmode == "2BPP" then
		numbermult = 4
	end

	local tiles = {}
	local function addTile(newTileImg)
		local newTile = newTileImg

		if DLG_remove.data.ignorepals then
			for it in newTile:pixels() do
				local pixelValue = it()%numbermult
				it(pixelValue)
			end
		end
		
		if DLG_remove.data.removedupes then
			for i,v in ipairs(tiles) do
				if v:isEqual(newTile) then
					return i
				end
			end
		end
		
		if DLG_remove.data.removeflip then
			for i,v in ipairs(tiles) do
				if v:isEqual(newTile) then
					return i
				end
			end
		end

		table.insert(tiles, newTile)
		return #tiles
	end
end

--]]

local function makeGFX()
	local size = DLG_blanks.data.gfxsize
	local imageheight = 64

	if size == "2.00   kb (Layer 3)" then
		imageheight = 32
	elseif size == "4.00   kb (Normal)" then
		imageheight = 64
	elseif size == "6.50   kb (AN2)" then
		imageheight = 104
	elseif size == "12.00  ­kb (GFX33.bin)" then
		imageheight = 192
	elseif size == "23.25 ­­­kb (GFX32.bin)" then
		imageheight = 376
	elseif size == "32.00 ­­­kb (ALT ExGFX source)" then
		imageheight = 512
	elseif size == "219.25 kb (AllGFX.bin)" then
		imageheight = 3512
	end

	if bitmode == "2BPP" then
		imageheight = imageheight*2
	end

	inputSprite = Sprite(128, imageheight, ColorMode.INDEXED)
	app.command.BackgroundFromLayer()
	inputSprite:loadPalette(scriptPath.."\\default_pal.pal")

	inputSprite.cels[1].layer.data = bitmode
	
	local filename = DLG_blanks.data.name
	inputSprite.filename = DLG_blanks.data.name

end

----------------------------------------------------------------

DLG_landing = Dialog("SNES GFX Tools by MM102")
local function createDLG_landing() -- this is here so I can collapse it in my code editor
	DLG_landing:separator{
		text="Bit Depth"
	}
	DLG_landing:radio{
		id="mode",
        text="4BPP",
		selected=true,
		onclick=function()
			if bitmode ~= "4BPP" then
				bitmode = "4BPP"
			end
		end
	}
	DLG_landing:radio{
		id="mode",
        text="2BPP",
		selected=false,
		onclick=function()
			if bitmode ~= "2BPP" then
				bitmode = "2BPP"
			end
		end
	}
	DLG_landing:button{
		id = "convertbitdepth",
		text = "Convert Bit Depth",
		onclick = convertBitDepth
	}
	DLG_landing:separator{
		text="Import/Export"
	}
	DLG_landing:button{
		focus=true,
		id = "landingToImport",
		text = "Import .bin",
		onclick = function()
			DLG_import:close()
			DLG_import:show{ wait=false }
			if DLG_landing.bounds.x-DLG_import.bounds.width-10 < 0 then
				DLG_import.bounds = Rectangle(
					DLG_landing.bounds.x+DLG_landing.bounds.width+10,
					DLG_landing.bounds.y,
					DLG_import.bounds.width,
					DLG_import.bounds.height
				)
			else
				DLG_import.bounds = Rectangle(
					DLG_landing.bounds.x-DLG_import.bounds.width-10,
					DLG_landing.bounds.y,
					DLG_import.bounds.width,
					DLG_import.bounds.height
				)
			end
		end
	}
	DLG_landing:newrow()
	DLG_landing:button{
		id = "landingToExport",
		text = "Export .bin",
		onclick = function()
			DLG_export:close()
			DLG_export:show{ wait=false }
			if DLG_landing.bounds.x-DLG_export.bounds.width-10 < 0 then
				DLG_export.bounds = Rectangle(
					DLG_landing.bounds.x+DLG_landing.bounds.width+10,
					DLG_landing.bounds.y,
					DLG_export.bounds.width,
					DLG_export.bounds.height
				)
			else
				DLG_export.bounds = Rectangle(
					DLG_landing.bounds.x-DLG_export.bounds.width-10,
					DLG_landing.bounds.y,
					DLG_export.bounds.width,
					DLG_export.bounds.height
				)
			end
		end
	}
	DLG_landing:button{
		id = "landingToReExport",
		text = "Quick Export .bin",
		onclick = doQuickExport
	}
	DLG_landing:separator{
		text="Tools"
	}
	DLG_landing:button{
		id = "landingToPaletteTools",
		text = "Palette Tools",
		onclick = function()
			DLG_palette:close()
			DLG_palette:show{ wait=false }
			if DLG_landing.bounds.x-DLG_palette.bounds.width-10 < 0 then
				DLG_palette.bounds = Rectangle(
					DLG_landing.bounds.x+DLG_landing.bounds.width+10,
					DLG_landing.bounds.y,
					DLG_palette.bounds.width,
					DLG_palette.bounds.height
				)
			else
				DLG_palette.bounds = Rectangle(
					DLG_landing.bounds.x-DLG_palette.bounds.width-10,
					DLG_landing.bounds.y,
					DLG_palette.bounds.width,
					DLG_palette.bounds.height
				)
			end
		end
	}
	--[[
	DLG_landing:newrow()
	DLG_landing:button{
		id = "landingToTileTools",
		text = "  Remove Duplicate Tiles  ",
		onclick = function()
			DLG_remove:close()
			DLG_remove:show{ wait=false }
			if DLG_landing.bounds.x-DLG_remove.bounds.width-10 < 0 then
				DLG_remove.bounds = Rectangle(
					DLG_landing.bounds.x+DLG_landing.bounds.width+10,
					DLG_landing.bounds.y,
					DLG_remove.bounds.width,
					DLG_remove.bounds.height
				)
			else
				DLG_remove.bounds = Rectangle(
					DLG_landing.bounds.x-DLG_remove.bounds.width-10,
					DLG_landing.bounds.y,
					DLG_remove.bounds.width,
					DLG_remove.bounds.height
				)
			end
		end
	}
	--]]
	DLG_landing:newrow()
	DLG_landing:button{
		id = "blanks",
		text = "Create Blank GFX Template",
		onclick = function()
			DLG_blanks:close()
			DLG_blanks:show{ wait=false }
			if DLG_landing.bounds.x-DLG_blanks.bounds.width-10 < 0 then
				DLG_blanks.bounds = Rectangle(
					DLG_landing.bounds.x+DLG_landing.bounds.width+10,
					DLG_landing.bounds.y,
					DLG_blanks.bounds.width,
					DLG_blanks.bounds.height
				)
			else
				DLG_blanks.bounds = Rectangle(
					DLG_landing.bounds.x-DLG_blanks.bounds.width-10,
					DLG_landing.bounds.y,
					DLG_blanks.bounds.width,
					DLG_blanks.bounds.height
				)
			end
		end
	}
end
createDLG_landing()

DLG_import = Dialog("GFX Importer")
local function createDLG_import() -- this is here so I can collapse it in my code editor
	DLG_import:radio{
		id="importsettings",
        text="Overwrite current sprite",
		selected=false,
		onclick=function() importsettings.overwrite = true end
	}
	DLG_import:newrow()
	DLG_import:radio{
		id="importsettings",
        text="Import as new sprite",
		selected=true,
		onclick=function() importsettings.overwrite = false end
	}
	DLG_import:separator{
	}
	--DLG_import:check{
	--	id = "importPalMap",
	--	text = "Import pal-map (if available)",
	--	selected = false
	--}
	--DLG_import:separator{
	--}
	DLG_import:file{
		focus=true,
		id="importfile",
		title="pick a file",
		open=true,
		filename="Import",
		filetypes={"bin"},
		onchange=doImport
	}
end
createDLG_import()

DLG_export = Dialog("GFX Exporter")
local function createDLG_export() -- this is here so I can collapse it in my code editor
	DLG_export:separator{
		text="Export Size"
	}
	DLG_export:combobox{
		id="exportsize",
		options={
			"Auto (closest)",
			"Document Size",
			"2.00   kb (Layer 3)",
			"4.00   kb (Normal)",
			"6.50   kb (AN2)",
			"12.00  ­kb (GFX33.bin)",
			"23.25 ­­­kb (GFX32.bin)",
			"32.00 ­­­kb (ALT ExGFX source)",
			"219.25 kb (AllGFX.bin)"
		}
	}
	DLG_export:separator{
	}
	DLG_export:file{
		focus=true,
		id="exportfile",
		title="Export file",
		save=true,
		filename="Export",
		filetypes={"bin"},
		onchange=doExport
	}
end
createDLG_export()

DLG_blanks = Dialog("Create Blank GFX Template")
local function createDLG_blanks() -- this is here so I can collapse it in my code editor
	DLG_blanks:separator{
		text="GFX Size"
	}
	DLG_blanks:combobox{
		id="gfxsize",
		option="4.00   kb (Normal)",
		options={
			"2.00   kb (Layer 3)",
			"4.00   kb (Normal)",
			"6.50   kb (AN2)",
			"12.00  ­kb (GFX33.bin)",
			"23.25 ­­­kb (GFX32.bin)",
			"32.00 ­­­kb (ALT ExGFX source)",
			"219.25 kb (AllGFX.bin)"
		}
	}
	DLG_blanks:separator{
		text="File Name"
	}
	DLG_blanks:entry{
		id="name",
		text="ExGFX80"
	}
	DLG_blanks:separator{
	}
	DLG_blanks:button{
		id = "create",
		text = "Create",
		onclick = makeGFX,
		focus = true
	}
end
createDLG_blanks()

DLG_palette = Dialog("SNES Palette Tools")
local function createDLG_palette() -- this is here so I can collapse it in my code editor
	DLG_palette:file{
		id="pickpal",
		title="Import a palette",
		open=true,
		filename="Import Palette",
		filetypes={"pal"},
		onchange= loadPalette
	}
	DLG_palette:newrow()
	DLG_palette:file{
		id="exportpal",
		title="Export a palette",
		save=true,
		filename="Export Palette",
		filetypes={"pal"},
		onchange= exportPalette
	}
	DLG_palette:separator{
		text="Shift Palette"
	}
	DLG_palette:button{
		id = "PalUp",
		text = "/\\ Up",
		onclick = shiftPalUp
	}
	DLG_palette:button{
		id = "PalDown",
		text = "  Down \\/  ",
		onclick = shiftPalDown
	}
	DLG_palette:separator{
		text="Set Palette"
	}
	DLG_palette:entry{
		id="palnum",
		text="0"
	}
	DLG_palette:button{
		id = "setpal",
		text = "Set",
		onclick = setPal
	}
end
createDLG_palette()

DLG_remove = Dialog("Remove Duplicate Tiles")
local function createDLG_remove() -- this is here so I can collapse it in my code editor
	DLG_remove:check{
		id = "removedupes",
		text = "Remove Duplicates",
		selected = true
	}
	DLG_remove:newrow()
	DLG_remove:check{
		id = "removeflip",
		text = "Remove Flipped",
		selected = true
	}
	DLG_remove:newrow()
	DLG_remove:check{
		id = "removerots",
		text = "Remove Rotated",
		selected = false
	}
	DLG_remove:separator{
	}
	DLG_remove:check{
		id = "ignorepals",
		text = "Ignore Different Palettes",
		selected = true
	}
	DLG_remove:button{
		id = "remove",
		text = "Remove",
		onclick = doRemove
	}
end
createDLG_remove()
----------------------------------------------------------------

DLG_landing:close()
DLG_landing:show{ wait=false }