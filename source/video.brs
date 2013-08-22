


function showVideo(originalList,startId, port)
	subReddit = originalList[0].subReddit
	
	
	'dialog = showLoadingScreen( "loading SubReddit:  r/" + subReddit , port)

 
	after = getTheAfter(originalList)
	list= removePicsAndSelf(originalList)
	activeListCount = list.count()
    s =  CreateObject("roVideoScreen") 
    s.SetMessagePort(port)
	
	episode = CreateObject("roAssociativeArray")

episode.HDBranded = false
episode.IsHD = true 
episode.url = "http://www.youtube.com/v/DPlMGujSzQk?version=3&f=videos&d=AeS_OxlRdQyoA0U0KoFqBsYO88HsQjpE1a8d1GxQnGDm&app=youtube_gdata"
episode.Stream = { url:"http://www.youtube.com/v/DPlMGujSzQk?version=3&f=videos&d=AeS_OxlRdQyoA0U0KoFqBsYO88HsQjpE1a8d1GxQnGDm&app=youtube_gdata",
bitrate:2000
quality:true
contentid:"DPlMGujSzQk"
}
	
	's.SetContentList(list)
	'startIndex = findStartIndex(list, startId)
	's.SetNext(startIndex, true)
	
	   s.SetContent(episode)

	
	s.Show()
	'dialog.Close()
	
	

	msg = "declaring"
	row = invalid

	
	
	while true
         msg = wait(0, port)
		

		if type(msg) = "roVideoScreenEvent" then
           print "showVideoScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
           if msg.isScreenClosed()
               print "Screen closed"
               exit while
            else if msg.isStatusMessage()
                  print "status message: "; msg.GetMessage()
            else if msg.isPlaybackPosition()
                  print "playback position: "; msg.GetIndex()
            else if msg.isFullResult()
                  print "playback completed"
                  exit while
            else if msg.isPartialResult()
                  print "playback interrupted"
                  exit while
            else if msg.isRequestFailed()
                  print "request failed – error: "; msg.GetIndex();" – "; msg.GetMessage()
                  exit while
            end if
       end if
    end while
	
End function


FUNCTION removePicsAndSelf(list) as Object
	tmpList = CreateObject("roArray", 122, true)

	for each post in list
		if (post.self=true OR post.video=false) then
			'ignore it
		else
			tmpList.Push(post)
		END IF
	end for
	
	return tmpList
END FUNCTION

