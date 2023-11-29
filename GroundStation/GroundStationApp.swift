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
	
	@State	private	var	globalState				=	GlobalState()
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
