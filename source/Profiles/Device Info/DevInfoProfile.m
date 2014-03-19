//
//  BLEDevice.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 8/16/13.
//  Copyright (c) 2013 Punch Through Design. All rights reserved.
//

#import "DevInfoProfile.h"


@implementation DevInfoProfile
{
    CBPeripheral* peripheral;
    CBService* service_deviceInformation;
    CBCharacteristic* characteristic_hardware_version;
    CBCharacteristic* characteristic_firmware_version;
    CBCharacteristic* characteristic_software_version;
}

#pragma mark Public Methods

-(id)initWithPeripheral:(CBPeripheral*)aPeripheral delegate:(id<ProfileDelegate_Protocol>)delegate
{
    self = [super init];
    if (self) {
        //Init Code
        peripheral = aPeripheral;
        _delegate = delegate;
    }
    return self;
}
-(void)validate
{
    // Discover services
    NSLog(@"Searching for Device Information service: %@", SERVICE_DEVICE_INFORMATION);
    if(peripheral.state == CBPeripheralStateConnected)
    {
        [peripheral discoverServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:SERVICE_DEVICE_INFORMATION]
                                      , nil]];
    }
}
-(BOOL)isValid:(NSError**)error
{
    return (service_deviceInformation &&
            characteristic_hardware_version &&
            characteristic_firmware_version &&
            characteristic_software_version)?TRUE:FALSE;
}

#pragma mark Private Functions
-(void)__notifyValidity
{
    if (self.delegate)
    {
        if([self.delegate respondsToSelector:@selector(profileValidated:)])
        {
            [self.delegate profileValidated:self];
        }
    }
}

#pragma mark CBPeripheralDelegate callbacks
-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        if(!(service_deviceInformation))
        {
            if(peripheral.services)
            {
                for (CBService * service in peripheral.services) {
                    if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_DEVICE_INFORMATION]]) {
                        NSLog(@"%@: Device Information profile  found", self.class.description);
                        
                        // Save oad service
                        service_deviceInformation = service;
                        
                        // Discover characteristics
                        NSArray * characteristics = [NSArray arrayWithObjects:
                                                     [CBUUID UUIDWithString:CHARACTERISTIC_HARDWARE_VERSION],
                                                     [CBUUID UUIDWithString:CHARACTERISTIC_FIRMWARE_VERSION],
                                                     [CBUUID UUIDWithString:CHARACTERISTIC_SOFTWARE_VERSION],
                                                     nil];
                        
                        
                        // Find characteristics of service
                        [peripheral discoverCharacteristics:characteristics forService:service];
                    }
                }
            }
        }
    }else {
        NSLog(@"%@: Service discovery was unsuccessful", self.class.description);
    }
}

-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if(!(characteristic_hardware_version &&
             characteristic_firmware_version &&
             characteristic_software_version))
        {
            if ([service isEqual:service_deviceInformation]) {
                NSLog(@"%@: Device Information Characteristics of peripheral found", self.class.description);
                for (CBCharacteristic * characteristic in service.characteristics) {
                    
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_HARDWARE_VERSION]]) {
                        characteristic_hardware_version = characteristic;
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_FIRMWARE_VERSION]]) {
                        characteristic_firmware_version = characteristic;
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_SOFTWARE_VERSION]]) {
                        characteristic_software_version = characteristic;
                    }
                }
                
                NSError* verificationerror;
                if ((
                     characteristic_hardware_version &&
                     characteristic_firmware_version &&
                     characteristic_software_version
                     )){
                    NSLog(@"%@: Found all Device Information characteristics", self.class.description);
                    
                    [self __notifyValidity];
                    
                }else {
                    // Could not find all characteristics!
                    NSLog(@"%@: Could not find all Device Information characteristics!", self.class.description);
                    
                    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                    [errorDetail setValue:@"Could not find all Device Information characteristics" forKey:NSLocalizedDescriptionKey];
                    verificationerror = [NSError errorWithDomain:@"Bluetooth" code:100 userInfo:errorDetail];
                }
                
                //Alert Delegate
            }
        }
    }
    else {
        NSLog(@"%@: Characteristics discovery was unsuccessful", self.class.description);
        
    }
}


@end