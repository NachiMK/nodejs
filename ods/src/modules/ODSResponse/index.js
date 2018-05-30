"use strict";
import moment from 'moment';
const _ = require('lodash');

export async function getDefaultODSResponse(){
    return {
        Status : "Started",
        Error  : {},
        StartTime : moment().format("MM/DD/YYYY HH:mm:ss.SSS"),
        EndTime   : undefined,
        Input  : {},
        // add additional response here as per your needs.
    }
}

export async function setODSResponseStatus_Success(ODSResponse) {
    if (ODSResponse){
        ODSResponse.Status = "Success";
        ODSResponse.EndTime = moment().format("MM/DD/YYYY HH:mm:ss.SSS");
    }
    return ODSResponse;
}

export async function IsResponseSuccess(ODSResponse){
    if ((!_.isUndefined(ODSResponse)) && (!_.isUndefined(ODSResponse.Status)) ){
        if (ODSResponse.Status === "Success"){
            return true;
        }
    }
    return false;
}

export async function setODSResponseStatus_Error(ODSResponse, err){
    if (ODSResponse){
        ODSResponse.Status = "Error";
        ODSResponse.Error  = (!_.isUndefined(err)) ? err : "No Error was provided";
        ODSResponse.EndTime = moment().format("MM/DD/YYYY HH:mm:ss.SSS");
    }
    return ODSResponse;
}

export async function setODSResponseStatus_Processing(ODSResponse, err){
    if (ODSResponse){
        ODSResponse.Status = "Processing";
    }
    return ODSResponse;
}

export async function setODSResponseStatus_EndTime(ODSResponse){
    if (ODSResponse){
        ODSResponse.EndTime = moment().format("MM/DD/YYYY HH:mm:ss.SSS");
    }
    return ODSResponse;
}