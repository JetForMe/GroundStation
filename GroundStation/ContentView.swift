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
		.toolbar
		{
			Button(action: { try? self.document.toggleConnection() })	//	TODO: Report errors
			{
				if self.document.connected
				{
					Image(systemName: "arrow.up.right.and.arrow.down.left")
				}
				else
				{
					Image(systemName: "arrow.down.left.and.arrow.up.right")
				}
			}
			
			if self.document.noTelemetryReceived
			{
				Image(systemName: "exclamationmark.triangle.fill")
					.foregroundColor(.yellow)
			}
			else
			{
				Image(systemName: "checkmark.circle.fill")
					.foregroundColor(.green)
			}
		}
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
