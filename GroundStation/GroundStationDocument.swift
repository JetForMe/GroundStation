//
//  GroundStationDocument.swift
//  GroundStation
//
//  Created by Rick Mann on 2023-11-28.
//

import SwiftUI
import UniformTypeIdentifiers

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

struct
GroundStationDocument : FileDocument
{
	var config					:	StationConfig
	var vehicles										=	[Vehicle]()
	
	init()
	{
		//	Hard-code some values for now…
		
		self.config = StationConfig(port: "/dev/tty.usbserial-FTF0GIP9", speed: 57600)
		self.vehicles.append(Vehicle(name: "Hard-coded Vehicle", longitude: -117.92382740743369, latitude: 33.874089406391725, altitude: 100))
	}

	static var readableContentTypes: [UTType]				{ [.gsConfig] }
	
	
	
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
