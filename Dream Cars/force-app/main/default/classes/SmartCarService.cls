public with sharing class SmartCarService {
    
    @AuraEnabled
    public static List<SmartCarVehicleWrapper> getAllVehicles() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SmartCar_API/v2.0/vehicles'); 
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        List<SmartCarVehicleWrapper> vehicleList = new List<SmartCarVehicleWrapper>();

        if (res.getStatusCode() == 200) {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> v1 = (Map<String, Object>) root.get('v1');
            
            if (v1 != null) {
                for (String vinKey : v1.keySet()) {
                    String jsonStr = JSON.serialize(v1.get(vinKey));
                    vehicleList.add(SmartCarVehicleWrapper.parse(jsonStr));
                }
            }
            return vehicleList;
        } else {
            throw new AuraHandledException('Error fetching vehicles: ' + res.getStatus());
        }
    }

    @AuraEnabled
    public static SmartCarVehicleWrapper getFullVehicleDetails(String vehicleId) {
        SmartCarVehicleWrapper details = new SmartCarVehicleWrapper();
        details.id = vehicleId;

        SmartCarVehicleWrapper odoData = fetchValue(vehicleId, '/odometer');
        details.distance = odoData.distance;
        
        SmartCarVehicleWrapper locData = fetchValue(vehicleId, '/location');
        details.latitude = locData.latitude;
        details.longitude = locData.longitude;
        
        return details;
    }

    private static SmartCarVehicleWrapper fetchValue(String vehicleId, String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SmartCar_API/v2.0/vehicles/' + vehicleId + path);
        req.setMethod('GET');
        
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            return SmartCarVehicleWrapper.parse(res.getBody());
        }
        return new SmartCarVehicleWrapper();
    }
}