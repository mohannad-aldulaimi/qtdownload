load "guilib.ring"  # Required for QApp and Network classes
load "jsonlib.ring"  # Required for json2list function

see "------------------------------------------------" + nl
see " Starting NHTSA Car API Test..." + nl
see " Endpoint: https://vpic.nhtsa.dot.gov/api/" + nl
see "------------------------------------------------" + nl

// 1. Initialize the Qt Application (Required for the Event Loop)
oApp = new qApp {}

// 2. Define the Target URL
// This specific endpoint gets all makes for vehicle type "car"
cTargetUrl = "https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/car?format=json"

// 3. Call QTDownload
QTDownload([
    :url      = cTargetUrl,
    :method   = "GET",
    :callback = func nState, cRes {

        see nl + ">>> Response Received! <<<" + nl

        // Check Network State
        if nState = 0
            see "Error: Network unreachable or request failed." + nl
            oApp.quit()
            return
        ok

        // Parse the JSON response
        try
            see "Status: Success (" + len(cRes) + " bytes received)" + nl

            // Convert JSON string to Ring List
            aData = json2list(cRes)

            // The API returns a root object with "Count", "Message", and "Results"
            see "API Message: " + aData[:Message] + nl
            see "Total Makes Found: " + aData[:Count] + nl

            // Get the list of cars
            aResults = aData[:Results]

            see nl + "--- First 5 Car Makes ---" + nl
            for i = 1 to 5
                if i <= len(aResults)
                    // Accessing the 'MakeName' key from the result item
                    see " " + i + ". " + aResults[i][:MakeName] + nl
                ok
            next

        catch
            see "Error Parsing JSON: " + cCatchError + nl
        done

        see nl + "Test Finished." + nl

        // Exit the application loop
        oApp.quit()
    }
])

// 4. Start the Event Loop
// This pauses the script and waits for the network callback to fire
oApp.exec()