import OpenTok

final class OpenTokManager: NSObject, ObservableObject {
    // Replace with your OpenTok API key
    private let kApiKey = "47196354"
    // Replace with your generated session ID
    private let kSessionId = "2_MX40NzE5NjM1NH5-MTYyMDczOTI3MjE5MX4rakxXNHNBSENVc1o1SVpFcEl1Q05mN1V-fg"
    // Replace with your generated token
    private let kToken = "T1==cGFydG5lcl9pZD00NzE5NjM1NCZzaWc9ZGZmZmMzZmJlZTBkYzE5ZDAwMjQ3ZDdiYmRjZTQ0YTFmMjNjZTU5YzpzZXNzaW9uX2lkPTJfTVg0ME56RTVOak0xTkg1LU1UWXlNRGN6T1RJM01qRTVNWDRyYWt4WE5ITkJTRU5WYzFvMVNWcEZjRWwxUTA1bU4xVi1mZyZjcmVhdGVfdGltZT0xNjIwNzM5NDE2Jm5vbmNlPTAuNzc0NDc0NjM4MjAwMjg0NyZyb2xlPXB1Ymxpc2hlciZleHBpcmVfdGltZT0xNjIwODI1ODE2JmluaXRpYWxfbGF5b3V0X2NsYXNzX2xpc3Q9"
    
    private lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()
    
    private lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    private var subscriber: OTSubscriber?
    
    @Published var pubview: UIView?
    @Published var subview: UIView?
    @Published var error: OTErrorWrapper?
    
    public func setup() {
        doConnect()
    }
    
    private func doConnect() {
        var error: OTError?
        defer {
            processError(error)
        }
        session.connect(withToken: kToken, error: &error)
    }
    
    private func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.publish(publisher, error: &error)
        
        if let view = publisher.view {
            DispatchQueue.main.async {
                self.pubview = view
            }
        }
    }
    
    private func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        session.subscribe(subscriber!, error: &error)
    }
    
    private func cleanupSubscriber() {
        DispatchQueue.main.async {
            self.subview = nil
        }
    }
    
    private func cleanupPublisher() {
        DispatchQueue.main.async {
            self.pubview = nil
        }
    }
    
    private func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                self.error = OTErrorWrapper(error: err.localizedDescription)
            }
        }
    }
}

extension OpenTokManager: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        doSubscribe(stream)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
}

extension OpenTokManager: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

extension OpenTokManager: OTSubscriberDelegate {
    
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let view = subscriber?.view {
            DispatchQueue.main.async {
                self.subview = view
            }
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}