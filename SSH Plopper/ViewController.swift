import UIKit

class ViewController: UIViewController {

    let discoverer: Discoverer

    required init?(coder aDecoder: NSCoder) {
        discoverer = Discoverer()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        discoverer.startBrowsing()
    }

}

