public class OpportunityProductHandler extends TriggerHandler {
    public override void beforeInsert() {
        Set<Id> carIds = new Set<Id>();
        for (OpportunityLineItem oli : (List<OpportunityLineItem>)Trigger.new) {
            carIds.add(oli.Product2Id);
        }

        Map<Id, Product2> cars = new Map<Id, Product2>([
            SELECT Id, Car_Status__c, Reserved_for_Opportunity__c
            FROM Product2 WHERE Id IN :carIds
            WITH USER_MODE
        ]);
        for (OpportunityLineItem oli : (List<OpportunityLineItem>) Trigger.new) {
            oli.Quantity = 1;

            Product2 car = cars.get(oli.Product2Id);
            if (car == null) continue;

            if (car.Car_Status__c == 'Sold' &&
                car.Reserved_for_Opportunity__c != oli.OpportunityId) {
                oli.addError('Sold car cannot be added to another Opportunity');
            }

        }
    }
    public override void beforeUpdate() {
        for (OpportunityLineItem oli : (List<OpportunityLineItem>) Trigger.new) {
           OpportunityLineItem oldOli = (OpportunityLineItem) Trigger.oldMap.get(oli.Id);
            if (oli.Quantity != oldOli.Quantity) {
                oli.addError('Quantity must be equal to 1.');
            }
        }
    }
}