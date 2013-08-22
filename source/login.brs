Function login()

	username = getUserInput("Login - Username", "Enter your Reddit username", "")
	if(username = "-1")
		return -1    'user hit the back btn
	END IF
	password = getUserInput("Login - Password", "Enter your Reddit password", "")
	if(password = "-1")
		return -1 'user hit the back btn
	END IF

	 
	http = NewHttp2("http://www.reddit.com/api/login", "application/json") 'we want to use SSL encryption so we dont send a plaintext password 
	'http = NewHttp2("https://ssl.reddit.com/api/login", "application/json")

	http.AddParam("user", username)
	http.AddParam("passwd", password)
	http.AddParam("api_type", "json")
	http.AddParam("rem", "true")
	response= http.PostFromStringWithTimeout("", 90)
	print "resp[0]= " + response[0]
	json = ParseJSON(response[0])
	' response[1] contains the header information

	print  json.json.DoesExist("errors")
	
IF(json = invalid ) then
	print "error logging in"
	showMessage("Unable to login" )
	return "fail"
else if(json.json.DoesExist("errors") = true AND json.json.errors.count() > 0 )
	'reasonAry = json.json.errors
	'reason = reasonAry[1]  ' cant figure out why this variable is invalid
	'showMessage("Unable to login, reason:" +  reason)
	showMessage("Unable to login")
	return "fail"
else
	print "login worked!"
	print json.json.data.cookie
	modhash = json.json.data.modhash
	cookie = json.json.data.cookie
	setSetting("modhash", modhash)
	setSetting("cookie", cookie)
	setSetting("username", username)
	loadMainGrid()
	return username
END IF
END FUNCTION

FUNCTION logout()
	deleteSetting("modhash")
	deleteSetting("cookie")
	deleteSetting("username")
	loadMainGrid()
END FUNCTION

FUNCTION isLoggedIn() as Boolean
	if(getSetting("username") <> invalid)
		return true
	else
		return false
	END IF
END FUNCTION

FUNCTION getModhash() as String
	modhash = getSetting("username")
	if(modhash <> invalid)
		return modhash
	else
		return invalid
	END IF
END FUNCTION


FUNCTION getUserInput(title, dspText, default) as String
	 screen = CreateObject("roKeyboardScreen")
     port = CreateObject("roMessagePort") 
     screen.SetMessagePort(port)
     screen.SetTitle(title)
     screen.SetText(default)
     screen.SetDisplayText(dspText)
     screen.SetMaxLength(45)
     screen.AddButton(1, "next")
     'screen.AddButton(2, "back")
     screen.Show() 
  
     while true
         msg = wait(0, screen.GetMessagePort()) 
         if type(msg) = "roKeyboardScreenEvent"
             if msg.isScreenClosed()
                 return "-1"
             else if msg.isButtonPressed() then
                 print "Evt:"; msg.GetMessage ();" idx:"; msg.GetIndex()
                 if msg.GetIndex() = 1
                     textInput = screen.GetText()
                     print "textInput: "; textInput
                     return textInput 
                 endif
             endif
         endif
     end while 
END FUNCTION

FUNCTION dumpArray(ary)
	for j = 0 to ary.Count() - 1
		print ary[j]
	end for
END FUNCTION

FUNCTION dumpAssArray(list)
	for each post in list
		print "body="+post.body
	end for
END FUNCTION
