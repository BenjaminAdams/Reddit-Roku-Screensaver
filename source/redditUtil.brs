function getDefaultSubreddits()
    subReddits = CreateObject("roArray", 30, true)
	subReddits.Push("Settings")
	'subReddits.Push("videos")
    subReddits.Push("funny")
	subReddits.Push("pics")
    subReddits.Push("adviceanimals")
    subReddits.Push("aww")
    subReddits.Push("gaming")
    subReddits.Push("earthporn")
    subReddits.Push("wallpapers")
	subReddits.Push("askreddit")
   ' subReddits.Push("todayilearned")
   ' subReddits.Push("gifs")
  '  subReddits.Push("IAmA") 
   ' subReddits.Push("treecomics")
   ' subReddits.Push("news")
   ' subReddits.Push("science")
   ' subReddits.Push("technology")
   ' subReddits.Push("television")
   ' subReddits.Push("todayilearned")
   ' subReddits.Push("worldnews")
   return subReddits
END FUNCTION

function getBlockedSubreddits()
'we need to block subreddits that never have self posts or images
    subReddits = CreateObject("roArray", 30, true)
    subReddits.Push("funny")
	subReddits.Push("pics")
    subReddits.Push("books")
    subReddits.Push("announcements")
    subReddits.Push("explainlikeimfive")
    subReddits.Push("videos")
    subReddits.Push("gifs")
    subReddits.Push("technology")
    subReddits.Push("bestof")
    subReddits.Push("news")
    subReddits.Push("blog")
    subReddits.Push("science")
    subReddits.Push("politics")
    subReddits.Push("todayilearned")
    subReddits.Push("worldnews")
	subReddits.Push("reddit.com")
	subReddits.Push("programming")
	subReddits.Push("gamemusic")
	subReddits.Push("geek")
   return subReddits
END FUNCTION

FUNCTION loadMorePosts(subReddit,after)

	if(subReddit = invalid OR after = invalid)
		print "subreddit or after are invalid"
		return invalid
	END IF
	api_url = "http://www.reddit.com/r/" + subReddit + ".json?after=" + after
	http = NewHttp2(api_url, "application/json")
	response= http.GetToStringWithTimeout(90)
	json = ParseJSON(response)
	if(json = invalid)
		return invalid
	END IF
	newList = parseJsonPosts(json)
	return newList
END FUNCTION


