Where's My Bus
==============

Where's My Bus is a simple app that tells you when a bus will arrive at your favourite bus stops in London. This is most useful when rushing out the door to work in the morning, or heading home from work in the evening - the app will quickly tell you when your bus will be arriving, so you can determine how much you need to rush!

## Requirements

- Xcode 7.3
- Swift 2.2
- Deployment on iOS 9 or later

## How To Build

You will need to register with the [TFL](https://api-portal.tfl.gov.uk/signup) for an app ID and key. Make a copy of the Keys.example.xcconfig file, and rename it to Keys.xcconfig. Edit the file and insert your details for each property. You should now be able to perform a clean build of the source.

## How To Use

The app consists of three screens: -

- Favourites
- Search
- Details

The app always opens up on the favourites screen.

### Favourites

The favourites screen is a list of favourite bus stops. For each favourite stop, the ETA for the next bus for each route is listed. You can swipe to delete a stop from the favourites list. In addition, tapping and holding any favourite, allows the user to reorder the list of favourites.

If there are favourites listed, there is a progress bar at the top of the view that shows when the ETA for each route will be refreshed. Alternatively, the user can start the refresh action themselves by using the ‘pull to refresh’ gesture.

An ‘Add’ button is available in the upper right corner of the screen to allow the user to move to the search screen. Tapping a favourite will move the user to the details screen.

### Search

The search screen is a map that shows bus stops in the area the user has panned and zoomed the map to.

On transitioning to the search screen, the app will zoom in to the users current location, if location services are enabled. The user is also able to manually pan and zoom to an area of their choice. If the zoom level is sufficient, a list of bus stops nearby will be displayed, otherwise an info panel will request that the user zoom in further to see bus stops.

If location services are enabled, then the user will be presented with a ‘locate me’ button in the lower left corner of the screen. Tapping this button will automatically pan the map to the users current location.

Pins show the location of each bus stop in the area. Tapping a pin will show up a detail view. The detail view consists of a ‘star’ either filled if the stop is a favourite or unfilled if not on the left, the bus stop letter, name, and a list of routes that stop at that bus stop in the centre, and an ‘info’ button on the right. Tapping the star toggles the favourite status of the stop. Tapping the info button, or the central text will transition the app to the details screen.

### Details

The details screen shows all of the busses that are scheduled to stop at the bus stop. The route, ETA, destination, and number plate of the is shown to the user for each scheduled arrival.

There are two sort options available; by route, and by ETA. The former divides the scheduled arrivals up by their route, then lists each bus by ETA, where as the latter sort order lists all busses by the time that they will arrive. The sort order can be changed by tapping the ‘sort order’ button in the lower left part of the screen.

There is a star button in the lower right corner of the screen. A filled star means that the stop is a favourite. If unfilled the stop is not a favourite. Tapping the star will toggle the favourite status. When the stop is a favourite, an ‘Edit’ button will appear in the upper right corner of the screen. Tapping the edit button will bring up a new screen that will allow the user to select routes of interest to show on the favourites screen. The details screen will always show all scheduled busses.

As with the favourites screen, there is a progress bar at the top of the screen that shows the user when the data will be refreshed. The user can also initiate a refresh by using the ‘pull to refresh’ gesture.

## Known Issues

There is currently an intermittent bug when displaying information on the favourites screen. Sometimes the auto layout engine will fail to correctly lay out a table view cell. This error is mostly harmless because the app appears to continue to display data as intended. I believe the error is because the auto layout engine is adding constraints based on the XIB that conflict with the actual constraints for the cell at runtime. (The tableView has rowHeight property set to NSAutomaticDimension).