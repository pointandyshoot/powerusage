// v0.1 23/07/2015 Andrew Duncan
//
// Using the built in BlinkUp light sensor on the electric imp
// count the light pulses from an house power meter and send
// the data to an Agent.

// initialize variables
local light_count = 0;      //pulses per post interval (1 pulse per Whr)
local old_light_level = 0;
local sensitivity = 5000;   //larger number is less sensitive to light change
local time_to_post = 300;  //seconds between sending count update to server
local time_to_count = 0.1;  //seconds between looking for light change

// function returns light value out of ~65k
function getSensor() {
    return (hardware.lightlevel());
}

// compare light levels, increment count if light level has changed sufficiently
function compareSensor() {
    
    //How often to check for change in light level
    imp.wakeup(time_to_count, compareSensor)
    
    local new_light_level = getSensor();
    if (math.abs(new_light_level - old_light_level) > sensitivity)
        light_count++;
    old_light_level = new_light_level;
}

// Send Sensor Data to be plotted
function sendDataToAgent() {
    // How often to post an update
    imp.wakeup(time_to_post, sendDataToAgent);
    
    server.log(light_count);

    local sensordata = {
        sensor_reading = light_count,
        time_stamp = getTime(),
        time_interval = time_to_post,
        volt_reading = hardware.voltage()
    }
    
    server.log(getTime());
    agent.send("new_readings", sensordata);        
    light_count = 0;    //reset counter after post
}


// Get Time String, -14400 is for -4 GMT (Montreal)
// use 3600 and multiply by the hours +/- GMT.
// e.g for +5 GMT local date = date(time()+18000, "u");
function getTime() {
    local date = date(time()+28800, "u");
    local sec = stringTime(date["sec"]);
    local min = stringTime(date["min"]);
    local hour = stringTime(date["hour"]);
    local day = stringTime(date["day"]);
    local month = stringTime(date["month"]+1); //month range is from 0 to 11
    local year = date["year"];
    return year+"-"+month+"-"+day+" "+hour+":"+min+":"+sec;

}

// Fix Time String
function stringTime(num) {
    if (num < 10)
        return "0"+num;
    else
        return ""+num;
}

function debug() {
    imp.wakeup(2, debug);
    server.log("debug: " + light_count + ", " + old_light_level)
}

// Initialize Loop
compareSensor();
sendDataToAgent();
//debug();
