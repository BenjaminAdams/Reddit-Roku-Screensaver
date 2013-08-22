Function getSetting(name as String) As Dynamic
     sec = CreateObject("roRegistrySection", "Authentication")
     if sec.Exists(name) 
         return sec.Read(name)
     endif
     return invalid
End Function

 
Function setSetting(name As String, value) As Void
    sec = CreateObject("roRegistrySection", "Authentication")
    sec.Write(name, value)
    sec.Flush()
End Function

Function deleteSetting(name as String) As Dynamic
     sec = CreateObject("roRegistrySection", "Authentication")
     if sec.Exists(name) 
         return sec.Delete(name)
     endif
     return invalid
End Function


Function getSettingsGridForHome()
	settings = CreateObject("roArray", 28, true)
	o = CreateObject("roAssociativeArray")
	o.Title = "Settings"
	o.self = true
	o.SDPosterUrl = "pkg:/images/settings.jpg"
	o.HDPosterUrl = "pkg:/images/settings.jpg"
	settings.Push(o)
	
	L = CreateObject("roAssociativeArray")
	L.self = true
	if(isLoggedIn() = true)
		username = getSetting("username")
		L.Title = username + " - Logout"
		L.SDPosterUrl = "pkg:/images/reddit-icon.jpg"
		L.HDPosterUrl = "pkg:/images/reddit-icon.jpg"
	else		
		L.Title = "Login"
		L.SDPosterUrl = "pkg:/images/reddit-icon.jpg"
		L.HDPosterUrl = "pkg:/images/reddit-icon.jpg"		
	END IF
	settings.Push(L)
	
	h = CreateObject("roAssociativeArray")
	h.Title = "Help"
	h.self = true
	h.SDPosterUrl = "pkg:/images/question.png"
	h.HDPosterUrl = "pkg:/images/question.png"
	settings.Push(h)
	
	return settings
	
END FUNCTION

function getTimerSetting() as String
'default 20 seconds
timer = getSetting("timer")
	if(timer <> invalid)
		return timer
	else
		return "20"
	end if

END FUNCTION

function getShowTitleSetting() as String
'default "yes"
display= getSetting("showTitle")
	if(display <> invalid)
		return display
	else
		return "yes"
	end if

END FUNCTION


Function settingsGrid(port)

	grid = CreateObject("roGridScreen")
    grid.SetMessagePort(port)
    grid.SetDisplayMode("scale-to-fit")
    grid.SetGridStyle("Flat-Square")
	grid.SetUpBehaviorAtTopRow("exit")

    grid.SetupLists(1)
	rowTitles = CreateObject("roArray", 1, true)
    rowTitles.Push("Settings")
    grid.SetListNames(rowTitles) 
	
	list = CreateObject("roArray", 10, true)
    timer = CreateObject("roAssociativeArray")
    timer.Title = "Slide Show Timer"
	timer.name = "timer"
	timer.SDPosterUrl = "pkg:/images/settings.jpg"
	timer.HDPosterUrl = "pkg:/images/settings.jpg"

	timerSetting =getTimerSetting()
	timer.Description =  "currently: "+timerSetting + " seconds"
    list.Push(timer)
	display = CreateObject("roAssociativeArray")
    display.Title = "Show title of Reddit post at the bottom of the screen?"
	display.SDPosterUrl = "pkg:/images/settings.jpg"
	display.HDPosterUrl = "pkg:/images/settings.jpg"
	display.name = "displayTitle"
	displaySetting =getShowTitleSetting()
	display.Description = "currently: "+displaySetting
    list.Push(display)
	grid.SetContentList(0, list) 
	grid.Show()
 
	while true
         msg = wait(0, port)
         if type(msg) = "roGridScreenEvent" then
             if msg.isScreenClosed() then
                 return -1
             elseif msg.isListItemFocused()
                 print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                 print " col: ";msg.GetData()
             elseif msg.isListItemSelected()
                print "Selected msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                print " col: ";msg.GetData()
				row = msg.GetIndex()
				col = msg.GetData()
				name = list[col].name
				
				IF(name = "timer" )

					changeTimerGrid(port)
					settingsGrid(port)
					return -1
				ELSE IF(name = "displayTitle" )
					
					changeDisplayGrid(port)
					settingsGrid(port)
					return -1					 
				END IF
				 
				 
             endif
         endif
     end while
	
	
END FUNCTION