Function parseJsonPosts(json)
	tmpList = CreateObject("roArray", 28, true)
	subReddit = invalid
	modhash = json.data.modhash
	if(modhash <> invalid)
		'print "updating new modhash="+ modhash
		setSetting("modhash", modhash)
	else
	print "modhash is invalid"
	END IF
	
	count = 0
	for each post in json.data.children		
				 IF(subReddit = invalid)
					subReddit = post.data.subreddit			
				 END IF
				 
				 url = fixImgur(post.data.url)
				 self = post.data.is_self
				 
				 if((isGood(url) = false) AND (self = false) AND (isVideo(post.data.domain) = false))
					 'print "Its not an img!"			   
				 else
					 ups = post.data.ups.tostr()
					 downs = post.data.downs.tostr()
					 urlType = ""
					 o = CreateObject("roAssociativeArray")
					' o.ContentType = "episode"
					 o.TextOverlayBody = post.data.title
					 
					 if(self=true)
						 o.Url = "pkg:/images/self.png" 
						 o.SDPosterUrl = "pkg:/images/self.png" 
						 o.HDPosterUrl = "pkg:/images/self.png" 
						 o.self = true
						 o.selftext = post.data.selftext
						 urlType = "[SELF]"
					 else if(post.data.thumbnail = "" OR post.data.thumbnail = "default")
						 o.SDPosterUrl = "pkg:/images/notfound.jpg" 
						 o.HDPosterUrl = "pkg:/images/notfound.jpg" 					 
					 else if(post.data.thumbnail = "nsfw")
						 o.SDPosterUrl = "pkg:/images/nsfw.png" 
						 o.HDPosterUrl = "pkg:/images/nsfw.png" 
						 urlType = "[PIC]"						 
					 else
						 o.Url = url
						 o.SDPosterUrl = post.data.thumbnail
						 o.HDPosterUrl = post.data.thumbnail
						 o.self=false
						 urlType = "[PIC]"
					 END IF
					 
					 
					 if(isVideo(post.data.domain) = true)
						o.video = true
						urlType = "[VID]"
						
					 else
						o.video = false
					 END IF
					 
					 'o.Title = urlType + " " + post.data.title
					 o.Title = post.data.title
					
					 o.ShortDescriptionLine1 = "Upvotes: " + ups + " - Downvotes: " + downs
					 o.ShortDescriptionLine2 = post.data.url
					 o.Description = "Upvotes: " + ups + " - Downvotes: " + downs + "     " + post.data.url
					 
					 o.subReddit = post.data.subreddit
					 o.ups = ups
					 o.downs = downs
					 o.name = post.data.name '.name contains the t3_ prefix
					 o.id = post.data.id 
					 o.selftext = post.data.selftext
					' o.StarRating = "100"
					' o.ReleaseDate = "[<mm/dd/yyyy]"
					' o.Length = 5400
					 o.minBandwidth = 20
					 o.Actors = []
					 o.Actors.Push("Posted by: "+ post.data.author)
					 o.Actors.Push("domain: " + post.data.domain)
					 o.Actors.Push("[Actor3]")
					 o.Director = "[Director]"
					 o.Font = "Large"
					 o.TextAttrs = { 
									Color:"#FFCCCCCC", 
									Font:"Large", 
									HAlign:"HCenter", 
									VAlign:"VCenter", 
									Direction:"LeftToRight" 
									}
					 count = count+1
					 tmpList.Push(o)
				 endif
		end for
		
		'need to store the after variable we can load the next set of posts
		more = generateLoadMorePost(json.data.after, subreddit,count)
		tmpList.Push(more)
		'return the new subreddit posts
		return tmpList
END FUNCTION

FUNCTION generateLoadMorePost(after,subreddit,count)
		more = CreateObject("roAssociativeArray")		
		more.After = after 
		if(count > 0)
			more.Title = "Load More"
		else
			more.Title = "Couldn't find any pictures or self posts, click here to try again"
		END IF
		more.name = "loadmore"
		more.HDPosterUrl =  "pkg:/images/reddit-icon.jpg"
		more.SDPosterUrl =  "pkg:/images/reddit-icon.jpg"
		more.self=true 'the slideshow will update when it comes to this post
		more.Url = "pkg:/images/loading.png" 'shows the loading screen
		'get the subreddit from the json
		more.SubReddit = subReddit	
		return more
END FUNCTION

function userHaveThisSubreddit(subRedditName as String,json) as Boolean		
	for each post in json.data.children	
		name =  LCase(post.data.display_name)
		if (name = subRedditName) THEN
			print "the user IS subscribed to " + subRedditName
			return true
		END IF
	end for
	
	print "the user IS NOT subscribed to " + subRedditName
	return false
END FUNCTION


FUNCTION filterBlockedSubreddits(subReddits,json )
		blocked = getBlockedSubreddits()
		
		for each post in json.data.children	
			found = false
			'block the blocked subreddits
			for i = 0 to blocked.Count() - 1 
				name =  LCase(post.data.display_name)
				if (name = blocked[i]) THEN
					found = true
				END IF
			end for
			if(found = false) THEN
					subReddits.Push(name)
			END IF
		end for
		return subReddits
END FUNCTION

