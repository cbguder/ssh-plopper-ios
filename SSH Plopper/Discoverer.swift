import Foundation
import MultipeerConnectivity

class Discoverer: NSObject, MCNearbyServiceBrowserDelegate {

    let browser: MCNearbyServiceBrowser

    override init() {
        let peerId = MCPeerID(displayName: "iPhone Simulator")

        let serviceType = "ssh-key-service"

        browser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)

        super.init()
    }

    func startBrowsing() {
        browser.delegate = self
        browser.startBrowsingForPeers()

        print("Started browsing for peers")
    }

    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: ", peerID)
    }

    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: ", peerID)
    }

    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("Failed to start browsing for peers ", error)
    }

}
