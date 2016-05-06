import UIKit
import Valet

class KeysViewController: UITableViewController {

    let valet: VALSecureEnclaveValet
    let userDefaults: NSUserDefaults
    var keyIds: [String]

    override init(style: UITableViewStyle) {
        valet = VALSecureEnclaveValet(identifier: "plopper", accessControl: .UserPresence)!

        userDefaults = NSUserDefaults.standardUserDefaults()

        keyIds = []

        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        readKeyIds()

        title = "SSH Keys"

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Add,
            target: self,
            action: #selector(KeysViewController.didTapAddButton)
        )
    }

    func didTapAddButton() {
        let documentMenuViewController = UIDocumentMenuViewController(documentTypes: ["public.data"], inMode: .Import)
        documentMenuViewController.delegate = self
        presentViewController(documentMenuViewController, animated: true, completion: nil)
    }

    func readKeyIds() {
        let storedKeyIds = userDefaults.stringArrayForKey("keyIds")
        if let storedKeyIds = storedKeyIds {
            keyIds = storedKeyIds
        }
    }

    func writeKeyIds() {
        userDefaults.setObject(keyIds, forKey: "keyIds")
    }

}

extension KeysViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keyIds.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let keyId = keyIds[indexPath.row]

        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.accessoryType = .DisclosureIndicator
        cell.textLabel!.text = keyId
        return cell
    }
}

extension KeysViewController {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let keyId = keyIds[indexPath.row]
        let viewController = ComputersViewController(keyId: keyId)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension KeysViewController: UIDocumentMenuDelegate {
    func documentMenu(documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        presentViewController(documentPicker, animated: true, completion: nil)
    }
}

extension KeysViewController: UIDocumentPickerDelegate {
    func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
        print(url)

        if let data = NSData(contentsOfURL: url) {
            if let name = url.lastPathComponent {
                valet.setObject(data, forKey: name)

                keyIds.append(name)
                writeKeyIds()

                tableView.reloadData()
            } else {
                print("Cannot determine name")
            }
        } else {
            print("Cannot load data")
        }
    }
}
