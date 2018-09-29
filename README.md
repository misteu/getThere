![app icon](https://github.com/misteu/getThere/blob/master/assets/AppIcon%403x.png "app icon")

This is a little Swift experiment with GPS Localization in combination with an API for requesting station and journey information in Berlin.

The app shows stations around the user on startup. Custom Annotation markers show which means of transportation is servicing that station. If a station is selected, there are popping up all the lines that ride to/from this station.

Via a searchfield the user can start an API request to search for a destination. With the first three typed in characters a request is started, after that the search is just locally in the saved response.

If one of the suggested stations is selected, this station's id is saved as the destination. As soon as a station to start is clicked, another request for that journey is started and the formatted results are presented in a toast message.

![app demo](https://github.com/misteu/getThere/blob/cd8d0acd8bc8bf1c17cda0933b6bedbfe7bd7705/doc/demo.gif "App demo")

uses:
- vbb-rest (https://github.com/derhuerst/vbb-rest)
- MapKit
- CoreLocation
- SearchTextField (https://github.com/apasccon/SearchTextField)
- URLSession (wanted to try requesting without Alamofire the first time ;-) I used this example: https://gist.github.com/cmoulton/7ddc3cfabda1facb040a533f637e74b8)
- some custom artworks made in Sketch with the help of (http://icon8.com/)

![bus icon](https://github.com/misteu/getThere/blob/master/assets/bus.png "bus icon")
![express icon](https://github.com/misteu/getThere/blob/master/assets/express.png "expres icon")
![multi icon](https://github.com/misteu/getThere/blob/master/assets/multi.png "multi icon")
![regional icon](https://github.com/misteu/getThere/blob/master/assets/regional.png "regional icon")
![suburban icon](https://github.com/misteu/getThere/blob/master/assets/suburban.png "suburban icon")
![subway icon](https://github.com/misteu/getThere/blob/master/assets/subway.png "subway icon")
