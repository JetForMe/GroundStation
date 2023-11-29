//
//  MapView.swift
//  GroundStation
//
//  Created by Rick Mann on 2023-11-28.
//

import MapKit
import SwiftUI





struct
MapView : View
{
	let	vehicles			:	[Vehicle]
	
	var
	body: some View
	{
		ZStack
		{
			Map(position: self.$mapPosition)
			{
				ForEach(self.vehicles)
				{ inVehicle in
					Marker("\(inVehicle.name)", coordinate: CLLocationCoordinate2D(latitude: inVehicle.latitude, longitude: inVehicle.longitude))
				}
			}
			.mapStyle(.standard(elevation: .realistic))
			
			//	Location tracking picker…
			
			VStack(alignment: .trailing)
			{
				
				Spacer()
			}
		}
		.onChange(of: self.trackingMode)
		{
			switch (self.trackingMode)
			{
				case .automatic:
					self.mapPosition = .automatic
					
				case .userLocation:
					self.mapPosition = .userLocation(fallback: .automatic)
				
				case .userLocationTrackUp:
					self.mapPosition = .userLocation(followsHeading: true, fallback: .automatic)
				
				default:
					self.mapPosition = .automatic
			}
		}
		.onChange(of: self.mapPosition.followsUserLocation)
		{
			if !self.mapPosition.followsUserLocation
			{
				self.trackingMode = .userSpecified
			}
		}
		.toolbar
		{
			ToolbarItemGroup
			{
				//	Automatic tracking (all objects)…
				
				if self.trackingMode == .automatic
				{
					Button(action: { self.trackingMode = .userSpecified })
					{
						Image(systemName: "circlebadge.2.fill")
					}
				}
				else
				{
					Button(action: { self.trackingMode = .automatic })
					{
						Image(systemName: "circlebadge.2")
					}
				}
				
				//	User-centric…
				
				if self.trackingMode == .userLocation
				{
					Button(action: { self.trackingMode = .userLocationTrackUp })
					{
						Image(systemName: "location.fill")
					}
				}
				else if self.trackingMode == .userLocationTrackUp
				{
					Button(action: { self.trackingMode = .userLocation })
					{
						Image(systemName: "location.north.line.fill")
					}
				}
				else
				{
					Button(action: { self.trackingMode = .userLocation })
					{
						Image(systemName: "location")
					}
				}
				
				//	Vehicle…
				
				if case .vehicle(let vehicleID) = self.trackingMode
				{
					Button(action: { self.trackingMode = .userSpecified })
					{
						Image(systemName: "balloon.fill")
					}
				}
				else
				{
					Button(action: { self.trackingMode = .vehicle(nil) })
					{
						Image(systemName: "balloon")
					}
				}
			}
		}
	}
	
	@State	private	var	trackingMode			:	LocationTrackingMode	=	.automatic
	@State	private	var	mapPosition											=	MapCameraPosition.automatic
}

enum
LocationTrackingMode : Hashable
{
	case automatic
	case userSpecified
	case userLocation
	case userLocationTrackUp
	case vehicle(UUID?)
}

#Preview
{
	MapView(vehicles: [Vehicle(name: "Hard-coded Vehicle", longitude: -117.92382740743369, latitude: 33.874089406391725, altitude: 100)])
}
