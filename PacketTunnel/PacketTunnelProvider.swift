/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the PacketTunnelProvider class. The PacketTunnelProvider class is a sub-class of NEPacketTunnelProvider, and is the integration point between the Network Extension framework and the SimpleTunnel tunneling protocol.
*/

import NetworkExtension
import SimpleTunnelServices
import SystemConfiguration
/// A packet tunnel provider object.
class PacketTunnelProvider: NEPacketTunnelProvider, TunnelDelegate, ClientTunnelConnectionDelegate {

	// MARK: Properties

	/// A reference to the tunnel object.
	var tunnel: ClientTunnel?

	/// The single logical flow of packets through the tunnel.
	var tunnelConnection: ClientTunnelConnection?

	/// The completion handler to call when the tunnel is fully established.
	var pendingStartCompletion: (NSError? -> Void)?

	/// The completion handler to call when the tunnel is fully disconnected.
	var pendingStopCompletion: (Void -> Void)?

	// MARK: NEPacketTunnelProvider
    var dnssvr:DNSServer?
	/// Begin the process of establishing the tunnel.
    /// Get a password from the keychain.
    func getPasswordWithPersistentReference(persistentReference: NSData) -> String? {
        var result: String?
        let query: [NSObject: AnyObject] = [
            kSecClass : kSecClassGenericPassword,
            kSecReturnData : kCFBooleanTrue,
            kSecValuePersistentRef : persistentReference
        ]
        
        var returnValue: AnyObject?
        let status = SecItemCopyMatching(query, &returnValue)
        
        if let passwordData = returnValue as? NSData where status == errSecSuccess {
            result = NSString(data: passwordData, encoding: NSUTF8StringEncoding) as? String
        }
        return result
    }
    func readPasswordDefaults() ->String {
        let defaults = NSUserDefaults(suiteName:"group.com.fuckgcd.Surf")
        return defaults?.objectForKey("group.com.fuckgcd.password")  as! String
    }
    func prepareTunnelNetworkSettings(){
        
        let setting = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "240.0.0.2")
        let ipv4=NEIPv4Settings(addresses: ["240.0.0.1"], subnetMasks: ["255.255.255.255"])
        
        setting.IPv4Settings = ipv4
        var includedRoutes = [NEIPv4Route]()
        //includedRoutes.append(NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "0.0.0.0"))
        includedRoutes.append(NEIPv4Route.defaultRoute())

        setting.IPv4Settings?.includedRoutes = includedRoutes
        var excludedRoutes = [NEIPv4Route]()
        var route = NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0")
        route.gatewayAddress = NEIPv4Route.defaultRoute().gatewayAddress
        excludedRoutes.append(route)
        route = NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0")
        route.gatewayAddress = NEIPv4Route.defaultRoute().gatewayAddress
        excludedRoutes.append(route)
        route = NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.192.0.0")
        route.gatewayAddress = NEIPv4Route.defaultRoute().gatewayAddress
        excludedRoutes.append(route)
        setting.IPv4Settings?.excludedRoutes = excludedRoutes
        //newSettings.IPv4Settings?.includedRoutes = [NEIPv4Route.defaultRoute()]
        let dserver = SysUtil.loadSystemDNSServer() as String
        NSLog("dns server: %@", dserver)
        setting.DNSSettings = NEDNSSettings(servers: [ dserver ] )//dserver，["127.0.0.1"]
        NSLog("dns server: \(setting.DNSSettings)")

        setting.tunnelOverheadBytes = 150
        setting.proxySettings = NEProxySettings()
        setting.proxySettings?.autoProxyConfigurationEnabled = true;
        
