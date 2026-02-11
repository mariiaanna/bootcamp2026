public class CarStatusService {

    public static Map<Id, String> mapStageToCarStatus(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Map<Id, String> result = new Map<Id, String>();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (oldOpp == null || opp.StageName == oldOpp.StageName) continue;

            if (opp.StageName == 'Contract Sent') {
                result.put(opp.Id, 'Reserved');

            } else if (opp.StageName == 'Closed Won') {
                result.put(opp.Id, 'Sold');

            } else if (opp.StageName == 'Closed Lost' ||
                (oldOpp.StageName == 'Contract Sent' &&
                 opp.StageName != 'Closed Won' &&
                 opp.StageName != 'Closed Lost')) {

                result.put(opp.Id, 'Available');
            } 
        }
        return result;
    }

    public static void updateCarsByOpportunityStage(Map<Id, String> oppIdToStatus) {
        if (oppIdToStatus.isEmpty()) return;

        List<OpportunityLineItem> olis = [
            SELECT Product2Id, OpportunityId
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIdToStatus.keySet()
            WITH USER_MODE
        ];
        if (olis.isEmpty()) return;

        Set<Id> carIds = new Set<Id>();
        for (OpportunityLineItem oli : olis) carIds.add(oli.Product2Id);

        Id soldRecordTypeId;
        try {
            soldRecordTypeId = Schema.SObjectType.Product2
                .getRecordTypeInfosByDeveloperName()
                .get('For_Sale').getRecordTypeId();
        } catch (Exception e) {}

        Map<Id, Product2> cars = new Map<Id, Product2>([
            SELECT Id, Car_Status__c, Reserved_for_Opportunity__c, RecordTypeId
            FROM Product2 WHERE Id IN :carIds
            WITH USER_MODE
        ]);

        for (OpportunityLineItem oli : olis) {
            Product2 car = cars.get(oli.Product2Id);
            String target = oppIdToStatus.get(oli.OpportunityId);
            if (car == null || target == null) continue;

            car.Car_Status__c = target;

            if (target == 'Reserved' || target == 'Sold') {
                car.Reserved_for_Opportunity__c = oli.OpportunityId;
                if (target == 'Sold' && soldRecordTypeId != null) {
                    car.RecordTypeId = soldRecordTypeId;
                }
            } else {
                car.Reserved_for_Opportunity__c = null;
            }
        }

        Database.update(cars.values(), true, AccessLevel.USER_MODE);

        List<PricebookEntry> pbes = [
            SELECT Id, IsActive, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :carIds
            WITH USER_MODE
        ];

        for (PricebookEntry pbe : pbes) {
            Product2 car = cars.get(pbe.Product2Id);
            Boolean shouldBeActive = (car.Car_Status__c != 'Sold');
            if (pbe.IsActive != shouldBeActive) {
                pbe.IsActive = shouldBeActive;
            }
        }

        Database.update(pbes, true, AccessLevel.SYSTEM_MODE);
    }

    public static void validateCarConflicts(
        List<Opportunity> newOpps,
        Map<Id, Opportunity> oldMap
    ) {
        Set<Id> oppIds = new Map<Id, Opportunity>(newOpps).keySet();

        Map<Id, List<OpportunityLineItem>> oppToOlis = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, Product2.Car_Status__c, Product2.Reserved_for_Opportunity__c
            FROM OpportunityLineItem WHERE OpportunityId IN :oppIds
            WITH USER_MODE
        ]) {
            if (!oppToOlis.containsKey(oli.OpportunityId)) {
            oppToOlis.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oppToOlis.get(oli.OpportunityId).add(oli);
        }

        for (Opportunity opp : newOpps) { 
            Boolean conflict = false;

            if (oppToOlis.containsKey(opp.Id)) {
                for (OpportunityLineItem oli : oppToOlis.get(opp.Id)) {
                    if ((oli.Product2.Car_Status__c == 'Reserved' ||
                         oli.Product2.Car_Status__c == 'Sold') &&
                        oli.Product2.Reserved_for_Opportunity__c != opp.Id) {
                        conflict = true;
                        break;
                    }
                }
            }

            opp.Has_Conflict_Cars__c = conflict;
            /*
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (conflict && opp.StageName != oldOpp.StageName) {
                opp.addError(
                    'Warning! This Opportunity has reserved or sold cars. You are not able to move forward with it, until you remove those cars, or they are back available.'
                );
            }
                */
        }
    }
}