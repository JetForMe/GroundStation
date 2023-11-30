//
//  Serial.swift
//  GroundStation
//
//  Created by Rick Mann on 2023-11-29.
//

import os

import Foundation












class
LZSerialPort
{
	enum
	Errors : Error
	{
		case posixError(errno_t)
	}
	
	typealias	ReceiveCallbackClosure		=	(Bool, Data?, Errors?) -> ()
	
	init(path: String, speed: BaudRate = .baud115200)
	{
		self.path = path
		self.speed = speed
		self.channelQueue = DispatchQueue(label: "Channel queue \(self.path)", qos: .background)
	}
	
	deinit
	{
		closePort()
	}
	
	/**
		- Parameters:
			- inQueue: The ``DispatchQueue`` on which to call the receive closure, or `nil` to call it on the main queue.
			- inCallback: The closure to call when data is received.
	*/
	
	func
	setReceiveCallback(queue inQueue: DispatchQueue? = nil, callback inCallback: @escaping ReceiveCallbackClosure)
	{
		self.recieveCallbackQueue = inQueue ?? DispatchQueue.main
		self.receiveCallback = inCallback
	}
	
	func
	openPort()
		throws
	{
		let fd = open(self.path, O_RDWR | O_NOCTTY | O_EXLOCK | O_NONBLOCK)
		guard
			fd > 0		//	-1 is error, what’s 0?
		else
		{
			throw Errors.posixError(errno)
		}
		
		self.fd = fd
		
		//	Configure the port…
		
		var settings = termios()
		tcgetattr(fd, &settings)
		cfmakeraw(&settings)
		
		//	Speed…
		
		cfsetispeed(&settings, self.speed.speedValue)
		cfsetospeed(&settings, self.speed.speedValue)
		
		//	8N1 for now…
		
		settings.c_cflag &= ~tcflag_t(CSIZE)
        settings.c_cflag |= tcflag_t(CS8)
		settings.c_cflag |= 0				//	no parity
		settings.c_cflag &= ~tcflag_t(CSTOPB)
		
		//	Disable input mapping of CR to NL, mapping of NL into CR, and ignoring CR…
		
		settings.c_iflag &= ~tcflag_t(ICRNL | INLCR | IGNCR)
		
		//	No flow control…
		
		settings.c_cflag &= ~tcflag_t(CRTS_IFLOW)
		settings.c_cflag &= ~tcflag_t(CCTS_OFLOW)
		settings.c_iflag &= ~tcflag_t(IXON | IXOFF | IXANY)

		//	Turn on the receiver of the serial port, and ignore modem control lines…

		settings.c_cflag |= tcflag_t(CREAD | CLOCAL)

		//	Turn off canonical mode…

		settings.c_lflag &= ~tcflag_t(ICANON | ECHO | ECHOE | ISIG)
		
		//	Don’t process output…
		
		settings.c_oflag &= ~tcflag_t(OPOST)
		
		//	Special characters
		//	We do this as c_cc is a C-fixed array which is imported as a tuple in Swift.
		//	To avoid hardcoding the VMIN or VTIME value to access the tuple value, we use the typealias instead
#if os(Linux)
		typealias specialCharactersTuple = (VINTR: cc_t, VQUIT: cc_t, VERASE: cc_t, VKILL: cc_t, VEOF: cc_t, VTIME: cc_t, VMIN: cc_t, VSWTC: cc_t, VSTART: cc_t, VSTOP: cc_t, VSUSP: cc_t, VEOL: cc_t, VREPRINT: cc_t, VDISCARD: cc_t, VWERASE: cc_t, VLNEXT: cc_t, VEOL2: cc_t, spare1: cc_t, spare2: cc_t, spare3: cc_t, spare4: cc_t, spare5: cc_t, spare6: cc_t, spare7: cc_t, spare8: cc_t, spare9: cc_t, spare10: cc_t, spare11: cc_t, spare12: cc_t, spare13: cc_t, spare14: cc_t, spare15: cc_t)
		var specialCharacters: specialCharactersTuple = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) // NCCS = 32
#elseif os(OSX)
		typealias specialCharactersTuple = (VEOF: cc_t, VEOL: cc_t, VEOL2: cc_t, VERASE: cc_t, VWERASE: cc_t, VKILL: cc_t, VREPRINT: cc_t, spare1: cc_t, VINTR: cc_t, VQUIT: cc_t, VSUSP: cc_t, VDSUSP: cc_t, VSTART: cc_t, VSTOP: cc_t, VLNEXT: cc_t, VDISCARD: cc_t, VMIN: cc_t, VTIME: cc_t, VSTATUS: cc_t, spare: cc_t)
		var specialCharacters: specialCharactersTuple = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) // NCCS = 20
