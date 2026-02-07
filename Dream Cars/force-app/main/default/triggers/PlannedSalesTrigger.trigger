trigger PlannedSalesTrigger on Planned_Sales__c (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete) {
    Trigger_Settings__c settings = Trigger_Settings__c.getInstance();
    if (settings.Planned_Sales_Deactivated__c) {
        return;
    }
    new PlannedSalesTriggerHandler().run();
}