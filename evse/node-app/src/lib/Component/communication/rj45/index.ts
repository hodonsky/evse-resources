"use strict"

import Communication from "../"
import { TRJ45} from "./types"

export class RFID extends Communication implements TRJ45{
    constructor({serialNumber}:{serialNumber:string|number|symbol}){
        super({serialNumber})
    }
}