#endif

        specialCharacters.VMIN = cc_t(0)
        specialCharacters.VTIME = cc_t(5 * 10)
        settings.c_cc = specialCharacters
        
        //	Write the port configuration…
		
		tcsetattr(fd, TCSANOW, &settings)
		
		//	Try to make the FD blocking…
		
		var flags = fcntl(fd, F_GETFL)
		flags &= ~O_NONBLOCK
		let result = fcntl(fd, F_SETFL, flags)
		Self.logger.info("Result of fcntl: \(result)")
		
		//	Create the dispatch channel…
		
		self.channel = DispatchIO(type: .stream, fileDescriptor: fd, queue: self.channelQueue)
									{ inVal in
										Self.logger.error("Cleanup called")
									}
	}
	
	func
	closePort()
	{
		if let fd = self.fd
		{
			close(fd)
			self.fd = nil
		}
	}
	
	func
	doARead()
	{
		if self.queue == nil
		{
			self.queue = DispatchQueue(label: "Port Queue \(self.path)", qos: .background)
		}
		
		self.channelQueue.async
		{
			Self.logger.info("Starting read")
			
			self.channel?.read(offset: 0,
								length: 1024,
								queue: self.recieveCallbackQueue!,
								ioHandler:
								{ done, dd, error in
									if error != 0
									{
										Self.logger.info("Receive called with error \(error)")
										self.receiveCallback?(done, nil, .posixError(error))
										return
									}
									
									if let dd = dd
									{
										let data = Data(dd)
										Self.logger.info("Received data, done: \(done), \(data.count) bytes")
										self.receiveCallback?(done, data, nil)
										return
									}
									else
									{
										Self.logger.info("Receive called, no data, done: \(done)")
										self.receiveCallback?(done, nil, nil)
										return
									}
								})
			
			Self.logger.info("read() returned")
		}
	}
	
	func
	write(data inData: Data)
	{
		self.channelQueue.async
		{
			let dd = DispatchData(data: inData)
			self.channel?.write(offset: 0, data: dd, queue: self.channelQueue) { done, data, error in
				print("data written: \(done)")
			}
		}
	}
	
	
	private	var	path					:	String
	private	var speed					:	BaudRate
	private	var	fd						:	Int32?
	private	var	queue					:	DispatchQueue?
	private	var	channel					:	DispatchIO?
	private	var	channelQueue			:	DispatchQueue
	private	var	recieveCallbackQueue	:	DispatchQueue?
	private	var	receiveCallback			:	ReceiveCallbackClosure?

	static	private	let	logger							=	Logger(subsystem: "com.latencyzero.Serial", category: "LZSerialPort")
}

extension
DispatchData
{
	init(data inData: Data)
	{
		self = inData.withUnsafeBytes({ inBytes in
			DispatchData(bytes: inBytes)
		})
	}
}

#if os(Linux)
public enum BaudRate {
    case baud0
    case baud50
    case baud75
    case baud110
    case baud134
    case baud150
    case baud200
    case baud300
    case baud600
    case baud1200
    case baud1800
    case baud2400
    case baud4800
    case baud9600
    case baud19200
    case baud38400
    case baud57600
    case baud115200
    case baud230400
    case baud460800
    case baud500000
    case baud576000
    case baud921600
    case baud1000000
    case baud1152000
    case baud1500000
    case baud2000000
    case baud2500000
    case baud3500000
    case baud4000000

    var speedValue: speed_t {
        switch self {
        case .baud0:
            return speed_t(B0)
        case .baud50:
            return speed_t(B50)
        case .baud75:
            return speed_t(B75)
        case .baud110:
            return speed_t(B110)
        case .baud134:
            return speed_t(B134)
        case .baud150:
            return speed_t(B150)
        case .baud200:
            return speed_t(B200)
        case .baud300:
            return speed_t(B300)
        case .baud600:
            return speed_t(B600)
        case .baud1200:
            return speed_t(B1200)
        case .baud1800:
            return speed_t(B1800)
        case .baud2400:
            return speed_t(B2400)
        case .baud4800:
            return speed_t(B4800)
        case .baud9600:
            return speed_t(B9600)
        case .baud19200:
            return speed_t(B19200)
        case .baud38400:
            return speed_t(B38400)
        case .baud57600:
            return speed_t(B57600)
        case .baud115200:
            return speed_t(B115200)
        case .baud230400:
            return speed_t(B230400)
        case .baud460800:
            return speed_t(B460800)
        case .baud500000:
            return speed_t(B500000)
        case .baud576000:
            return speed_t(B576000)
        case .baud921600:
            return speed_t(B921600)
        case .baud1000000:
            return speed_t(B1000000)
        case .baud1152000:
            return speed_t(B1152000)
        case .baud1500000:
            return speed_t(B1500000)
        case .baud2000000:
            return speed_t(B2000000)
        case .baud2500000:
            return speed_t(B2500000)
        case .baud3500000:
            return speed_t(B3500000)
        case .baud4000000:
            return speed_t(B4000000)
        }
    }
}
#elseif os(OSX)
public enum BaudRate {
    case baud0
    case baud50
    case baud75
    case baud110
    case baud134
    case baud150
    case baud200
    case baud300
    case baud600
    case baud1200
    case baud1800
    case baud2400
    case baud4800
    case baud9600
    case baud19200
    case baud38400
    case baud57600
    case baud115200
    case baud230400

    var speedValue: speed_t {
        switch self {
        case .baud0:
            return speed_t(B0)
        case .baud50:
            return speed_t(B50)
        case .baud75:
            return speed_t(B75)
        case .baud110:
            return speed_t(B110)
        case .baud134:
            return speed_t(B134)
        case .baud150:
            return speed_t(B150)
        case .baud200:
            return speed_t(B200)
        case .baud300:
            return speed_t(B300)
        case .baud600:
            return speed_t(B600)
        case .baud1200:
            return speed_t(B1200)
        case .baud1800:
            return speed_t(B1800)
        case .baud2400:
            return speed_t(B2400)
        case .baud4800:
            return speed_t(B4800)
        case .baud9600:
            return speed_t(B9600)
        case .baud19200:
            return speed_t(B19200)
        case .baud38400:
            return speed_t(B38400)
        case .baud57600:
            return speed_t(B57600)
        case .baud115200:
            return speed_t(B115200)
        case .baud230400:
            return speed_t(B230400)
        }
    }
}
#endif
