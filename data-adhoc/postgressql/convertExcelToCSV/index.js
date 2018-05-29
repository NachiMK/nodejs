var xlsx = require('node-xlsx');
var fs = require('fs');
var csv = require ('csv-string');

if (process.argv.length <= 2){
    console.error("Invalid number of arguments. Please pass Excel file name and optionally a flag to removeHeader");
    console.log("Sample: node index.js test.xlsx true");
}
else{
    console.log("File to process as per arguments:" + process.argv[2]);
    let removeheader = true;
    if (process.argv.length > 3){
        // console.log(typeof process.argv[3]);
        // console.log(process.argv[3].localeCompare("false"));
        if ((typeof process.argv[3] !== undefined) && (process.argv[3].length > 0) && (process.argv[3].localeCompare("false") == 0))
        {
            // console.log("process.argv[3]:" + process.argv[3]);
            removeheader = false; 
        }
    }
    convertExcelToCSV(process.argv[2], removeheader); 
}

function convertExcelToCSV(filename, removeHeader = true){    
    var excelRows = [];
    var writeStr = "";

    console.log(`Excel File name:{${filename}}`);
    let csvFileName = filename.substring(0, filename.lastIndexOf(".")) + ".csv";    
    let startIdx = (removeHeader) ? 1 : 0;

    try {
        var excelParser = xlsx.parse(filename); // parses a file
        
        // convert only first sheet
        var excelSheet = excelParser[0];

        //looping through all sheets
        //for (var i = 0; i < obj.length; i++) { var sheet = obj[0]; }

        //loop through all rows in the sheet
        for (var j = startIdx; j < excelSheet['data'].length; j++) {
            //add the row to the rows array
            // console.log("CSV stringify" + csv.stringify(sheet['data'][j]));
            // console.log("escape chars:" +escapeSpecialChars(sheet['data'][j]) );
            excelRows.push(csv.stringify(excelSheet['data'][j]));
        }

        //creates the csv string to write it to a file
        for (var i = 0; i < excelRows.length; i++) {
            writeStr += excelRows[i];
        }
    }
    catch(err){
        console.error("Error opening file:" + filename);
    }

    try{
        //writes to a file, but you will presumably send the csv as a      
        //response instead
        if(writeStr.length > 1){
            fs.writeFile(csvFileName, writeStr, function (err) {
                if (err) {
                    return console.log(err);
                }
                console.log(csvFileName + " was saved in the current directory!");
            });
        }
        else {
            console.log("CSV File was not created. There is no data in input file or input file is invalid.");
        }

    }
    catch(err){
        console.error("Error in writing file:" + csvFileName);
    }

}

// function escapeSpecialChars(strToEscape){
//     return strToEscape.map(element => {
//         return "\"" + JSON.stringify(element).replace("\"", "\"\"") + "\"";
//     });
// }