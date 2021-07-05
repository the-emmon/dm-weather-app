import jester, asyncdispatch, strutils, strformat, json
from httpclient import newHttpClient, getContent
from htmlgen import h1

var readConf = readFile("config.ini"); readConf.stripLineEnd() # Read config, remove newline at the end of the file.

var
  config   = readConf.replace("apikey=", "\"apikey\": ").replace("sitename=", "\"sitename\": ").replace("\n", ", ")
  strJson  = "{" & config & "}" # Q: "What are you?" config: "An idiot sandwich"
  cfgJson  = parseJson(strJson)
  apiKey   = replace($cfgJson["apikey"], "\"", "")
  siteName = replace($cfgJson["sitename"], "\"", "") # Config file has been fully read into variables.
  client   = newHttpClient() # To query the API
  gZipcP   = readFile("wpage.html").split("|")[0].replace("APPNAME", siteName)
  gFcstP   = readFile("wpage.html").split("|")[1].replace("APPNAME", siteName)
  apiUrl   = "http://dataservice.accuweather.com/forecasts/v1/daily/5day/"
  apiZip   = fmt"http://dataservice.accuweather.com/locations/v1/postalcodes/search?apikey={apiKey}&q=" # Display the config.ini set title instead of "APPNAME".
  city = ""
  zipcode = ""
  zip2 = ""
  zip3 = ""
  zip4 = ""
  zip5 = ""
  check = ""

proc grabZip(zip: string): (string, string) = # Trades the zipcode that was entered for an API location code.
  var
    url = apiZip & zip
    res = $client.getContent(url)
  return (res.split("\"Key\":\"")[1].split("\",")[0], res.split("EnglishName\":\"")[1].split("\"")[0]) # Grab API location keycode

proc grabWeather(zip:string): seq = # Calls grabZip, then uses the resulting location key to get the zipcode's forecast
  var
    loc    = zip
    parse  = parseJson($client.getContent(fmt"{apiUrl}{loc}?apikey={apiKey}")) # Get API data as a string, parse it into json.
    reduce = $parse{"DailyForecasts"} # Eliminate superfluous data from the results; we only need DailyForecasts.
    days   = reduce.replace("[", "").replace("]", "").replace(",{", ",{{").split(",{") # API returns an entire JSON object for each day; split to sequence var.
  return days

