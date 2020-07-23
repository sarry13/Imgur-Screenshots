local _rendercap = render.Capture
local _utilb64e = util.Base64Encode

local CLIENT_ID = "" -- https://api.imgur.com/oauth2/addclient

local capturing = false
local inprogress = false
local fr
local Color = Color
local surface = surface
local quality_number = CreateClientConVar("imgur_quality", "90", true, false, "", "1", "100")
function StartCapturing()
	if fr then
		return
	end
	fr = vgui.Create( "DFrame" )
	fr:MakePopup()
	fr:SetPos( 0, 0 )
	fr:SetSize( ScrW(), ScrH() )
	fr:SetDraggable( false )
	fr:SetTitle( " " )
	fr:ShowCloseButton( false )
	function fr:Paint()
	end
	function fr:OnClose()
		self:Remove()
		fr = nil
	end
	function fr:Think()
		fr:SetCursor( "crosshair" )
	end
	capturing = true
end
function CaptureImage( startpos, endpos )
	local v1x = math.min( startpos.x, endpos.x )
	local v1y = math.min( startpos.y, endpos.y )
	local v2x = math.max( startpos.x, endpos.x )
	local v2y = math.max( startpos.y, endpos.y )
	local distx = v2x - v1x
	local disty = v2y - v1y
	local capture = {
		format = "jpeg",
		h = disty,
		w = distx,
		quality = quality_number:GetInt(),
		x = v1x,
		y = v1y
	}
	local data1 = ""
	hook.Add("PostRenderVGUI", "ased", function()
		data1 = _rendercap( capture )
		hook.Remove("PostRenderVGUI", "ased")
	end)
	timer.Simple(0.1, function()
	if capture.h <= 5 or capture.w <= 5 then
		chat.AddText( Color( 255, 0, 0 ), "Upload failed - Image must be greater than 5x5 px" )
		surface.PlaySound( "buttons/button11.wav" )
		inprogress = false			
		return
	end
	if not data1 then
		chat.AddText( Color( 255, 0, 0 ), "render.Capture has been overriden, attempting to bypass..."  )
		data1 = _rendercap( capture )
		if data1 then
			chat.AddText( Color( 0, 255, 0 ), "render.Capture override has been bypassed." )
		else
			chat.AddText( Color( 255, 0, 0 ), "render.Capture override could not be bypassed." )
			surface.PlaySound( "buttons/button11.wav" )
			return
		end
	end
	local data = util.Base64Encode( data1 )
	if not data then
		chat.AddText( Color( 255, 0, 0 ), "util.Base64Encode has been overriden, attempting to bypass..."  )
		data = _utilb64e( data1 )
		if data then
			chat.AddText( Color( 0, 255, 0 ), "util.Base64Encode override has been bypassed." )
		else
			chat.AddText( Color( 255, 0, 0 ), "util.Base64Encode override could not be bypassed." )
			surface.PlaySound( "buttons/button11.wav" )
			return
		end
	end	
	local params = {
		[ "image" ] = data,
		[ "type" ] = "base64"
	}
	local tab = {
		[ "failed" ] = 
			function()
				print( "Upload failed!" )
			end,
		[ "success" ] =
			function( status, response, headers )
				local res = util.JSONToTable( response )
				inprogress = false
				if status == 200 then
					SetClipboardText( res.data.link )
					surface.PlaySound( "garrysmod/content_downloaded.wav" )
					chat.AddText( Color( 0, 255, 0 ), "Upload success - URL Copied to clipboard" )
					return
				elseif status == 400 then
					chat.AddText( Color( 255, 0, 0 ), "Upload failed - Invalid parameters" )
				elseif status == 401 then
					chat.AddText( Color( 255, 0, 0 ), "Upload failed - Authentication required" )
				elseif status == 403 then
					chat.AddText( Color( 255, 0, 0 ), "Upload failed - Invalid Authentication" )
				elseif status == 404 then
					chat.AddText( Color( 255, 0, 0 ), "Upload failed - Resource does not exist" )
				elseif status == 429 then
					chat.AddText( Color( 255, 0, 0 ), "Upload failed - Application rate limit reached" )
				elseif status == 500 then
					chat.AddText( Color( 255, 0, 0 ), "Upload failed - Imgur.com is down" )
				end
				surface.PlaySound( "buttons/button11.wav" )
			end,
		[ "method" ] =
			"post",
		[ "url" ] =
			"https://api.imgur.com/3/upload",
		[ "parameters" ] =
			params,
		[ "headers" ] =
			{ 
				[ "Authorization" ] = "Client-ID " .. CLIENT_ID 
			}
	}
	HTTP( tab )
	chat.AddText( color_white, "Starting image upload (" .. distx .. "x" .. disty .. ")" )
	end)
