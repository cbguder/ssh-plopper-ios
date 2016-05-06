import UIKit
import MultipeerConnectivity
import Valet

class ComputersViewController: UITableViewController {

    let browser: MCNearbyServiceBrowser
    let session: MCSession
    let valet: VALSecureEnclaveValet
    let keyId: String
    var peerIds: NSMutableOrderedSet

    init(keyId: String) {
        self.keyId = keyId

        let device = UIDevice.currentDevice()
        let peerId = MCPeerID(displayName: device.name)
        let serviceType = "ssh-key-service"

        peerIds = NSMutableOrderedSet()

        browser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)

        session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .Required)

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

}

extension ComputersViewController {

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peerIds.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let peerId = peerIds[indexPath.row] as! MCPeerID

        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.accessoryType = .DisclosureIndicator
        cell.textLabel!.text = peerId.displayName
        return cell
    }

}

extension ComputersViewController {

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let peerId = peerIds[indexPath.row] as! MCPeerID

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
        if state == .Connected {
            let data = valet.objectForKey(keyId, userPrompt: "Gimme Yo SSH Key")!

            do {
                try session.sendData(data, toPeers: [peerID], withMode: .Reliable)
            } catch let error {
                print("Failed to send", error)
            }
        }
    }

    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
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

