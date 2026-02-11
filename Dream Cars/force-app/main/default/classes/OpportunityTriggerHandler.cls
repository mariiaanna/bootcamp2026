public class OpportunityTriggerHandler extends TriggerHandler {

    public override void beforeUpdate() {
       CarStatusService.validateCarConflicts(
        (List<Opportunity>) Trigger.new,
        (Map<Id, Opportunity>) Trigger.oldMap
        );
    }

    
    
    public override void afterUpdate() {
        Set<Id> changedOppIds = new Set<Id>();
        Map<Id, String> oppIdToStatus = CarStatusService.mapStageToCarStatus(
        (List<Opportunity>) Trigger.new,
        (Map<Id, Opportunity>) Trigger.oldMap
        );

        for (Opportunity opp : (List<Opportunity>) Trigger.new) {
            Opportunity oldOpp = (Opportunity) Trigger.oldMap.get(opp.Id);
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                changedOppIds.add(opp.Id);
            }

        }


        if (!changedOppIds.isEmpty()) {
            recalculateStatistics(changedOppIds);
        }
         if (!oppIdToStatus.isEmpty()) {
            CarStatusService.updateCarsByOpportunityStage(oppIdToStatus);
        }
    }

    public override void beforeDelete() {
        Set<Id> oppIds = new Set<Id>();

        for (Opportunity opp : (List<Opportunity>) Trigger.old) {
            if (opp.StageName == 'Closed Won') {
                oppIds.add(opp.Id);
            }
        }

        if (oppIds.isEmpty()) return;

        for (OpportunityLineItem oli : [
            SELECT Product2.Condition__c, Opportunity.CloseDate
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
            WITH USER_MODE
        ]) {
            if (oli.Opportunity.CloseDate != null) {
                OpportunityTriggerCache.deletedYears.add(oli.Opportunity.CloseDate.year());
                OpportunityTriggerCache.deletedMonths.add(oli.Opportunity.CloseDate.month());
                OpportunityTriggerCache.deletedCarTypes.add(oli.Product2.Condition__c);
            }
        }
    }

    public override void afterDelete() {
        if (OpportunityTriggerCache.deletedYears.isEmpty()) return;

        List<Planned_Sales__c> statsToUpdate = [
            SELECT Id, Year__c, Month__c, Car_Type__c
            FROM Planned_Sales__c
            WHERE Year__c IN :OpportunityTriggerCache.deletedYears
            AND Month__c IN :OpportunityTriggerCache.deletedMonths
            AND Car_Type__c IN :OpportunityTriggerCache.deletedCarTypes
            WITH USER_MODE
        ];

        if (!statsToUpdate.isEmpty()) {
            PlannedSalesCalculationService.getSalesData(statsToUpdate);
            Database.update(statsToUpdate, false, AccessLevel.USER_MODE);
        }
        OpportunityTriggerCache.deletedYears.clear();
        OpportunityTriggerCache.deletedMonths.clear();
        OpportunityTriggerCache.deletedCarTypes.clear();
    }

    private void recalculateStatistics(Set<Id> opportunityIds) {
        try {
            List<OpportunityLineItem> items = [
                SELECT Product2.Condition__c, Opportunity.CloseDate
                FROM OpportunityLineItem
                WHERE OpportunityId IN :opportunityIds
                WITH USER_MODE
            ];

            Set<Integer> years = new Set<Integer>();
            Set<Integer> months = new Set<Integer>();
            Set<String> carTypes = new Set<String>();

            for (OpportunityLineItem oli : items) {
                if (oli.Opportunity.CloseDate != null) {
                    years.add(oli.Opportunity.CloseDate.year());
                    months.add(oli.Opportunity.CloseDate.month());
                    carTypes.add(oli.Product2.Condition__c);
                }
            }

            if (years.isEmpty()) return;

            List<Planned_Sales__c> statsToUpdate = [
                SELECT Id, Year__c, Month__c, Car_Type__c
                FROM Planned_Sales__c
                WHERE Year__c IN :years
                AND Month__c IN :months
                AND Car_Type__c IN :carTypes
                WITH USER_MODE
            ];

            if (!statsToUpdate.isEmpty()) {
                PlannedSalesCalculationService.getSalesData(statsToUpdate);
                Database.update(statsToUpdate, false, AccessLevel.USER_MODE);
            }

        } catch (Exception e) {
            List<Opportunity> sourceList =
                (Trigger.new != null) ? (List<Opportunity>) Trigger.new : (List<Opportunity>) Trigger.old;
            for (Opportunity opp : sourceList) {
                opp.addError('Cannot update statistics: ' + e.getMessage());
            }
        }
    }
}