proc animate(replacezip:string, html:string, forecast:string, date:string, city:string, date1:string, date2:string, date3:string, date4:string, date5:string, range:string):string = # returns html to resp with
  var # Fed api data, modifies the HTML template in wpage.html, then responds with the proper visuals.
    page = html.replace("DAY1", date1.split("021-")[1]) # Should have used a template for every single scenario, but I was hoping to keep req files to a minimum.
  page = page.replace("DAY2", date2.split("021-")[1]) # The result is this hard-to-read replacement fest.
  page = page.replace("DAY3", date3.split("021-")[1])
  page = page.replace("DAY4", date4.split("021-")[1])
  page = page.replace("DAY5", date5.split("021-")[1])
  page = page.replace("REPLACERANGE", range)
  page = page.replace("REPLACEDATE", date)
  page = page.replace("REPLACECITY", city)
  page = page.replace("REPLACETHIS", forecast.replace("\"", ""))
  page = page.replace("ZIPHERE", replacezip)
  if "unny" in forecast or forecast == "Intermittent clouds" or "howers" in forecast or forecast == "Mostly cloudy w/ t-storms" or forecast == "Mostly cloudy" or forecast == "Cloudy" or forecast == "Hazy sunshine" or forecast == "Mostly cloudy w/ showers" or forecast == "Partly sunny w/ t-storms" or forecast == "Mostly cloudy w/ flurries" or forecast == "Mostly cloudy w/ snow" or forecast == "Ice" or forecast == "Hot":
    page = page.replace("hidden;' name='sun", "visible;' name='sun")
  if forecast == "Mostly cloudy" or forecast == "Cloudy":
    page = page.replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("hidden;' name='cloud1", "visible;' name='cloud1").replace("hidden;' name='cloud2", "visible;' name='cloud2").replace("hidden;' name='cloud3", "visible;' name='cloud3").replace("hidden;' name='cloud4", "visible;' name='cloud4")
  elif forecast == "Intermittent clouds":
    page = page.replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("hidden;' name='cloud1", "visible;' name='cloud1").replace("hidden;' name='cloud2", "visible;' name='cloud2")
  elif forecast == "Partly sunny":
    page = page.replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("hidden;' name='cloud1", "visible;' name='cloud1").replace("hidden;' name='cloud2", "visible;' name='cloud2").replace("hidden;' name='cloud3", "visible;' name='cloud3").replace("hidden;' name='cloud4", "visible;' name='cloud4")
  elif forecast == "Mostly sunny":
    page = page.replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("hidden;' name='cloud2", "visible;' name='cloud2")
  elif forecast == "Thunderstorms" or forecast == "Mostly cloudy w/ t-storms" or forecast == "t-storms" or forecast == "T-storms" or forecast == "Partly sunny w/ t-storms":
    page = page.replace("<img src=/img/cloud0.png style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: hidden;' name='cloud1'>", "<img src=/img/dark.gif style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: visible;' name='cloud1'>").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/dark.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>").replace("hidden;' name='cloud4", "visible;' name='cloud4").replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("/img/cloud0.png", "/img/lightning.gif").replace("/img/baby.gif", "/img/lightning.gif").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/dark.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>")
  elif forecast == "Freezing rain" or forecast == "Sleet" or forecast == "Rain and snow":
    page = page.replace("<img src=/img/cloud0.png style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: hidden;' name='cloud1'>", "<img src=/img/snow.gif style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: visible;' name='cloud1'>").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/snow.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>").replace("hidden;' name='cloud4", "visible;' name='cloud4").replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("/img/cloud0.png", "/img/rain.gif").replace("/img/baby.gif", "/img/rain.gif").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/snow.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>")
  elif forecast == "Rain":
    page = page.replace("<img src=/img/cloud0.png style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: hidden;' name='cloud1'>", "<img src=/img/rain.gif style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: visible;' name='cloud1'>").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/rain.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>").replace("hidden;' name='cloud4", "visible;' name='cloud4").replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("/img/cloud0.png", "/img/rain.gif").replace("/img/baby.gif", "/img/rain.gif").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/cloud.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>")
  elif forecast == "Snow" or forecast == "Mostly cloudy w/ snow" or forecast == "Ice" or forecast == "Sleet" or forecast == "Mostly cloudy w/ flurries" or forecast == "Partly sunny w/ flurries" or forecast == "Flurries":
    page = page.replace("<img src=/img/cloud0.png style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: hidden;' name='cloud1'>", "<img src=/img/dark.gif style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: visible;' name='cloud1'>").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/dark.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>").replace("hidden;' name='cloud4", "visible;' name='cloud4").replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("/img/cloud0.png", "/img/snow.gif").replace("/img/baby.gif", "/img/snow.gif").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/dark.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>")
  elif "howers" in forecast:
    page = page.replace("<img src=/img/cloud0.png style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: hidden;' name='cloud1'>", "<img src=/img/dark.gif style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: visible;' name='cloud1'>").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/dark.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>").replace("hidden;' name='cloud4", "visible;' name='cloud4").replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("/img/cloud0.png", "/img/rain.gif").replace("/img/baby.gif", "/img/rain.gif").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/dark.gif style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>")
  elif forecast == "Cold" or forecast == "Windy":
    page = page.replace("<img src=/img/cloud0.png style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: hidden;' name='cloud1'>", "<img src=/img/cloud0.png style='width: 22%; position:relative; left: -285px; top:70px; -webkit-animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-left 2.8s cubic-bezier(0.250, 0.460,0.450, 0.940) both; visibility: visible;' name='cloud1'>").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>").replace("hidden;' name='cloud4", "visible;' name='cloud4").replace("hidden;' name='cloud0", "visible;' name='cloud0").replace("/img/baby.gif", "/img/wind.gif").replace("<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: hidden;' name='cloud2'>", "<img src=/img/cloud0.png style='width: 21%; position:relative; left: -315px; top:30px; -webkit-animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; animation: slide-in-right 2.8s cubic-bezier(0.250, 0.460, 0.450, 0.940) both; visibility: visible;' name='cloud2'>").replace("cloud0.png", "cloud.gif")
  if forecast == "Dreary" or forecast == "Partly sunny w/ t-storms" or forecast == "Thunderstorms" or forecast == "Overcast" or forecast == "Fog" or forecast == "Mostly cloudy w/ t-storms" or forecast == "T-storms" or forecast == "T-Storms" or forecast == "Rain" or forecast == "Flurries" or forecast == "Sleet" or forecast == "Freezing Rain" or forecast == "Rain anad snow":
    return page.replace("REPLACETH1S", "background: rgb(37,29,29); background: linear-gradient(0deg, rgba(37,29,29,1) 0%, rgba(19,6,6,1) 3%, rgba(23,134,10,1) 4%, rgba(62,130,72,1) 5%, rgba(32,35,71,0.4318102240896359) 7%, rgba(39,45,74,1) 100%); color: white; font-family: 'Patua One', cursive; font-size:42px;")
  else:
    return page.replace("REPLACETH1S", "background: linear-gradient(0deg, rgba(37,29,29,1) 0%, rgba(19,6,6,1) 3%, rgba(23,134,10,1) 4%, rgba(62,130,72,1) 4.5%, rgba(135,177,200,1) 5%, rgba(88,155,217,1) 100%); color: white; font-family: 'Patua One', cursive; font-size:42px;")