Function changeTimerGrid(port)

	grid = CreateObject("roGridScreen")
    grid.SetMessagePort(port)
    grid.SetDisplayMode("scale-to-fit")
    grid.SetGridStyle("Flat-Square")
	grid.SetUpBehaviorAtTopRow("exit")

    grid.SetupLists(1)
	rowTitles = CreateObject("roArray", 1, true)
	currentSeconds = getTimerSetting()
    rowTitles.Push("Timer seconds, currently: " + currentSeconds + " seconds")
    grid.SetListNames(rowTitles) 
	
	list = CreateObject("roArray", 20, true)
	for i = 1 to 18 - 1
		seconds = (i*5).tostr()
		timer = CreateObject("roAssociativeArray")
		timer.Title = seconds + " seconds"
		timer.ShortDescriptionLine1 = "How many seconds between each post?"
		timer.seconds = seconds
		timer.SDPosterUrl = "pkg:/images/settings.jpg"
		timer.HDPosterUrl = "pkg:/images/settings.jpg"
		list.Push(timer)
	end for


	grid.SetContentList(0, list) 
	grid.Show()
 
	while true
         msg = wait(0, port)
         if type(msg) = "roGridScreenEvent" then
             if msg.isScreenClosed() then
                 return -1
             elseif msg.isListItemFocused()
                 print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                 print " col: ";msg.GetData()
             elseif msg.isListItemSelected()
                print "Selected msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                print " col: ";msg.GetData()
				row = msg.GetIndex()
				col = msg.GetData()
				 
				newTime = list[col].seconds
				setSetting("timer", newTime) 
				print "changed timer settings to " + newTime
				 return -1
             endif
         endif
     end while
END FUNCTION

function changeDisplayGrid(port)

	grid = CreateObject("roGridScreen")
    grid.SetMessagePort(port)
    grid.SetDisplayMode("scale-to-fit")
    grid.SetGridStyle("Flat-Square")
	grid.SetUpBehaviorAtTopRow("exit")

    grid.SetupLists(1)
	rowTitles = CreateObject("roArray", 1, true)
	currentDisplay = getShowTitleSetting()
    rowTitles.Push("Display the Reddit post title?")
    grid.SetListNames(rowTitles) 
	
	list = CreateObject("roArray", 2, true)
	yes = CreateObject("roAssociativeArray")
	yes.Title = "yes"
	yes.option = "yes"
	yes.SDPosterUrl = "pkg:/images/settings.jpg"
	yes.HDPosterUrl = "pkg:/images/settings.jpg"
	list.Push(yes)

	no = CreateObject("roAssociativeArray")
	no.Title = "no"
	no.option = "no"
	no.SDPosterUrl = "pkg:/images/settings.jpg"
	no.HDPosterUrl = "pkg:/images/settings.jpg"
	list.Push(no)
	
	grid.SetContentList(0, list) 
	grid.Show()
 
	while true
         msg = wait(0, port)
         if type(msg) = "roGridScreenEvent" then
             if msg.isScreenClosed() then
                 return -1
             elseif msg.isListItemFocused()
                 print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                 print " col: ";msg.GetData()
             elseif msg.isListItemSelected()
                print "Selected msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                print " col: ";msg.GetData()
				row = msg.GetIndex()
				col = msg.GetData()
				 
				option = list[col].option
				setSetting("showTitle", option) 
				print "changed display title setting:  " + option
				 return -1
             endif
         endif
     end while
END FUNCTION


function showHelp()
	canvasItems = invalid
	if(IsHD()=false)
		canvasItems = [
			{ 
				url:"pkg:/images/info.jpg"
				TargetRect:{x:100,y:10}
			},
			{ 
				Text:"Loading subreddit"
				TextAttrs:{Color:"#00000000", Font:"Medium",
				HAlign:"HCenter", VAlign:"VCenter",
				Direction:"LeftToRight"}
				TargetRect:{x:550,y:255,w:100,h:25}
			}
		] 
	ELSE
		    canvasItems = [
        { 
            url:"pkg:/images/info.jpg"
            TargetRect:{x:100,y:125}
        },
        { 
            Text:"Loading subreddit"
            TextAttrs:{Color:"#00000000", Font:"Medium",
            HAlign:"HCenter", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:550,y:255,w:100,h:25}
        }
    ] 
	END IF
 
   canvas = CreateObject("roImageCanvas")
   port = CreateObject("roMessagePort")
   canvas.SetMessagePort(port)
   'Set opaque background
  ' canvas.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"}) 
   canvas.SetLayer(0, {Color:"#FFffffff", CompositionMode:"Source"}) 
   canvas.SetRequireAllImagesToDraw(true)
   canvas.SetLayer(1, canvasItems)
   canvas.Show() 
	sleep(1000)
   
   while(true)
       msg = wait(0,port) 
       if type(msg) = "roImageCanvasEvent" then
           if (msg.isRemoteKeyPressed()) then
				canvas.Close()
           else if (msg.isScreenClosed()) then
               print "Closed"
               return -1
           end if
       end if
   end while

END FUNCTION
