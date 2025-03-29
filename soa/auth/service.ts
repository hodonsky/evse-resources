"use strict"

import Service from "@hodonsky/node-service"

import config    from "./config"

import authToken from "./actions/authToken"
import getEmail  from "./actions/getEmail"
import getToken  from "./actions/getToken"

Service.configure( config )

const service = new Service( { getToken, authToken, getEmail } )

service.on( "reconnecting", () => console.log( "...reconnecting" ) )
service.on( "error", console.log )