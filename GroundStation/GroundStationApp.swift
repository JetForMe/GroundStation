//
//  GroundStationApp.swift
//  GroundStation
//
//  Created by Rick Mann on 2023-11-28.
//

import os

import CoreLocation
import SwiftUI








@main
struct
GroundStationApp : App
{
	var
	body: some Scene
	{
		Window("Debug", id: "debug")
		{
			Button("Open port")
			{
				do
				{
					let port = LZSerialPort(path: "/dev/tty.usbserial-FTF0GIP9", speed: .baud115200)
					self.port = port
					
					port.setReceiveCallback(callback:
							{ inDone, inData, inError in
								if let data = inData
								{
									let s = String(data: data, encoding: .utf8)!
									Self.logger.info("Received \(data.count) bytes: \(s, privacy: .public)")
								}
							})
					
					try port.openPort()
				}
				
				catch
				{
					Self.logger.error("Error in LZSerialPort: \(String(describing: error), privacy: .public)")
				}
			}
			.disabled(self.port != nil)
			
			Button("Do a Read")
			{
				self.port?.doARead()
			}
			.disabled(self.port == nil)
			
			Button("Do a Write")
			{
				self.port?.write(data: "Well, hello there!\r\n".data(using: .utf8)!)
			}
			.disabled(self.port == nil)
		}
		
		DocumentGroup(newDocument: GroundStationDocument())
		{ file in
			ContentView(document: file.$document)
				.onAppear()
				{
					self.globalState.startTrackingUser()
				}
		}
		.environment(self.globalState)
	}
	
	@State	private	var	port			:	LZSerialPort?
	@State	private	var	globalState						=	GlobalState()

	@Environment(\.scenePhase)	private	var	scenePhase

	static	private	let	logger							=	Logger(subsystem: "com.latencyzero.GroundStation", category: "GroundStationApp")
}



/**
	This class holds state for the entire app, regardless of
	which documents are open. Things like the current location
	of the ground station.
*/

@Observable
class
GlobalState : NSObject
{
	var		currentLocation				:	CLLocation?
	
	override
	init()
	{
		super.init()
		
		self.locationManager.delegate = self
	}
	
	func
	startTrackingUser()
	{
		self.locationManager.startUpdatingLocation()
	}
	
	
	private var	locationManager			=	CLLocationManager()
	
	static	private	let	logger							=	Logger(subsystem: "com.latencyzero.GroundStation", category: "GlobalState")
}

extension
GlobalState : CLLocationManagerDelegate
{
	func
	locationManager(_ inMgr: CLLocationManager, didUpdateLocations inLocations: [CLLocation])
	{
		self.currentLocation = inLocations.first
		Self.logger.info("Got user location: \(String(describing: self.currentLocation), privacy: .public)")
	}
}
