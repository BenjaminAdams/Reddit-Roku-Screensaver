Library "v30/bslCore.brs"

Function Main()
	initTheme()
	loadMainGrid()
End Function

sub loadMainGrid()
	port=CreateObject("roMessagePort")
	dialogPort=CreateObject("roMessagePort")
	subReddits = getSubreddits()
	countSubreddits = subReddits.Count()
	subRedditNamesAfterAsync = CreateObject("roArray", subReddits.Count(), true)
	
	grid = CreateObject("roGridScreen")
	grid.SetMessagePort(port)
	grid.SetDisplayMode("scale-to-fit")
    grid.SetGridStyle("Flat-Square")
	grid.SetupLists(countSubreddits)


	grid.show()
	
	dialog = showLoadingScreen("Downloading subreddits: 0/" +(countSubreddits-1).tostr(),dialogPort)
	
	list = CreateObject("roArray", subReddits.Count(), true)
	
	settings = getSettingsGridForHome()
	subRedditNamesAfterAsync[0] = "Settings"
	list[0] = settings

	cookie = getSetting("cookie") 

	request = CreateObject("roArray", 100, true)
	'httpPort=CreateObject("roMessagePort")
	for j = 1 to subReddits.Count() -1
		request[j] = CreateObject("roUrlTransfer")
		request[j].SetPort(port)
		if(cookie <> invalid)
			'request[j].AddHeader("Cookie", "reddit_session="+cookie) ' not sure if adding cookies is a good thing, its making my "logged in" version of the app pull in 100 json posts for each subreddit causing it to take a long time to load
		END IF
		subReddit = subReddits[j]
		api_url = "http://www.reddit.com/r/" + subReddit + ".json"
		request[j].SetUrl(api_url)
		request[j].AsyncGetToString()
		print "init list " + j.tostr()
	end for
	
	
	countListAsync = 1 'counting the list but for when the async returns
	
	timer = CreateObject("roTimespan")
	
	while true
        msg = wait(0, port)
		
		TotalSeconds = timer.TotalSeconds()
		if(TotalSeconds > 90)               'prevent infinite while loop while 
			exit while
		end if
		
		if (type(msg) = "roUrlEvent")
			code = msg.GetResponseCode()
			print code
			if (code = 200)
				newList = invalid
				response = msg.GetString()
				json = ParseJSON(response)
				if(json = invalid)
					'do nothing
				else
					newList = parseJsonPosts(json)
					subRedditName = newList[0].subReddit
					if(subRedditName <> invalid)
						print "got the subreddit= " + subRedditName
						subRedditNamesAfterAsync.push(subRedditName)
					end if
					list[countListAsync] = newList
					if(list[countListAsync] = invalid)
						'build a failed to load icon for the grid
						list[countListAsync] = buildErrorGrid()
					END IF
					
					dialog.SetTitle( "Downloading subreddits: "+countListAsync.tostr()+ "/" + (countSubreddits-1).tostr() )
					dialog.Show()
					
					'print "[" + msg.GetString() + "]"
				END IF
				
				countListAsync = countListAsync+1

				if(countListAsync = countSubreddits )
					exit while
				end if
			else
				'code was not 200
				print "HTTP response was not 200"
			END IF
		END IF 
	end while
	

	
    grid.SetListNames(subRedditNamesAfterAsync)  'we are now setting these asyncornously
	
	dialog.SetTitle( "Loading subreddits" )
	dialog.Show()
	

 
	for i = 0 to subReddits.Count() -1
		grid.SetContentList(i, list[i])
	end for
	 grid.SetFocusedListItem(2,0)
	'grid.show()
	dialog.Close()
	
	
    while true	
         msg = wait(0, port)

         if type(msg) = "roGridScreenEvent" then
             if msg.isScreenClosed() then
                 return
             elseif msg.isListItemFocused()
                 print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                 print " col: ";msg.GetData()
					 
             elseif msg.isListItemSelected()
                 print "Selected msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                 print " col: ";msg.GetData()
				 row = msg.GetIndex()
				 col = msg.GetData()
				 
				 'login or logout
				if(row=0 AND col=2) THEN 'show settings grid
					showHelp()
				ELSE IF (row=0 AND col=1) THEN
					'show the login screen
					if(isLoggedIn() = true) THEN
						logout()
					else
						login()
					END IF 
				ELSE if(row=0 AND col=0) THEN 'show settings grid
					settingsGrid(port)
				 ELSE if(list[row][col].video=true)
					'show a video
					showVideo(list[row],list[row][col].id,port)
				 
				 ELSE
				 
				 'for images show a slideshow
				 if(list[row][col].self = false )
					list[row] = showSlideShow(list[row],list[row][col].id,port)
					dialog = showLoadingScreen("Loading" ,port)
					'populate any new reddit posts we got during the slideshow
				    grid.SetContentList(row, list[row]) 
				    'send the user back to the original location in the grid
				    grid.SetListOffset(row,col)
					dialog.close()
					
				 ELSE IF(list[row][col].name = "loadmore" )
				 
					'load more posts for this subreddit
					dialog = showLoadingScreen( "loading MOAR",port)
					subReddit = list[row][col].subReddit
					after = getTheAfter(list[row])	
					list[row] = removeOldLoadMore(list[row])
					newPosts = loadMorePosts(subReddit,after)
					if(newPosts = invalid)
						showMessage("Unable to load more posts, try again")
					ELSE 

						if(newPosts.count() < 2)
							showMessage("Could not find new posts, please try again")
						END IF
						list[row] = removeOldLoadMore(list[row])
						list[row].Append(newPosts)
						grid.SetContentList(row, list[row])
						'send the user back to the original location in the grid
						grid.SetListOffset(row,col)
					END IF
					dialog.Close()
				 
				 ELSE					
					'for self posts show the comments page
					showComments(list[row][col])
				 END IF
				 

				 END IF
				 
             endif
         endif
     end while
