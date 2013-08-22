
function addButtons(s)
s.AddButton(1, "Hide") 
s.AddButton(2, "Upvote") 
s.AddButton(3, "Downvote") 
s.AddButton(4, "View Comments") 
s.AddButton(5, "Save Post") 
s.AddButton(9, "View Full") 
return s
end function 

function showSlideShow(originalList,startId, port)
	subReddit = originalList[0].subReddit
	
	if(getSetting("helpShown") = invalid)
		showHelp()
		setSetting("helpShown","1")
	END IF
	
	dialog = showLoadingScreen( "loading SubReddit:  r/" + subReddit , port)

	timer = getTimerSetting()
	timer = timer.ToInt()
	timerMilaseconds = timer * 1000
	
	showTitle = getShowTitleSetting()
 
	after = getTheAfter(originalList)	
	list= cleanList(originalList)
	activeListCount = list.count()
    s = CreateObject("roSlideShow")
    s.SetMessagePort(port)
	if(showTitle = "yes")
		s.SetTextOverlayHoldTime(timerMilaseconds)   ' 1 second = 1000 milaseconds
	else
		s.SetTextOverlayIsVisible(false)
		s.SetTextOverlayHoldTime(0)
	end if

	s.SetUnderscan(3) ' gives a padding around the image because TVs cut off the outer part of the image sometimes
	' s.SetDisplayMode("photo-fit") 'I think default is best
	s.SetPeriod(timer) ' dont need this
	
	s.SetContentList(list)
	startIndex = findStartIndex(list, startId)
	s.SetNext(startIndex, true)
	s.Show()
	dialog.Close()
	
	
	buttonsShownOnce = false
	msg = "declaring"
	row = invalid
	addThesePosts = CreateObject("roArray", 28, true)
	attemptMoreCount = 0
	paused = false
	
	
	while true
         msg = wait(0, port)
		 if type(msg) = "roSlideShowEvent" then
		   if msg.isRemoteKeyPressed() then
		   
					'show the button menu to interact with reddit post
			  if(msg.getIndex()=6)
			     print "adding btns"
				 paused = true
                 s= addButtons(s)
			  END IF	  		  
		  END IF
		

		    if msg.isRequestSucceeded() then
		 		if((after <> invalid) AND (paused = false) AND (attemptMoreCount < 55) )
						print "attempting to load more posts attempt = " + attemptMoreCount.tostr()
						attemptMoreCount = attemptMoreCount +1
						
						newList = loadMorePosts(subReddit, after)
						if(newList = invalid)
							'do nothing
							print "newList was invalid" 
						else
							after = getTheAfter(newList)	
									
							newListRemovedSelf = cleanList(newList)
							
							'make sure the new subreddits we found contained at least one image
							if(newListRemovedSelf.count() > 1)
								print "adding more posts count= " + newListRemovedSelf.count().tostr()
								list.Append(newListRemovedSelf)
								addThesePosts.Append(newListRemovedSelf)
							END IF
						END IF
				else
					'print "after is invalid"
				END IF
		    END IF
		 
		 
		 'EXIT slideshow

             if msg.isScreenClosed() then
				'return the list that also contains the self posts
				 originalList = removeOldLoadMore(originalList)
				 originalList.Append(list)
				 
				 'add a load more to this
				 if(attemptMoreCount < 40) ' we dont want to have a load more if theres already a ton of posts
					after = getTheAfter(list)
					
					if(after <> invalid)
						more = generateLoadMorePost(after,subreddit, 99) 'the count variable just needs to be > 0
						print "returning back to the grid after= " +after
						print "more.after = " + more.after
						originalList.Push(more)
					END IF
				 END IF
                 return originalList 'when the user closes the screen return any new reddit posts we downloaded
			 end if

			 IF msg.isPlaybackPosition() THEN
			 
					row = msg.GetIndex()   'keeps the variable row supplied with the list index
					print  row.tostr() +"/" + (activeListCount-1).tostr() + " pending to add =" +addThesePosts.count().tostr() 
			

						IF  (addThesePosts.count() > 0) AND (paused = false) THEN
							'add more posts to the slideshow
							FOR EACH post IN addThesePosts
								s.AddContent(post)
								s.show()
							END FOR
							
							activeListCount = activeListCount + addThesePosts.count()
							's.SetNext(activeListCount -2, false)

							print "REFRESHING SLIDESHOW adding new posts =  " + addThesePosts.count().tostr() 
							'after we are done adding new posts clear the list containing new posts
							addThesePosts.Clear()
							
						END IF
					

			 END IF
			 
			 if msg.isResumed() then
				print "removing btns"
                s.ClearButtons()
				paused = false
			 end if
			 
			 if msg.isButtonPressed() then
				index = msg.GetIndex()
			 'RESUME
				IF index = 1 THEN
					print "User hit resume"
					s.ClearButtons()
					s.Resume()
					paused = false
				END IF
				
				if(isLoggedIn() = false AND (index =2 OR index=3 OR index = 5)) THEN
				'show need to login msg
					showMessage("Please login first")
				ELSE IF index = 2 THEN			
				'UPVOTE
					print "User hit upvote btn"
					vote(list[row].name, "1")
					s.ClearButtons()
					paused = false			
				'DOWNVOTE
				ELSE IF index = 3 THEN
					print "User hit downvote btn"
					vote(list[row].name, "-1")
					s.ClearButtons()
					paused = false
				ELSE IF index = 5 THEN
				'SAVE POST
					print "save post: " + list[row].Title
					savePost(list[row].name)
					s.ClearButtons()
					paused = false
				END IF
				
				IF index = 4 THEN
					print "view comments"
					showComments(list[row])
				END IF
				
			
				IF index = 9 THEN
					print "view full img"
					showImg(list[row].Url) 
				END IF
				
				end if
			 
		 end if
    end while
	
End function


FUNCTION cleanList(list) as Object
	tmpList = CreateObject("roArray", 122, true)

	for each post in list
		if (post.self=false AND post.video=false) then
			tmpList.Push(post)
		END IF
	end for
	
	return tmpList
END FUNCTION




'pass in the list and the start ID and find the index the ID has
FUNCTION findStartIndex(list, id)
	for i = 0 to list.Count() - 1
		if(list[i].id=id)
			return i
		end if
	end for
	
	print "COULDNT FIND START INDEX"
	return 0
END FUNCTION