        let path = NSBundle.mainBundle().pathForResource("2", ofType: "js")
        do {
            NSLog("use js")
            let js = try NSString(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
            setting.proxySettings?.proxyAutoConfigurationJavaScript = js as String
        }catch _ {
            NSLog("use url")
            setting.proxySettings?.proxyAutoConfigurationURL = NSURL(string: "http://192.168.2.69/2.js")
        }
        setting.tunnelOverheadBytes = 150
//        guard let settings = createTunnelSettingsFromConfiguration(newIPv4Dictionary) else {
//            pendingStartCompletion?(SimpleTunnelError.InternalError as NSError)
//            pendingStartCompletion = nil
//            return
//        }
        //settings.IPv4Settings
        NSLog("22222")
        setTunnelNetworkSettings(setting) { error in
            var startError: NSError?
            if let error = error {
                myLog("Failed to set the tunnel network settings: \(error)")
                startError = SimpleTunnelError.BadConfiguration as NSError
            }
            else {
                // Now we can start reading and writing packets to/from the virtual interface.
                self.tunnelConnection?.startHandlingPackets()
                NSLog("pass self.tunnelConnection?.startHandlingPackets")
            }
            print(startError)
            // Now the tunnel is fully established, call the start completion handler.
            self.pendingStartCompletion?(startError)
            self.pendingStartCompletion = nil
            //set_config("108.61.126.194","14860","passwordxx","aes-256-cfb")
            //local_main()
            let  proxy = dispatch_queue_create("proxy", nil)
            dispatch_async(proxy) { () -> Void in
                let config = self.protocolConfiguration
                NSLog("-------%@",config);
                NSLog("get password")
                let passwd = self.readPasswordDefaults()//self.getPasswordWithPersistentReference(config.passwordReference!)
                NSLog("get password %@",passwd);
                guard let serverAddress = self.protocolConfiguration.serverAddress else {
                    NSLog("config error")
                    return
                }
                NSLog("%@",serverAddress);
                if let colonRange = serverAddress.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: ":"), options: [], range: nil) {
                    // The server is specified in the configuration as <host>:<port>.
                    let hostname = serverAddress.substringWithRange(Range<String.Index>(start:serverAddress.startIndex, end:colonRange.startIndex))
                    let portString = serverAddress.substringWithRange(Range<String.Index>(start:colonRange.startIndex.successor(), end:serverAddress.endIndex))
                    myLog("server host name : \(hostname) and port \(portString) ")
                    guard !hostname.isEmpty && !portString.isEmpty else {
                        NSLog("server config error")
                        return
                    }
                    
                    //endpoint = NWHostEndpoint(hostname:hostname, port:portString)
                    set_config(hostname,portString,passwd,config.username!)
                    local_main()
                    let config = self.protocolConfiguration
                    NSLog("-------%@",config);
                }
                self.dnssvr = DNSServer()
                //self.dnssvr?.startServer()
            }
        }

    }
    func startHandlingPackets() {
        packetFlow.readPacketsWithCompletionHandler { inPackets, inProtocols in
            self.handlePackets(inPackets, protocols: inProtocols)
        }
    }
    func handlePackets(packets: [NSData], protocols: [NSNumber]) {
        NSLog("handlePackets %@", packets.count)
        // Read more packets.
        self.packetFlow.readPacketsWithCompletionHandler { inPackets, inProtocols in
            self.handlePackets(inPackets, protocols: inProtocols)
        }

    }
	override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        
        //vpn 拨号开始
		let newTunnel = ClientTunnel()
		newTunnel.delegate = self

		if let error = newTunnel.startTunnel(self) {
			completionHandler(error as NSError)
		}
		else {
			// Save the completion handler for when the tunnel is fully established.
			pendingStartCompletion = completionHandler
			tunnel = newTunnel
		}
        
	}

	/// Begin the process of stopping the tunnel.
	override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
		// Clear out any pending start completion handler.
        stopSocks()
		pendingStartCompletion = nil

		// Save the completion handler for when the tunnel is fully disconnected.
		pendingStopCompletion = completionHandler
		tunnel?.closeTunnel()
	}

	/// Handle IPC messages from the app.
	override func handleAppMessage(messageData: NSData, completionHandler: ((NSData?) -> Void)?) {
		guard let messageString = NSString(data: messageData, encoding: NSUTF8StringEncoding) else {
			completionHandler?(nil)
			return
		}

		myLog("Got a message from the app: \(messageString)")

		let responseData = "Hello app".dataUsingEncoding(NSUTF8StringEncoding)
		completionHandler?(responseData)
	}

	// MARK: TunnelDelegate

	/// Handle the event of the tunnel connection being established.
	func tunnelDidOpen(targetTunnel: Tunnel) {
		// Open the logical flow of packets through the tunnel.
        NSLog("stop here")
        
        prepareTunnelNetworkSettings()
        //startHandlingPackets()
        return;
		let newConnection = ClientTunnelConnection(tunnel: tunnel!, clientPacketFlow: packetFlow, connectionDelegate: self)
		newConnection.open()
		tunnelConnection = newConnection
        
	}

	/// Handle the event of the tunnel connection being closed.
	func tunnelDidClose(targetTunnel: Tunnel) {
		if pendingStartCompletion != nil {
			// Closed while starting, call the start completion handler with the appropriate error.
			pendingStartCompletion?(tunnel?.lastError)
			pendingStartCompletion = nil
		}
		else if pendingStopCompletion != nil {
			// Closed as the result of a call to stopTunnelWithReason, call the stop completion handler.
			pendingStopCompletion?()
			pendingStopCompletion = nil
		}
		else {
			// Closed as the result of an error on the tunnel connection, cancel the tunnel.
			cancelTunnelWithError(tunnel?.lastError)
		}
		tunnel = nil
	}

	/// Handle the server sending a configuration.
	func tunnelDidSendConfiguration(targetTunnel: Tunnel, configuration: [String : AnyObject]) {
        print(configuration);
	}

	// MARK: ClientTunnelConnectionDelegate

	/// Handle the event of the logical flow of packets being established through the tunnel.
	func tunnelConnectionDidOpen(connection: ClientTunnelConnection, configuration: [NSObject: AnyObject]) {

		// Create the virtual interface settings.
		guard let settings = createTunnelSettingsFromConfiguration(configuration) else {
			pendingStartCompletion?(SimpleTunnelError.InternalError as NSError)
			pendingStartCompletion = nil
			return
		}
        NSLog("send properties:%@ and setTunnelNetworkSettings %s",settings,__FILE__)
		// Set the virtual interface settings.
		setTunnelNetworkSettings(settings) { error in
			var startError: NSError?
			if let error = error {
				myLog("Failed to set the tunnel network settings: \(error)")
				startError = SimpleTunnelError.BadConfiguration as NSError
			}
			else {
				// Now we can start reading and writing packets to/from the virtual interface.
				self.tunnelConnection?.startHandlingPackets()
			}

			// Now the tunnel is fully established, call the start completion handler.
			self.pendingStartCompletion?(startError)
			self.pendingStartCompletion = nil
		}
	}

	/// Handle the event of the logical flow of packets being torn down.
	func tunnelConnectionDidClose(connection: ClientTunnelConnection, error: NSError?) {
		tunnelConnection = nil
		tunnel?.closeTunnelWithError(error)
	}

	/// Create the tunnel network settings to be applied to the virtual interface.
	func createTunnelSettingsFromConfiguration(configuration: [NSObject: AnyObject]) -> NEPacketTunnelNetworkSettings? {
		guard let tunnelAddress = tunnel?.remoteHost,
			address = getValueFromPlist(configuration, keyArray: [.IPv4, .Address]) as? String,
			netmask = getValueFromPlist(configuration, keyArray: [.IPv4, .Netmask]) as? String
			else { return nil }

		let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelAddress)
		var fullTunnel = true

		newSettings.IPv4Settings = NEIPv4Settings(addresses: [address], subnetMasks: [netmask])

		if let routes = getValueFromPlist(configuration, keyArray: [.IPv4, .Routes]) as? [[String: AnyObject]] {
			var includedRoutes = [NEIPv4Route]()
			for route in routes {
				if let netAddress = route[SettingsKey.Address.rawValue] as? String,
					netMask = route[SettingsKey.Netmask.rawValue] as? String
				{
					includedRoutes.append(NEIPv4Route(destinationAddress: netAddress, subnetMask: netMask))
				}
			}
			newSettings.IPv4Settings?.includedRoutes = includedRoutes
			fullTunnel = false
		}
		else {
			// No routes specified, use the default route.
			newSettings.IPv4Settings?.includedRoutes = [NEIPv4Route.defaultRoute()]
		}

		if let DNSDictionary = configuration[SettingsKey.DNS.rawValue] as? [String: AnyObject],
			DNSServers = DNSDictionary[SettingsKey.Servers.rawValue] as? [String]
		{
			newSettings.DNSSettings = NEDNSSettings(servers: DNSServers)
			if let DNSSearchDomains = DNSDictionary[SettingsKey.SearchDomains.rawValue] as? [String] {
				newSettings.DNSSettings?.searchDomains = DNSSearchDomains
				if !fullTunnel {
					newSettings.DNSSettings?.matchDomains = DNSSearchDomains
				}
			}
		}

		newSettings.tunnelOverheadBytes = 150

		return newSettings
	}
//    /// Copy the default resolver configuration from the system on which the server is running.
//    class func copyDNSConfigurationFromSystem() -> ([String], [String]) {
//        let globalDNSKey = SCDynamicStoreKeyCreateNetworkGlobalEntity(kCFAllocatorDefault, kSCDynamicStoreDomainState, kSCEntNetDNS)
//        var DNSServers = [String]()
//        var DNSSearchDomains = [String]()
//        
//        // The default resolver configuration can be obtained from State:/Network/Global/DNS in the dynamic store.
//        
//        if let globalDNS = SCDynamicStoreCopyValue(nil, globalDNSKey) as? [NSObject: AnyObject],
//            servers = globalDNS[kSCPropNetDNSServerAddresses as String] as? [String]
//        {
//            if let searchDomains = globalDNS[kSCPropNetDNSSearchDomains as String] as? [String] {
//                DNSSearchDomains = searchDomains
//            }
//            DNSServers = servers
//        }
//        
//        return (DNSServers, DNSSearchDomains)
//    }
}
