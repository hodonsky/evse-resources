// -- ESNext --
import Gateway from "@hodonsky/node-gateway"
import getEmail from "./auth/actions/getEmail"
import getToken from "./auth/actions/getToken"
import authToken from "./auth/actions/authToken"


const koaMiddleware = [
  require( "koa-cors"   )(),
  require( "koa-helmet" )(),
  require( "koa-morgan" )( "combined" )
]

if ( process.env.NODE_ENV === "production" ){
  koaMiddleware.push(
    require( "koa-sslify" )({
      trustProtoHeader     : true,
      redirectMethods      : [ "HEAD", "OPTIONS", "GET", "POST" ],
      specCompliantDisallow: true
    })
  ) 
}

const options = { koaMiddleware }
const gateway = new Gateway( options )

gateway
  .on( "ready", console.log )
  .on( "error", err => console.log( "ERROR:", err ) )
  .post( "/auth", getToken )
  .post( "/getEmail/:userId", authToken, getEmail )
  .listen()

export default gateway