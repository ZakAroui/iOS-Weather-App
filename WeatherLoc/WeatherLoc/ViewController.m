//
//  ViewController.m
//  WeatherLoc
//
//  Created by Zack Aroui on 6/3/17.
//  Copyright © 2017 Zack Aroui. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

#import <MapKit/MapKit.h>

#import "WLApiManager.h"
#import "WLWebConfig.h"



@interface ViewController ()<MKMapViewDelegate>{
    CLLocationManager *locationManager;
    NSMutableArray *weatherDataArray;
    int entriesCount;
    
    NSString *mTemperature;
    NSString *mHumidity;
    NSString *mWeatherDesc;
    NSString *mLatitude;
    NSString *mLongitude;
    NSString *mNeighborhood;
}



@property (weak, nonatomic) IBOutlet MKMapView *weatherMapView;
@property (weak, nonatomic) IBOutlet UITableView *recentWeatherTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.weatherMapView.delegate = self;
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) || ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    [self.weatherMapView setShowsPointsOfInterest:NO];
    [self.weatherMapView setShowsUserLocation:YES];
    [self centerUserLocation];
    
    // Fetch the data from persistent data store
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PlaceEntity"];
    weatherDataArray = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    [self.recentWeatherTableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
   
    [locationManager stopUpdatingLocation];
}

#pragma mark - map

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
   
    [self centerUserLocation];
    [self.recentWeatherTableView reloadData];

    [self fetchWeatherFromWeb];
    
    // Fetch the data from persistent data store
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PlaceEntity"];
    weatherDataArray = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    entriesCount = (int)weatherDataArray.count;
    
    [self.recentWeatherTableView reloadData];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
   
    if (self.weatherMapView.userLocation == annotation){
        MKAnnotationView *annotationView = [mapView viewForAnnotation:self.weatherMapView.userLocation];
        annotationView.canShowCallout = YES;
        
        self.weatherMapView.userLocation.title = mNeighborhood;
        self.weatherMapView.userLocation.subtitle = mTemperature;
    }
    return nil;
}

- (void)centerUserLocation {
    
    MKCoordinateRegion region;
    region.center.latitude  = [_weatherMapView userLocation].location.coordinate.latitude;
    region.center.longitude = [_weatherMapView userLocation].location.coordinate.longitude;
    region.span.latitudeDelta  = 0.08;
    region.span.longitudeDelta = 0.08;
    
    region = [_weatherMapView regionThatFits:region];
    [_weatherMapView setRegion:region animated:YES];
}

#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dayCellReuse" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dayCellReuse"];
    }
    
    if (entriesCount >= 1 && indexPath.row < entriesCount) {
        
        NSManagedObject *dayWeather = [weatherDataArray objectAtIndex:(entriesCount - 1 - indexPath.row)];
        
        [cell.textLabel setText:[NSString stringWithFormat:@"%@ - %@ Degrees", [dayWeather valueForKey:@"locationName"], [dayWeather valueForKey:@"temperature"]]];
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ - %@", [dayWeather valueForKey:@"weatherDescription"], [dayWeather valueForKey:@"humidity"]]];
    }
    
    return cell;
}

#pragma mark - core data stack
- (NSManagedObjectContext *)managedObjectContext {
    
    NSManagedObjectContext *context = nil;
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(persistentContainer)]) {
        context = [delegate persistentContainer].viewContext;
    }
    return context;
}

- (void)saveWeatherDescitpion: (NSString *)weatherDescrp andTemperature:(NSString *)tempr andHumidity:(NSString *)humid andLatitude: (NSString *)Lat andLongitude:(NSString *)longi andLocationName:(NSString *)locName {
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *updatedWeather = [NSEntityDescription insertNewObjectForEntityForName:@"PlaceEntity" inManagedObjectContext:context];
    
    [updatedWeather setValue:weatherDescrp    forKey:@"weatherDescription"];
    [updatedWeather setValue:tempr forKey:@"temperature"];
    [updatedWeather setValue:humid forKey:@"humidity"];
    
    [updatedWeather setValue:longi  forKey:@"locationLongitude"];
    [updatedWeather setValue:Lat forKey:@"locationLatitude"];
    [updatedWeather setValue:locName forKey:@"locationName"];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save weather data! %@ %@", error, [error localizedDescription]);
    }
}

#pragma mark - weather and Location apis
- (void)fetchWeatherFromWeb {
  
    WLApiManager *manager = [[WLApiManager alloc] init];
    
    //get weather data
    NSString* cordParams = [NSString stringWithFormat:@"lat=%@&lon=%@&", [[NSString alloc] initWithFormat:@"%f", locationManager.location.coordinate.latitude], [[NSString alloc] initWithFormat:@"%f", locationManager.location.coordinate.longitude]];

    [manager getApiCallToEndpoint:[NSString stringWithFormat:@"%@%@%@", WEATHER_BASE_URL, cordParams, WEATHER_API_KEY] withParams:nil onCompletion:^(id data, BOOL success) {
        if (success) {
            
            mTemperature = [[[data objectForKey:@"main"] objectForKey:@"temp"] stringValue];
            mHumidity = [[[data objectForKey:@"main"] objectForKey:@"humidity"] stringValue];
            mWeatherDesc = [[data objectForKey:@"weather"][0] objectForKey:@"description"];
        }
        else{
            NSLog(@"error in fetching the weather data!");
        }
    }];
    
    //get location data
    cordParams = [NSString stringWithFormat:@"latlng=%@,%@", [[NSString alloc] initWithFormat:@"%f", locationManager.location.coordinate.latitude], [[NSString alloc] initWithFormat:@"%f", locationManager.location.coordinate.longitude]];
    
    [manager getApiCallToEndpoint:[NSString stringWithFormat:@"%@%@", GEO_BASE_URL, cordParams] withParams:nil onCompletion:^(id data, BOOL success) {
        if (success) {
            
            mLatitude = [[NSString alloc] initWithFormat:@"%f", locationManager.location.coordinate.latitude];
            mLongitude = [[NSString alloc] initWithFormat:@"%f", locationManager.location.coordinate.longitude];
            id addresses = [[data objectForKey:@"results"][0] objectForKey:@"address_components"];
            
            for (id address in addresses) {
                if ([[address objectForKey:@"types"][0] isEqualToString:@"neighborhood"]) {
                    mNeighborhood = [address objectForKey:@"long_name"];
                    break;
                }
            }
            [self saveWeatherDescitpion:mWeatherDesc andTemperature:mTemperature andHumidity:mHumidity andLatitude:mLatitude andLongitude:mLongitude andLocationName:mNeighborhood];
            
            [self.recentWeatherTableView reloadData];
        }
        else{
            NSLog(@"error in fetching the weather data!");
        }
    }];
}

@end
