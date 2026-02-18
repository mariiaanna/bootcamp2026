public class SmartCarVehicleWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String make { get; set; }
    @AuraEnabled public String model { get; set; }
    @AuraEnabled public Integer year { get; set; }
    @AuraEnabled public Double distance { get; set; }
    @AuraEnabled public Double latitude {get;set;}
    @AuraEnabled public Double longitude {get;set;}
    public SmartCarVehicleWrapper() {}
    public static SmartCarVehicleWrapper parse(String json) {
        return (SmartCarVehicleWrapper) System.JSON.deserialize(json, SmartCarVehicleWrapper.class);
    }
}