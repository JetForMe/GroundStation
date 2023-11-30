//
//  GroundStationDocument.swift
//  GroundStation
//
//  Created by Rick Mann on 2023-11-28.
//

import os

import SwiftUI
import UniformTypeIdentifiers

import SwiftSerial



extension
UTType
{
	static
	var
	gsConfig: UTType
	{
		UTType(importedAs: "com.latencyzero.GroundStation.groundstation")
	}
}


@Observable
class
GroundStationDocument : FileDocument
{
	var config					:	StationConfig
	var vehicles										=	[Vehicle]()
	var	connected										=	false
	var	lastHeartbeatTime		:	Date?
	
	/**
		Returns true if we have never received telemetry or the
		last receive time was more than five seconds ago.
	*/
	
	var
	noTelemetryReceived: Bool
	{
		lastHeartbeatTime == nil
			|| (lastHeartbeatTime!.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate) > 5
	}
	
	init()
	{
		//	Hard-code some values for now…
		
		self.config = StationConfig(port: "/dev/cu.usbserial-FTF0GIP9---", speed: 57600)
		self.vehicles.append(Vehicle(name: "Hard-coded Vehicle", longitude: -117.92382740743369, latitude: 33.874089406391725, altitude: 100))
	}

	static var readableContentTypes: [UTType]				{ [.gsConfig] }
	
	
	
	required
	init(configuration inConfig: ReadConfiguration)
		throws
	{
		guard
			let data = inConfig.file.regularFileContents
		else
		{
			throw CocoaError(.fileReadCorruptFile)
		}
		self.config = try JSONDecoder().decode(StationConfig.self, from: data)
	}
    
	func
	fileWrapper(configuration _: WriteConfiguration)
		throws
		-> FileWrapper
	{
		let data = try JSONEncoder().encode(self.config)
		return .init(regularFileWithContents: data)
	}
	
	func
	toggleConnection()
		throws
	{
		if self.connected
		{
			self.port?.closePort()
			self.connected = false
		}
		else
		{
			try openPort()
		}
	}
	
	func
	openPort()
		throws
	{
		self.port = SerialPort(path: self.config.port)
		self.port?.setSettings(receiveRate: .baud57600,			//	TODO: set speed from config
								transmitRate: .baud57600,
								minimumBytesToRead: 0,
								timeout: 5 * 10)				//	5-second timeout
		do
		{
			try self.port?.openPort()
		}
		
		catch let error as PortError
		{
			if case .failedToOpen(let errno) = error
			{
				Self.logger.error("Error opening port: \(errno)")
			}
			else
			{
				Self.logger.error("Error opening port: \(error)")
			}
			throw error
		}
		
		self.connected = true
		
		//	Set up our receive task…
		
		if self.receiveQueue == nil
		{
			self.receiveQueue = DispatchQueue(label: "Serial Receive Queue", qos: .background)
		}
		
//		let q = DispatchIO(type: .stream, fileDescriptor: 1, queue: self.receiveQueue!)
//		{ error in
//			print("cleanup DispatchIO: \(error)")
//		}
//		q.read(offset: 0, length: 1024, queue: self.receiveQueue!) { done, data, error in
//			
//		}
		
		self.receiveQueue!.async
		{
			Self.logger.info("Port connected, entering receive loop")
			
			while (self.connected)
			{
				do
				{
					let data = try self.port!.readData(ofLength: 8 * 1024)
					Self.logger.info("Got \(data.count) bytes of data")
					self.receive(data: data)
				}
				
				catch let error as PortError
				{
					Self.logger.error("Error receiving data: \(error)")
					if error == .timeout
					{
						self.receiveDataTimeout()
					}
				}
				
				catch
				{
					Self.logger.error("Error receiving data: \(error)")
				}
			}
			
			Self.logger.info("Port disconnected, exited receive loop")
		}
	}
	
	func
	receive(data inData: Data)
	{
		self.lastHeartbeatTime = Date()
	}
	
	func
	receiveDataTimeout()
	{
	}
	
	var	port					:	SerialPort?
	var	receiveQueue			:	DispatchQueue?
	
	static	private	let	logger							=	Logger(subsystem: "com.latencyzero.GroundStation", category: "GroundStationDocument")
}



struct
StationConfig : Codable
{
	var	port			:	String
	var	speed			:	Int
}

struct
Vehicle : Identifiable
{
	var	id				=	UUID()
	
	var	name			:	String
	var	longitude		:	Double
	var	latitude		:	Double
	var altitude		:	Double
}