END sub

function buildSubredditGrid(grid, subRedditName,index)
	list = CreateObject("roArray",100, true)		
	list = loadMorePosts(subRedditName,"")
			
	if(list = invalid)
		'build a failed to load icon for the grid
		list = buildErrorGrid()
	END IF
			
	grid.SetContentList(index, list)
	grid.show()
	return list
			
END FUNCTION

function buildErrorGrid()
	tmpList = CreateObject("roArray", 2, true)
	o = CreateObject("roAssociativeArray")
	o.Title = "Error getting subreddit"
	tmpList.Push(o)
	return tmpList
END FUNCTION


Sub initTheme()
    app = CreateObject("roAppManager")
    app.SetTheme(CreateDefaultTheme())
End Sub
'******************************************************
'** @return The default application theme.
'** Screens can make slight adjustments to the default
'** theme by getting it from here and then overriding
'** individual theme attributes.
'******************************************************
Function CreateDefaultTheme() as Object
    theme = CreateObject("roAssociativeArray")

    'theme.ThemeType = "generic-dark"
	
	black = "#000000"
	white = "#ffffff"
	hdLogo = "pkg:/images/reddit-logo-hd.jpg"
	sdLogo = "pkg:/images/reddit-logo-sd.jpg"
	
	theme.BackgroundColor = white
	theme.ParagraphBodyText = black
	
	theme.OverhangSliceHD = "pkg:/images/clear.png"
	theme.OverhangSliceSD = "pkg:/images/clear.png"
    theme.GridScreenBackgroundColor = white
    theme.GridScreenMessageColor    = black
    theme.GridScreenRetrievingColor = black
    theme.GridScreenListNameColor   = black
	
	'one msg dialog
	theme.ButtonMenuNormalOverlayText = white
	theme.ButtonMenuNormalText = black
	theme.ButtonNormalColor = black
	theme.DialogBodyText = black
	theme.ButtonHighlightColor = white
	theme.DialogTitleText = black


    ' Color values work here
    theme.GridScreenDescriptionTitleColor    = black
    theme.GridScreenDescriptionDateColor     = "#FF005B"
    theme.GridScreenDescriptionRuntimeColor  = "#5B005B"
    theme.GridScreenDescriptionSynopsisColor = "#606000"
    
    'used in the Grid Screen
    theme.CounterTextLeft           = black
    theme.CounterSeparator          = black
    theme.CounterTextRight          = black
	
	theme.GridScreenLogoHD          = hdLogo
	theme.OverhangPrimaryLogoHD     = sdLogo
    theme.GridScreenLogoOffsetHD_X  = "0"
    theme.GridScreenLogoOffsetHD_Y  = "0"
    theme.GridScreenOverhangHeightHD = "145"
	
	theme.OverhangPrimaryLogoOffsetHD_X = "220"
	theme.OverhangPrimaryLogoOffsetHD_Y = "15"


	
    theme.GridScreenLogoSD          = sdLogo
	theme.OverhangPrimaryLogoSD     = sdLogo
    theme.GridScreenLogoOffsetSD_X  = "0"
    theme.GridScreenLogoOffsetSD_Y  = "0"
	theme.GridScreenOverhangHeightSD = "100"
    
    ' to use your own focus ring artwork 
   ' theme.GridScreenFocusBorderSD        = "pkg:/images/GridCenter_Border_Movies_SD43.png"
   ' theme.GridScreenBorderOffsetSD  = "(-26,-25)"
   ' theme.GridScreenFocusBorderHD        = "pkg:/images/GridCenter_Border_Movies_HD.png"
  '  theme.GridScreenBorderOffsetHD  = "(-28,-20)"
    
    ' to use your own description background artwork
    'theme.GridScreenDescriptionImageSD  = "pkg:/images/Grid_Description_Background_SD43.png"
    'theme.GridScreenDescriptionOffsetSD = "(25,25)"
   ' theme.GridScreenDescriptionImageHD  = "pkg:/images/Grid_Description_Background_HD.png"
	'theme.GridScreenDescriptionOffsetHD = "(25,25)"
    

    return theme
End Function


Function showMessage(msg As String)
	port = CreateObject("roMessagePort") 
	dialog = CreateObject( "roOneLineDialog" )
	dialog.SetMessagePort(port)
	dialog.SetTitle( msg )
	dialog.Show()
	sleep(3200)
	return -1
END FUNCTION 

Function showLoadingScreen(msg As String,port)
	dialog = CreateObject( "roOneLineDialog" )
	dialog.SetMessagePort(port)
	dialog.ShowBusyAnimation() 
	dialog.SetTitle( msg )
	dialog.Show()
	return dialog
END FUNCTION

Function IsHD()
    di = CreateObject("roDeviceInfo")
    if di.GetDisplayType() = "HDTV" then return true
    return false
End Function