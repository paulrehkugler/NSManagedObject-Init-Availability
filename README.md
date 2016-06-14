### NSManagedObject Init Availability

Looks like `NSManagedObject(context:)` has incorrect `@available` markers. This code worked properly on iOS 9, but it's cordoned off to iOS 10+ in the iOS 10 beta 1 SDK.
