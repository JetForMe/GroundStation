//
//  ContentView.swift
//  GroundStation
//
//  Created by Rick Mann on 2023-11-28.
//

import SwiftUI




struct
ContentView: View
{
	@Binding var document: GroundStationDocument

	var
	body: some View
	{
		VStack(alignment: .leading)
		{
			MapView(vehicles: self.document.vehicles)
			
			//	Port Parameters…
			
			HStack(alignment: .firstTextBaseline)
			{
				Text("Port:")
					.fontWeight(.bold)
				Text("\(self.document.config.port), \(self.document.config.speed as NSNumber, formatter: Self.portSpeedFormatter) 8N1")
				
				Spacer()
			}
		}
		.padding()
	}
	
	
	@Environment(GlobalState.self)	private	var	globalState
	
	static let portSpeedFormatter =
	{
		let nf = NumberFormatter()
		nf.usesGroupingSeparator = false
		return nf
	}()
}

#Preview
{
	ContentView(document: .constant(GroundStationDocument()))
		.frame(width: 600, height: 400)
		.environment(GlobalState())
}
