import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let screen = UIScreen.mainScreen()

        let keysViewController = KeysViewController(style: .Plain)
        let navigationController = UINavigationController(rootViewController: keysViewController)

        window = UIWindow(frame: screen.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }

}