proc validate(params:string):string = # Check to ensure that parameters aren't being tampered with.
  try: # redirect is to handle weirdness, safe is for proper input, and tamper is for potentially malicious tampering.
    if params == "{:}" or params == "{\"zipcode\": \"\"}" or params == "{\"zipcode\": \"ZIPHERE\"}":
      return "redirect"
    elif len(replace($parseJson(params){"zipcode"}, "\"", "")) == 5 and parseInt(replace($parseJson(params){"zipcode"}, "\"", "")) > 0:
      return "safe"
    else:
      return "tamper"
  except:
    return "tamper"

routes: # Defining routes. Everything that isn't a valid weather visual page is rerouted to "/"
  get "/":
    echo fmt"{$request.ip} - GET {$request.path} 200"
    resp gZipcP
  post "/day1":
    redirect(uri("/"))
  get "/day1":
    var check = validate($request.params) # Verify that our parameter is legitimate input.
    if check == "tamper": # Send a message if someone tries to mess with the zip param
      resp h1("PS /> Invoke-RascalsAfoot") & h1("ye be fiddlin with the devil when ye fiddle with m' params!") & gZipcP
    elif check == "safe": # The only "if" that continues. Logs a valid 200 and the path
      echo fmt"{$request.ip} - GET {$request.path} {$request.params} 200"
    elif check == "redirect": # If the parameter is missing or blank, load the index page
      redirect(uri("/"))
    try: # Getting weather data and formatting it via proc calls and var assigns.
      var # In hindsight, this should have been done entirely in a procedure. Routes behave as kind of "half-procedures" - I had to do some var name modification in ensuing routes once I discovered that.
        (zip, city) = grabZip(replace($parseJson($request.params){"zipcode"}, "\"", "")) # Gets loc. key and city name
        days1 = grabWeather(zip) # gets weather for zipcode using API zip location key
        zipcode = replace($parseJson($request.params){"zipcode"}, "\"", "")
        day1 = parseJson($days1[0]) # Map out the next 5 days of data into json
        day2 = parseJson($days1[1])
        day3 = parseJson($days1[2])
        day4 = parseJson($days1[3])
        day5 = parseJson($days1[4])
        day1Min = split($day1{"Temperature", "Minimum", "Value"}, ".")[0] # min and max temperatures defined
        day1Max = split($day1{"Temperature", "Maximum", "Value"}, ".")[0]
        day1Range = fmt"High: {day1Max} Low: {day1Min}" # formatting into a string to print
        day1Fcst = replace($day1{"Day", "IconPhrase"}, "\"", "") # Forecast for this /day1 endpoint
        day1Date = split($day1{"Date"}, "T0")[0].replace("\"", "") # Display the proper dates for the next 5 days
        day2Date = split($day2{"Date"}, "T0")[0].replace("\"", "") # Wanted to keep binary size low so used split instead of parsing date into a format with a library
        day3Date = split($day3{"Date"}, "T0")[0].replace("\"", "") # probably a terrible idea, but it seems happy.
        day4Date = split($day4{"Date"}, "T0")[0].replace("\"", "")
        day5Date = split($day5{"Date"}, "T0")[0].replace("\"", "")
      resp animate(zipcode, gFcstP, $day1Fcst, day1Date, city, day1Date, day2Date, day3Date, day4Date, day5Date, day1Range) # animate() returns full html with proper visuals for the forecast.
    except: # If the API fails us or the zip code is incorrect. Return error msg and index page
      resp "An error has occurred! Perhaps you entered a nonexisting zipcode?" & gZipcP # Avoid a full path reveal error msg if api returns error.
  get "/day2": # Every other day GET route is fairly identical to the first.
    check = validate($request.params)
    if check == "tamper":
      resp h1("PS /> Invoke-RascalsAfoot") & h1("ye be fiddlin with the devil when ye fiddle with m' params!") & gZipcP
    elif check == "safe":
      echo fmt"{$request.ip} - GET {$request.path} {$request.params} 200"
    else:
      redirect(uri("/"))
    try:
      (zip2, city) = grabZip(replace($parseJson($request.params){"zipcode"}, "\"", ""))
      zipcode = replace($parseJson($request.params){"zipcode"}, "\"", "")
      var
        days2 = grabWeather($zip2)
        day21 = parseJson($days2[0])
        day22 = parseJson($days2[1])
        day23 = parseJson($days2[2])
        day24 = parseJson($days2[3])
        day25 = parseJson($days2[4])
        day2Min = split($day22{"Temperature", "Minimum", "Value"}, ".")[0]
        day2Max = split($day22{"Temperature", "Maximum", "Value"}, ".")[0]
        day2Range = fmt"High: {day2Max} Low: {day2Min}"
        day2Fcst = replace($day22{"Day", "IconPhrase"}, "\"", "")
        day1Date = split($day21{"Date"}, "T0")[0].replace("\"", "")
        day2Date = split($day22{"Date"}, "T0")[0].replace("\"", "")
        day3Date = split($day23{"Date"}, "T0")[0].replace("\"", "")
        day4Date = split($day24{"Date"}, "T0")[0].replace("\"", "")
        day5Date = split($day25{"Date"}, "T0")[0].replace("\"", "")
      resp animate(zipcode, gFcstP, $day2Fcst, day2Date, city, day1Date, day2Date, day3Date, day4Date, day5Date, day2Range)
    except:
      resp "An error has occurred! Perhaps you entered a nonexisting zipcode?" & gZipcP
  get "/day3":
    check = validate($request.params)
    if check == "tamper":
      resp h1("PS /> Invoke-RascalsAfoot") & h1("ye be fiddlin with the devil when ye fiddle with m' params!") & gZipcP
    elif check == "safe":
      echo fmt"{$request.ip} - GET {$request.path} {$request.params} 200"
    else:
      redirect(uri("/"))
    try:
      zipcode = replace($parseJson($request.params){"zipcode"}, "\"", "")
      (zip3, city) = grabZip(replace($parseJson($request.params){"zipcode"}, "\"", ""))
      var
        days3 = grabWeather($zip3)
        day31 = parseJson($days3[0])
        day32 = parseJson($days3[1])
        day33 = parseJson($days3[2])
        day34 = parseJson($days3[3])
        day35 = parseJson($days3[4])
        day3Min = split($day33{"Temperature", "Minimum", "Value"}, ".")[0]
        day3Max = split($day33{"Temperature", "Maximum", "Value"}, ".")[0]
        day3Range = fmt"High: {day3Max} Low: {day3Min}"
        day3Fcst = replace($day33{"Day", "IconPhrase"}, "\"", "")
        day1Date = split($day31{"Date"}, "T0")[0].replace("\"", "")
        day2Date = split($day32{"Date"}, "T0")[0].replace("\"", "")
        day3Date = split($day33{"Date"}, "T0")[0].replace("\"", "")
        day4Date = split($day34{"Date"}, "T0")[0].replace("\"", "")
        day5Date = split($day35{"Date"}, "T0")[0].replace("\"", "")
      resp animate(zipcode, gFcstP, $day3Fcst, day3Date, city, day1Date, day2Date, day3Date, day4Date, day5Date, day3Range)
    except:
      resp "An error has occurred! Perhaps you entered a nonexisting zipcode?" & gZipcP
  get "/day4":
    check = validate($request.params)
    if check == "tamper":
      resp h1("PS /> Invoke-RascalsAfoot") & h1("ye be fiddlin with the devil when ye fiddle with m' params!") & gZipcP
    elif check == "safe":
      echo fmt"{$request.ip} - GET {$request.path} {$request.params} 200"
    else:
      redirect(uri("/"))
    try:
      zipcode = replace($parseJson($request.params){"zipcode"}, "\"", "")
      (zip4, city) = grabZip(replace($parseJson($request.params){"zipcode"}, "\"", ""))
      var
        days4 = grabWeather($zip4)
        day41 = parseJson($days4[0])
        day42 = parseJson($days4[1])
        day43 = parseJson($days4[2])
        day44 = parseJson($days4[3])
        day45 = parseJson($days4[4])
        day4Min = split($day44{"Temperature", "Minimum", "Value"}, ".")[0]
        day4Max = split($day44{"Temperature", "Maximum", "Value"}, ".")[0]
        day4Range = fmt"High: {day4Max} Low: {day4Min}"
        day4Fcst = replace($day44{"Day", "IconPhrase"}, "\"", "")
        day1Date = split($day41{"Date"}, "T0")[0].replace("\"", "")
        day2Date = split($day42{"Date"}, "T0")[0].replace("\"", "")
        day3Date = split($day43{"Date"}, "T0")[0].replace("\"", "")
        day4Date = split($day44{"Date"}, "T0")[0].replace("\"", "")
        day5Date = split($day45{"Date"}, "T0")[0].replace("\"", "")
      resp animate(zipcode, gFcstP, $day4Fcst, day4Date, city, day1Date, day2Date, day3Date, day4Date, day5Date, day4Range)
    except:
      resp "An error has occurred! Perhaps you entered a nonexisting zipcode?" & gZipcP
  get "/day5":
    check = validate($request.params)
    if check == "tamper":
      resp h1("PS /> Invoke-RascalsAfoot") & h1("ye be fiddlin with the devil when ye fiddle with m' params!") & gZipcP
    elif check == "safe":
      echo fmt"{$request.ip} - GET {$request.path} {$request.params} 200"
    else:
      redirect(uri("/"))
    try:
      zipcode = replace($parseJson($request.params){"zipcode"}, "\"", "")
      (zip5, city) = grabZip(replace($parseJson($request.params){"zipcode"}, "\"", ""))
      var
        days5 = grabWeather($zip5)
        day51 = parseJson($days5[0])
        day52 = parseJson($days5[1])
        day53 = parseJson($days5[2])
        day54 = parseJson($days5[3])
        day55 = parseJson($days5[4])
        day5Min = split($day55{"Temperature", "Minimum", "Value"}, ".")[0]
        day5Max = split($day55{"Temperature", "Maximum", "Value"}, ".")[0]
        day5Range = fmt"High: {day5Max} Low: {day5Min}"
        day5Fcst = replace($day55{"Day", "IconPhrase"}, "\"", "")
        day1Date = split($day51{"Date"}, "T0")[0].replace("\"", "")
        day2Date = split($day52{"Date"}, "T0")[0].replace("\"", "")
        day3Date = split($day53{"Date"}, "T0")[0].replace("\"", "")
        day4Date = split($day54{"Date"}, "T0")[0].replace("\"", "")
        day5Date = split($day55{"Date"}, "T0")[0].replace("\"", "")
      resp animate(zipcode, gFcstP, $day5Fcst, day5Date, city, day1Date, day2Date, day3Date, day4Date, day5Date, day5Range)
    except:
      resp "An error has occurred! Perhaps you entered a nonexisting zipcode?" & gZipcP
  error Http400: # Handle (and log) 400, 404, and 500 errors to avoid technology identification or full path reveals.
    echo fmt"{$request.ip} - GET {$request.path} 400"
    resp gZipcP
  error Http404:
    echo fmt"{$request.ip} - GET {$request.path} 404"
    resp gZipcP
  error Http500:
    echo fmt"{$request.ip} - GET {$request.path} 500"
    resp gZipcP
