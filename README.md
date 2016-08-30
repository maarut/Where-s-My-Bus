Where's My Bus
==============

Where's My Bus is a simple app that tells you when a bus will arrive at your favourite bus stops in London. This is most useful when rushing out the door to work in the morning, or heading home from work in the evening - the app will quickly tell you when your bus will be arriving, so you can determine how much you need to rush!

## Requirements

- Xcode 7.3
- Swift 2.2
- Deployment on iOS 9 or later

## How To Build

You will need to register with the [TFL](https://api-portal.tfl.gov.uk/signup) for an app key and secret. Make a copy of the Keys.example.config file, and rename it to Keys.config. Edit the file and insert your details for each property. You should now be able to perform a clean build of the source.

## How To Use

On opening the app, a list of your favourite bus stops is displayed, along with when the next bus for each route for that stop will arrive. Tapping a stop will send you to the details screen that will list all of the busses that are scheduled to arrive at that stop. Tapping the “Add” button will bring you to the search screen where you can look around your current location to add new favourite stops. From the search screen, you can tap the info button to be sent to the details screen. If the stop is a favourite, you can edit the details of a particular stop to show or hide specific routes on the favourites screen.

## Known Issues

There is currently an intermittent bug when displaying information on the favourites screen. Sometimes the auto layout engine will fail to correctly lay out a table view cell. This error is mostly harmless because the app appears to continue to display data as intended. I believe the error is because the auto layout engine is adding constraints based on the XIB that conflict with the actual constraints for the cell at runtime. (The tableView has rowHeight property set to NSAutomaticDimension).