end
local cappin
local startpos
local endpos
hook.Add( "Think", "CheckMouseClicks", function()
	if not capturing then
		return
	end
	if input.IsMouseDown( MOUSE_LEFT ) and not cappin then
		cappin = true
		local p, p2 = input.GetCursorPos()
		startpos = { x = p, y = p2 }
	elseif not input.IsMouseDown( MOUSE_LEFT ) and cappin then
		cappin = false
		local p, p2 = input.GetCursorPos()
		endpos = { x = p, y = p2 }
		capturing = false
		fr:Close()
		timer.Simple( 0.1, function()
			CaptureImage( startpos, endpos )
			startpos = nil			
		end )
	end
end )
function math.n( num )
	return -num
end
function surface.DrawVectorRect( pos1, pos2 )
	local pos1x = pos1.x
	local pos1y = pos1.y
	local pos2x = pos2.x
	local pos2y = pos2.y
	local distx
	local disty		
	if pos1x - pos2x < 0 then
		distx = pos2x - pos1x 
	else
		distx = math.n( pos1x - pos2x )
	end
	if pos1y - pos2y < 0 then
		disty = pos2y - pos1y
	else
		disty = math.n( pos1y - pos2y )
	end		
	if disty < 0 and distx < 0 then
		pos1x, pos1y = input.GetCursorPos()
		distx, disty = math.abs( distx ), math.abs( disty )
	elseif distx < 0 and disty > 0 then
		pos1x = input.GetCursorPos()
		distx = math.abs( distx )
	elseif disty < 0 and distx > 0 then
		_, pos1y = input.GetCursorPos()
		disty = math.abs( disty )
	end			
	return surface.DrawRect( pos1x, pos1y, distx, disty )
end
function surface.DrawOutlinedVectorRect( pos1, pos2 )
	local pos1x = pos1.x
	local pos1y = pos1.y
	local pos2x = pos2.x
	local pos2y = pos2.y
	local distx
	local disty		
	if pos1x - pos2x < 0 then
		distx = pos2x - pos1x 
	else
		distx = math.n( pos1x - pos2x )
	end
	if pos1y - pos2y < 0 then
		disty = pos2y - pos1y
	else
		disty = math.n( pos1y - pos2y )
	end		
	if disty < 0 and distx < 0 then
		pos1x, pos1y = input.GetCursorPos()
		distx, disty = math.abs( distx ), math.abs( disty )
	elseif distx < 0 and disty > 0 then
		pos1x = input.GetCursorPos()
		distx = math.abs( distx )
	elseif disty < 0 and distx > 0 then
		_, pos1y = input.GetCursorPos()
		disty = math.abs( disty )
	end			
	return surface.DrawOutlinedRect( pos1x, pos1y, distx, disty )
end
hook.Add( "HUDPaint", "DrawCap", function()
	if capturing then
		if startpos then
			local px, py = input.GetCursorPos()
			surface.SetDrawColor( 0, 0, 0, 220 )
			surface.DrawOutlinedVectorRect( Vector( startpos.x, startpos.y ), Vector( px, py ) )			
			surface.SetDrawColor( 255, 255, 255, 45 )
			surface.DrawVectorRect( Vector( startpos.x, startpos.y ), Vector( px, py ) )
		end
	end
end )
