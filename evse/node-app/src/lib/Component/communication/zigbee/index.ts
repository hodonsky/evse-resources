"use strict"

import Communication from "../"
import { TZigBee} from "./types"

export class ZigBee extends Communication implements TZigBee{
    constructor({serialNumber}:{serialNumber:string|number|symbol}){
        super({serialNumber})
    }
}
export default ZigBee