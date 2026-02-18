@isTest
private class SmartCarServiceTest {
    
    @isTest
    static void testGetAllVehiclesSuccess() {
        Test.setMock(HttpCalloutMock.class, new SmartCarCalloutMock());
        
        Test.startTest();
        List<SmartCarVehicleWrapper> result = SmartCarService.getAllVehicles();
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Must be one vehicle in the response');
        System.assertEquals('car-123', result[0].id);
        System.assertEquals('Tesla', result[0].make);
    }

    @isTest
    static void testGetFullVehicleDetailsSuccess() {
        Test.setMock(HttpCalloutMock.class, new SmartCarCalloutMock());
        
        Test.startTest();
        SmartCarVehicleWrapper details = SmartCarService.getFullVehicleDetails('car-123');
        Test.stopTest();
        
        System.assertEquals(55043.0, details.distance, 'Distance should match the mock response');
        System.assertEquals(37.41, details.latitude, 'Latitude should match the mock response');
        System.assertEquals(-122.09, details.longitude, 'Longitude should match the mock response');
    }

    
}