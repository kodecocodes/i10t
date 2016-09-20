import Intents
import WenderLoonCore

let simulator = WenderLoonSimulator(renderer: nil)
class IntentHandler: INExtension {
  override func handler(for intent: INIntent) -> Any? {
    if intent is INRequestRideIntent {
      return RideRequestHandler(simulator: simulator)
    }
    return .none
  }
}