function getSubreddits()
'for testing on certian subreddits
'subReddits = CreateObject("roArray", 300, true)
'subReddits.Push("settings")
'subReddits.Push("askreddit")
'subReddits.Push("aww")
'return subReddits


	if(isLoggedIn() = true)
		
		subReddits = CreateObject("roArray", 300, true)
		'always include these subreddits first
		subReddits.Push("Settings")	
		http = NewHttp2("http://www.reddit.com/reddits/mine.json?limit=100", "application/json")
		response= http.GetToStringWithTimeout(90)
		json = ParseJSON(response)
		print "starting to filter subreddits"
		if(userHaveThisSubreddit("pics",json) = true)
			subReddits.Push("pics")
		end if
		if(userHaveThisSubreddit("funny",json) = true)
			subReddits.Push("funny")
		end if
		subReddits = filterBlockedSubreddits(subReddits,json )

		
		if(subReddits.Count() < 3)
			subReddits = getDefaultSubreddits()
		END IF
		return subReddits
	else
		subReddits =getDefaultSubreddits()
		return subReddits

   END IF

END FUNCTION



FUNCTION savePost(id as String)
	print "saving post id=" +id
	modhash = getSetting("modhash")
	http = NewHttp2("http://www.reddit.com/api/save", "application/json") 
	http.AddParam("id", id)
	http.AddParam("uh", modhash)
	response= http.PostFromStringWithTimeout("", 90)
	'print response
	'dumpArray(response[1])
	'json = ParseJSON(response[1])
	'print dumpArray(json)
	return 0
END FUNCTION


'dir is the vote value either 1, or -1
'Upvote or downvote a "thing" on Reddit
FUNCTION vote(id as String, dir as String)
	modhash = getSetting("modhash")
	http = NewHttp2("http://www.reddit.com/api/vote", "application/json") 
	http.AddParam("id", id)
	http.AddParam("dir", dir)
	http.AddParam("uh", modhash)
	response= http.PostFromStringWithTimeout("", 90)
	'print response
	'dumpArray(response[1])
	'json = ParseJSON(response[1])
	'print dumpArray(json)
	return 0
END FUNCTION

FUNCTION getTheAfter(list) 
	after = "init"
	for each post in list
		if (post.DoesExist("after")=true) then 
			after = post.after
			if(post.after = invalid)
				return invalid
			END IF
			return post.after
			
		END IF
	end for
	
	print "couldnt find the after returning invalid"
	
	if(list <> invalid)
		after = list[list.count() - 1].Lookup("id")
		return after
	else
		return invalid
	END IF

	
END FUNCTION


Function isGood(url as string) as Boolean
	if(isImg(url) = false OR isGallery(url) = false OR isGif(url) = false )
		return false
	else
		return true
	endif
End Function

FUNCTION isVideo(domain as string)
	if(domain = "youtube.com" OR domain="youtu.be")
		return true
	else
		return false
	END IF

END FUNCTION

Function isGif(url as string) as Boolean
	if(right(url, 3) <> "gif")
		return true
	else
		return false
	endif
End Function

Function fixImgur(url as string) as String
if(Instr(1, url, "imgur.com")=0) 'if the domain is not imgur return the original URL
	return url
END IF

if right(url, 3) <> "jpg" AND right(url, 3) <> "png" AND right(url, 4) <> "jpeg"  then
	url = url + ".jpg"
endif
	return url
End Function

Function isImg(url as string) As Boolean
	if right(url, 3) <> "jpg" AND right(url, 3) <> "png" AND right(url, 3) <> "gif" AND right(url, 4) <> "jpeg"  then
		return false
	else
		return true
	endif
End Function

Function fetch_JSON(url as string) as Object

    xfer=createobject("roURLTransfer")
    xfer.seturl(url)
    data=xfer.gettostring()
	if(data = "")
		return invalid
	END IF
    json = ParseJSON(data)

    return json
End Function

Function isGallery(url as string) As Boolean
	if Instr(1, url, "imgur.com/a/") > 0 then
		return false
	else
		return true
	endif
End Function

FUNCTION removeOldLoadMore(list) as Object
	tmpList = CreateObject("roArray", 100, true)

	for each post in list
		if (post.DoesExist("after")=false) then
			tmpList.Push(post)
			'print("not the after")
		else
			'print "this the after"
		END IF
	end for
	
	return tmpList
END FUNCTION



