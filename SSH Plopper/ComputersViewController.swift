import UIKit
import MultipeerConnectivity
import Valet

class ComputersViewController: UITableViewController {

    let browser: MCNearbyServiceBrowser
    let session: MCSession
    let valet: VALSecureEnclaveValet
    let keyId: String
    var peerIds: NSMutableOrderedSet
    var transmittingPeerIds: Set<MCPeerID>

    init(keyId: String) {
        self.keyId = keyId

        let device = UIDevice.currentDevice()
        let myPeerId = MCPeerID(displayName: device.name)
        let serviceType = "ssh-key-service"

        peerIds = NSMutableOrderedSet()
        transmittingPeerIds = Set<MCPeerID>()

        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .Required)

        valet = VALSecureEnclaveValet(identifier: "plopper", accessControl: .UserPresence)!

        super.init(style: .Plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Computers"

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        session.delegate = self

        browser.delegate = self
        browser.startBrowsingForPeers()
    }

    func displayConfirmationCode(confirmationCode: String, peerId: MCPeerID) {
        let alertController = UIAlertController(title: "Confirm Code", message: confirmationCode, preferredStyle: .Alert)

        let confirmAction = UIAlertAction(title: "Confirm", style: .Default) { action in
            if let data = self.valet.objectForKey(self.keyId, userPrompt: "Gimme Yo SSH Key") {
                do {
                    try self.session.sendData(data, toPeers: [peerId], withMode: .Reliable)
                } catch let error {
                    print("Failed to send", error)
                }
            }

            self.cleanupForPeerId(peerId)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            self.cleanupForPeerId(peerId)
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        presentViewController(alertController, animated: true, completion: nil)
    }

    func cleanupForPeerId(peerId: MCPeerID) {
        transmittingPeerIds.remove(peerId)

        let indexPath = NSIndexPath(forRow: peerIds.indexOfObject(peerId), inSection: 0)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

}

extension ComputersViewController {

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peerIds.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let peerId = peerIds[indexPath.row] as! MCPeerID

        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!

        if transmittingPeerIds.contains(peerId) {
            let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            activityIndicatorView.startAnimating()
            cell.accessoryView = activityIndicatorView
            cell.accessoryType = .None
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .DisclosureIndicator
        }

        cell.textLabel!.text = peerId.displayName
        return cell
    }

}

extension ComputersViewController {

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let peerId = peerIds[indexPath.row] as! MCPeerID

        transmittingPeerIds.insert(peerId)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

        browser.invitePeer(peerId, toSession: session, withContext: nil, timeout: 0)
    }

}

extension ComputersViewController: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        peerIds.addObject(peerID)
        tableView.reloadData()
    }

    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        peerIds.removeObject(peerID)
        tableView.reloadData()
    }
}

extension ComputersViewController: MCSessionDelegate {
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        print("Peer changed state", peerID, state.rawValue)
    }

    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        if let str = String(data: data, encoding: NSUTF8StringEncoding) {
            dispatch_async(dispatch_get_main_queue()) {
                self.displayConfirmationCode(str, peerId: peerID)
            }
        } else {
            print("Unable to decode confirmation code")
        }
    }

    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }

    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        certificateHandler(true)
    }

    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
    }

    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
    }
}

