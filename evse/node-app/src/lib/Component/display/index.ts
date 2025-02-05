"use strict"

import ComponentModule from "../common"
import { EScreenType, EScreenResolution } from "./enums"
import { TDisplay } from "./types"

export class TFTDisplay extends ComponentModule implements TDisplay {
  screenType  : EScreenType.LCD
  screenSize  : 0
  bits        : number
  resolution  : EScreenResolution.FOUR_HUNDRED_X_THREE_HUNDRED_TWENTY
}

export class TouchDisplay extends ComponentModule implements TDisplay {
  screenType  : EScreenType.TOUCH_LCD
  screenSize  : 0
  bits        : number     
  resolution  : EScreenResolution.FOUR_HUNDRED_X_THREE_HUNDRED_TWENTY
}