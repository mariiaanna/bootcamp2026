public class PlannedSalesTriggerHandler extends TriggerHandler {
    override public void beforeInsert() {
        List<Planned_Sales__c> newPlannedSales = (List<Planned_Sales__c>) Trigger.new;
        recalculate(newPlannedSales);
    }
    override public void beforeUpdate() {
        List<Planned_Sales__c> updatedPlannedSales = (List<Planned_Sales__c>) Trigger.new;
        recalculate(updatedPlannedSales);
    }

    private void recalculate(List<Planned_Sales__c> salesList) {
        try {
            PlannedSalesCalculationService.getSalesData(salesList);
        } catch (Exception e) {
            for (Planned_Sales__c ps : salesList) {
                ps.addError('Cannot update statistics: ' + e.getMessage());
            }
        }
    }
}