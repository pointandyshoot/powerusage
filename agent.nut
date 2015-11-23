// v0.2 10/08/2015 Andrew Duncan
//
// Using the built in BlinkUp light sensor on the electric imp
// count the light pulses from an house power meter and send
// the data to an Agent.
//
// This agent will send an update to PVOutput.org and an email
// warning when the battery level runs low.

local battery_alert = 2.9; //voltage at or below to send a low battery email

// When Device sends new readings, Run this!
device.on("new_readings" function(msg) {
    server.log(msg.time_stamp + ", " + msg.sensor_reading + ", " + msg.time_interval);
    //Plotly Data Object
    local data = [{
        x = msg.time_stamp, // Time Stamp from Device
        y = msg.sensor_reading // Sensor Reading from Device
    }];

    // Plotly Layout Object
    local layout = {
        fileopt = "extend",
        filename = "Power Usage",
    };

    // Setting up Data to be POSTed
    local payload = {
    un = "XXXXX",                        //plot.ly username
    key = "XXXXX",                     //plot.ly key
    origin = "plot",
    platform = "electricimp",
    args = http.jsonencode(data),
    kwargs = http.jsonencode(layout),
    version = "0.0.1"
    };
    // encode data and log to Plotly
    local headers = { "Content-Type" : "application/json" };
    local body = http.urlencode(payload);
    local url = "https://plot.ly/clientresp";
  //  HttpPostWrapper(url, headers, body, true);
    
    //encode data and log to PVOutput
    local apikey = "XXXXX";  //PVOutput apikey
    local systemID = "XXXXX";                                   //PVOutput systemID
    local newdate = msg.time_stamp.slice(0,4) + msg.time_stamp.slice(5, 7) + msg.time_stamp.slice(8, 10);
    local newtime = msg.time_stamp.slice(11,16);
    
    //convert pulses to watts
    //1 pulse = 1whr
    //time interval is in seconds
    // P (watts) = E (Whr) / t (hr)
    local powerconsumed = (msg.sensor_reading.tofloat() / (msg.time_interval.tofloat() / 3600.0));
    
    //headers = { "Content-Type" : "application/json" };
    //body = http.urlencode(payload);
    url = "http://pvoutput.org/service/r2/addstatus.jsp?key=";
    url = url + apikey;
    url = url + "&sid=" + systemID;
    url = url + "&d=" + newdate;
    url = url + "&t=" + newtime;
    url = url + "&v4=" + powerconsumed;
    url = url + "&v6=" + msg.volt_reading;
    
    server.log(url);
    local PVsend = http.get(url);
    local PVresponse = PVsend.sendsync();
    server.log(http.jsonencode(PVresponse));
    
    //check battery status and send email if low
    if (msg.volt_reading < battery_alert) {
        mailgun("Electric Imp - Battery Low", "Electric Imp voltage: " + msg.volt_reading);    
        
    }
    
    
    
});


// Http Request Handler
function HttpPostWrapper (url, headers, string, log) {
  local request = http.post(url, headers, string);
  local response = request.sendsync();
  if (log)
    server.log(http.jsonencode(response));
  return response;

}

// mailgun sender
function mailgun(subject, message)
{
  local from = "imp@no-reply.com";
  local to   = "XXXXX@XXXXX.COM"   // E-mail address to send alert to
 
  local apikey = "XXXXX";           //mailgun API
  local domain = "XXXXX.mailgun.org";
 
  local request = http.post("https://api:" + apikey + "@api.mailgun.net/v2/" + domain + "/messages", {"Content-Type": "application/x-www-form-urlencoded"}, "from=" + from + "&to=" + to + "&subject=" + subject + "&text=" + message);
 
  local response = request.sendsync();
  server.log("Mailgun response: " + response.body);
}
